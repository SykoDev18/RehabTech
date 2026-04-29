/**
 * RehabTech — Cloud Functions
 *
 * Triggers de Firestore que disparan push notifications via FCM cuando:
 *   - se crea una nueva cita en `appointments/`
 *   - se crea un nuevo mensaje en `conversations/{convId}/messages/`
 *
 * El cliente Flutter no puede mandar push cross-user desde la app porque
 * eso requiere el FCM Server Key (que NUNCA debe vivir en cliente). El
 * Admin SDK de Cloud Functions sí puede.
 *
 * Despliegue:
 *   cd functions && npm install && cd ..
 *   firebase deploy --only functions
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

// ─────────────────────────────────────────────────────────────────────
// 1. Notifica al paciente cuando su terapeuta agenda una cita
// ─────────────────────────────────────────────────────────────────────

export const onAppointmentCreated = onDocumentCreated(
  "appointments/{appointmentId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const patientId = data.patientId as string | undefined;
    if (!patientId) {
      logger.warn("appointment sin patientId", {id: event.params.appointmentId});
      return;
    }

    const fcmToken = await fetchFcmToken(patientId);
    if (!fcmToken) {
      logger.info("paciente sin fcmToken — no se manda push", {patientId});
      return;
    }

    const sessionType = (data.sessionType as string | undefined) ?? "Sesión";
    const dateStr = formatDate(data.dateTime);

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Nueva cita agendada",
          body: `Tu terapeuta te agendó: ${sessionType} — ${dateStr}`,
        },
        data: {
          type: "new_appointment",
          appointmentId: event.params.appointmentId,
        },
        android: {priority: "high"},
        apns: {
          payload: {aps: {sound: "default", badge: 1}},
        },
      });
      logger.info("Push de cita enviado", {patientId});
    } catch (err) {
      logger.error("Error enviando push de cita", err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────
// 2. Notifica al destinatario cuando llega un mensaje en una conversación
// ─────────────────────────────────────────────────────────────────────

export const onConversationMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const senderId = data.senderId as string | undefined;
    if (!senderId) return;

    const conversationId = event.params.conversationId;
    const convSnap = await getFirestore()
      .doc(`conversations/${conversationId}`)
      .get();
    const conv = convSnap.data();
    if (!conv) return;

    const therapistId = conv.therapistId as string | undefined;
    const patientId = conv.patientId as string | undefined;
    if (!therapistId || !patientId) return;

    // El destinatario es el participante que NO envió el mensaje.
    const recipientId = senderId === therapistId ? patientId : therapistId;

    const fcmToken = await fetchFcmToken(recipientId);
    if (!fcmToken) {
      logger.info("destinatario sin fcmToken", {recipientId});
      return;
    }

    const senderName = await fetchUserDisplayName(senderId);
    const text = (data.text as string | undefined) ?? "";
    const preview = text.length > 80 ? `${text.substring(0, 80)}…` : text;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body: preview.length > 0 ? preview : "Te envió un mensaje",
        },
        data: {
          type: "new_message",
          conversationId,
        },
        android: {priority: "high"},
        apns: {
          payload: {aps: {sound: "default", badge: 1}},
        },
      });
      logger.info("Push de mensaje enviado", {recipientId});
    } catch (err) {
      logger.error("Error enviando push de mensaje", err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

async function fetchFcmToken(userId: string): Promise<string | null> {
  try {
    const userSnap = await getFirestore().doc(`users/${userId}`).get();
    return (userSnap.data()?.fcmToken as string | undefined) ?? null;
  } catch (err) {
    logger.error("Error leyendo fcmToken", {userId, err});
    return null;
  }
}

async function fetchUserDisplayName(userId: string): Promise<string> {
  try {
    const userSnap = await getFirestore().doc(`users/${userId}`).get();
    const data = userSnap.data();
    if (!data) return "Alguien";
    const name = (data.name as string | undefined) ?? "";
    const lastName = (data.lastName as string | undefined) ?? "";
    const full = `${name} ${lastName}`.trim();
    return full.length > 0 ? full : "Alguien";
  } catch (_) {
    return "Alguien";
  }
}

function formatDate(value: unknown): string {
  if (value instanceof Timestamp) {
    const d = value.toDate();
    return new Intl.DateTimeFormat("es-MX", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(d);
  }
  return "pronto";
}
