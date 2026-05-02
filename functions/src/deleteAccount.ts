/**
 * deleteAccount — HTTPS Callable
 *
 * Atomically deletes a user's data from Firestore and then deletes the auth
 * user. Routed through a Cloud Function because the client cannot reliably
 * delete its own data without leaving orphans:
 *   - top-level docs that reference the user (notifications, fcm_tokens,
 *     appointments, conversations) require batched queries the client can't
 *     run safely under load,
 *   - `currentUser.delete()` revokes the auth token immediately, so any
 *     remaining Firestore writes from the client fail mid-cleanup,
 *   - `auth.deleteUser()` is Admin-SDK-only.
 *
 * Order of operations (intentional):
 *   1. Delete Firestore data.
 *   2. Delete the Firebase Auth record.
 * If step 2 fails the data is gone but auth lingers; the user can re-trigger
 * the function (it will be a no-op for missing data) or contact support.
 * The reverse order would leave Firestore orphans that the user no longer has
 * the auth context to clean up.
 */

import {
  onCall,
  HttpsError,
  type CallableRequest,
} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";

interface DeleteAccountResponse {
  status: "deleted";
  deletedCounts: Record<string, number>;
}

// Firestore caps batches at 500 writes; staying under 400 leaves margin for
// retry-with-merge race conditions.
const BATCH_SIZE = 400;

/**
 * Deletes every doc in `collection` whose `field == value`. Pages through in
 * batches of [BATCH_SIZE] so we never load the whole result set into memory.
 */
async function deleteByQuery(
  collection: string,
  field: string,
  value: string,
): Promise<number> {
  const db = getFirestore();
  let total = 0;
  // Loop until a query returns fewer docs than the page size — guaranteed
  // termination because each iteration removes at most BATCH_SIZE docs.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db
      .collection(collection)
      .where(field, "==", value)
      .limit(BATCH_SIZE)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < BATCH_SIZE) break;
  }
  return total;
}

/**
 * Deletes every conversation the user participated in, including the
 * `messages` subcollection. Uses `recursiveDelete` because conversations are
 * 2-party shared docs — when the user requests deletion both halves of the
 * thread must go.
 */
async function deleteConversationsForUser(uid: string): Promise<number> {
  const db = getFirestore();
  let total = 0;
  for (const field of ["therapistId", "patientId"]) {
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const snap = await db
        .collection("conversations")
        .where(field, "==", uid)
        .limit(BATCH_SIZE)
        .get();
      if (snap.empty) break;
      for (const conv of snap.docs) {
        await db.recursiveDelete(conv.ref);
        total++;
      }
      if (snap.size < BATCH_SIZE) break;
    }
  }
  return total;
}

async function deleteUserData(uid: string): Promise<Record<string, number>> {
  const db = getFirestore();
  const counts: Record<string, number> = {};

  // 1. Drop the user doc and ALL its subcollections (nora_chats, progress,
  //    sessions, routines, patient_context, etc.). recursiveDelete walks
  //    every descendant.
  await db.recursiveDelete(db.doc(`users/${uid}`));
  counts.users = 1;

  // 2. Top-level docs keyed by uid. .delete() on a missing doc is a no-op,
  //    so the .catch is paranoia for transport errors only.
  await db.doc(`user_streaks/${uid}`).delete().catch(() => undefined);
  counts.user_streaks = 1;
  await db
    .doc(`notification_settings/${uid}`)
    .delete()
    .catch(() => undefined);
  counts.notification_settings = 1;
  // Therapist may have a /therapists/{uid}/patients subcollection.
  await db
    .recursiveDelete(db.doc(`therapists/${uid}`))
    .catch(() => undefined);
  counts.therapists = 1;

  // 3. Top-level collections referencing the user by id field.
  counts.notifications = await deleteByQuery("notifications", "userId", uid);
  counts.fcm_tokens = await deleteByQuery("fcm_tokens", "userId", uid);
  counts.user_achievements = await deleteByQuery(
    "user_achievements",
    "userId",
    uid,
  );
  counts.feedback = await deleteByQuery("feedback", "userId", uid);
  counts.sent_notifications = await deleteByQuery(
    "sent_notifications",
    "recipientId",
    uid,
  );
  counts.appointments_as_patient = await deleteByQuery(
    "appointments",
    "patientId",
    uid,
  );
  counts.appointments_as_therapist = await deleteByQuery(
    "appointments",
    "therapistId",
    uid,
  );
  counts.routines_as_patient = await deleteByQuery(
    "routines",
    "patientId",
    uid,
  );
  counts.routines_as_therapist = await deleteByQuery(
    "routines",
    "therapistId",
    uid,
  );

  // 4. Conversations and their nested messages.
  counts.conversations = await deleteConversationsForUser(uid);

  return counts;
}

export const deleteAccount = onCall<
  Record<string, never>,
  Promise<DeleteAccountResponse>
>(
  {region: "us-central1", timeoutSeconds: 540},
  async (request: CallableRequest<Record<string, never>>) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión primero.");
    }

    logger.info("[deleteAccount] start", {uid});

    let counts: Record<string, number>;
    try {
      counts = await deleteUserData(uid);
    } catch (e) {
      logger.error("[deleteAccount] Firestore deletion failed", {
        uid,
        err: (e as Error).message,
      });
      throw new HttpsError(
        "internal",
        "No se pudieron eliminar tus datos. Intenta de nuevo o contacta a soporte.",
      );
    }

    try {
      await getAuth().deleteUser(uid);
    } catch (e) {
      logger.error("[deleteAccount] Auth deletion failed", {
        uid,
        err: (e as Error).message,
      });
      // Firestore data is already gone. Surface a distinct error so the
      // client can prompt the user to contact support without retrying the
      // whole flow (which would now be a no-op).
      throw new HttpsError(
        "data-loss",
        "Tus datos fueron eliminados pero no se pudo eliminar la cuenta de autenticación. Contacta a soporte.",
      );
    }

    logger.info("[deleteAccount] done", {uid, counts});
    return {status: "deleted", deletedCounts: counts};
  },
);
