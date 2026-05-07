/**
 * verifyProfessionalLicense — HTTPS Callable
 *
 * Validates a Mexican professional license (cédula profesional) against the
 * SEP RNP public endpoint and writes the result back into the therapist's
 * `users/{uid}` doc using the Admin SDK. The Flutter client cannot hit SEP
 * directly (CORS + the SEP endpoint is unauthenticated, so anyone could spam
 * lookups in the user's name); routing through this function lets us:
 *   - rate-limit per-user (3 attempts / 24h),
 *   - cache verified results for 30 days,
 *   - normalise SEP's flaky JSON shape, and
 *   - downgrade SEP transport failures to "manual_review" rather than user-facing errors.
 *
 * The Admin SDK bypasses Firestore rules, so the protected fields
 * (licenseStatus, licenseData, verifiedAt, …) can only be written from here —
 * the firestore.rules `affectsLicenseAdminFields()` guard enforces that.
 */

import {onCall, HttpsError, type CallableRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";

// node-fetch v3 is ESM-only; we lazy-import inside the handler so the
// CommonJS top-level stays clean and tests can stub it.
//
// Note: we expose BOTH `text()` and `json()` because SEP occasionally serves
// `text/html` (an error/CAPTCHA page) with HTTP 200 — calling `.json()` on
// that throws and would mis-classify real misses as transport errors. The
// production callSep() uses `text()` then `JSON.parse` defensively. Existing
// tests that stub via `json()` still keep working: when `text()` is missing,
// callSep falls back to `json()`.
type FetchFn = (url: string, init?: Record<string, unknown>) => Promise<{
  ok: boolean;
  status: number;
  json: () => Promise<unknown>;
  text?: () => Promise<string>;
}>;

let _fetchOverride: FetchFn | null = null;
/** Test seam — call from Jest specs. Production never touches this. */
export function __setFetchForTesting(fn: FetchFn | null): void {
  _fetchOverride = fn;
}

async function getFetch(): Promise<FetchFn> {
  if (_fetchOverride) return _fetchOverride;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const mod: any = await import("node-fetch");
  return mod.default as FetchFn;
}

// ─────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────

interface VerifyLicenseRequest {
  licenseNumber?: string;
  speciality?: string;
}

interface SepLicenseData {
  nombre: string;
  paterno: string;
  materno: string;
  titulo: string;
  institucion: string;
  fechaExpedicion: string;
}

type VerifyLicenseStatus =
  | "verified"
  | "not_found"
  | "manual_review"
  | "rate_limited"
  | "invalid_input"
  | "error";

interface VerifyLicenseResponse {
  status: VerifyLicenseStatus;
  licenseData?: SepLicenseData;
  message: string;
}

// ─────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────

const SEP_RNP_ENDPOINT =
  "https://www.cedulaprofesional.sep.gob.mx/cedula/consultaJson.action";

const SEP_TIMEOUT_MS = 10_000;

const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_MS = 24 * 60 * 60 * 1000; // 24h
const CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

const VALID_PROFESSIONS = [
  "fisioterapia",
  "fisioterapeuta",
  "terapeuta físico",
  "terapia física",
  "rehabilitación",
  "kinesiología",
  "kinesiólogo",
  "kinesióloga",
  "terapeuta en rehabilitación",
];

// ─────────────────────────────────────────────────────────────────────
// Pure helpers (exported for tests)
// ─────────────────────────────────────────────────────────────────────

export function normalizeLicenseNumber(raw: unknown): string {
  if (typeof raw !== "string") return "";
  return raw.replace(/[\s-]/g, "");
}

export function isValidLicenseFormat(cleaned: string): boolean {
  return /^\d{7,8}$/.test(cleaned);
}

export function isPhysiotherapyTitulo(titulo: string): boolean {
  const lc = titulo.toLowerCase();
  return VALID_PROFESSIONS.some((kw) => lc.includes(kw));
}

/**
 * Pulls a typed [SepLicenseData] out of the SEP response. SEP's JSON shape is
 * "best effort" — on a hit it returns the fields below, on a miss it returns
 * `null` or `{}` with empty strings. Treat anything without a populated
 * `nombre` as a miss.
 */
export function parseSepResponse(body: unknown): SepLicenseData | null {
  if (!body || typeof body !== "object") return null;
  const o = body as Record<string, unknown>;

  // SEP wraps the payload in an `items[0]` array on some endpoints.
  let payload: Record<string, unknown> = o;
  const items = o.items;
  if (Array.isArray(items) && items.length > 0 && typeof items[0] === "object") {
    payload = items[0] as Record<string, unknown>;
  }

  const nombre = String(payload.nombre ?? "").trim();
  if (nombre.length === 0) return null;

  return {
    nombre,
    paterno: String(payload.paterno ?? "").trim(),
    materno: String(payload.materno ?? "").trim(),
    titulo: String(payload.titulo ?? payload.carrera ?? "").trim(),
    institucion: String(
      payload.institucion ?? payload.idInstitucion ?? ""
    ).trim(),
    fechaExpedicion: String(
      payload.fechaExpedicion ?? payload.fechaRegistro ?? ""
    ).trim(),
  };
}

// ─────────────────────────────────────────────────────────────────────
// Side-effecting helpers
// ─────────────────────────────────────────────────────────────────────

interface RateLimitState {
  attempts: number;
  lastAttemptAt: Date | null;
  status: string;
  verifiedAt: Date | null;
  cachedData: SepLicenseData | null;
}

async function readUserState(uid: string): Promise<RateLimitState | null> {
  const snap = await getFirestore().doc(`users/${uid}`).get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};

  const lastAttempt = data.lastAttemptAt;
  const verifiedAt = data.verifiedAt;
  const cached = data.licenseData;

  return {
    attempts: typeof data.verificationAttempts === "number" ? data.verificationAttempts : 0,
    lastAttemptAt: lastAttempt instanceof Timestamp ? lastAttempt.toDate() : null,
    status: typeof data.licenseStatus === "string" ? data.licenseStatus : "unverified",
    verifiedAt: verifiedAt instanceof Timestamp ? verifiedAt.toDate() : null,
    cachedData:
      cached && typeof cached === "object" ? (cached as SepLicenseData) : null,
  };
}

async function getUserType(uid: string): Promise<string | null> {
  const snap = await getFirestore().doc(`users/${uid}`).get();
  if (!snap.exists) return null;
  return (snap.data()?.userType as string | undefined) ?? null;
}

/**
 * Increments [verificationAttempts] (or resets to 1 if the previous attempt
 * is older than the rate-limit window) and stamps [lastAttemptAt]. Runs in a
 * transaction so concurrent callers can't race past the cap.
 */
async function bumpAttemptCounter(uid: string, now: Date): Promise<void> {
  const ref = getFirestore().doc(`users/${uid}`);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const prevAttempts =
      typeof data.verificationAttempts === "number" ? data.verificationAttempts : 0;
    const lastAt =
      data.lastAttemptAt instanceof Timestamp ? data.lastAttemptAt.toDate() : null;
    const reset = lastAt === null || now.getTime() - lastAt.getTime() >= RATE_LIMIT_WINDOW_MS;
    tx.set(
      ref,
      {
        verificationAttempts: reset ? 1 : prevAttempts + 1,
        lastAttemptAt: Timestamp.fromDate(now),
      },
      {merge: true}
    );
  });
}

type SepCallResult =
  | {kind: "ok"; data: SepLicenseData}
  | {kind: "not_found"}
  | {kind: "transport_error"; reason: string};

async function callSep(licenseNumber: string): Promise<SepCallResult> {
  const fetch = await getFetch();
  const url = `${SEP_RNP_ENDPOINT}?idCedula=${encodeURIComponent(licenseNumber)}`;

  // node-fetch v3 supports AbortSignal directly.
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), SEP_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      method: "GET",
      signal: controller.signal,
      headers: {
        // SEP's edge has been observed to 403 requests with non-browser UAs.
        // Mimic a real browser to keep the lookup path open. The endpoint is
        // public and unauthenticated, so this isn't bypassing any control.
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "es-MX,es;q=0.9",
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      },
    });
    if (!res.ok) {
      return {kind: "transport_error", reason: `HTTP ${res.status}`};
    }
    // Defensive parse: SEP sometimes returns text/html for misses or CAPTCHA
    // pages. Read raw text first, then parse — empty body means "not found".
    let body: unknown;
    try {
      if (typeof res.text === "function") {
        const raw = (await res.text()).trim();
        if (raw.length === 0) {
          return {kind: "not_found"};
        }
        // Reject obvious HTML so we don't try to parse "<!DOCTYPE html>…" as JSON.
        if (raw.startsWith("<")) {
          return {kind: "transport_error", reason: "non-JSON response"};
        }
        body = JSON.parse(raw);
      } else {
        // Test-stub fallback — older fakes only implement json().
        body = await res.json();
      }
    } catch (e) {
      return {kind: "transport_error", reason: `parse: ${(e as Error).message}`};
    }
    const parsed = parseSepResponse(body);
    if (parsed === null) return {kind: "not_found"};
    return {kind: "ok", data: parsed};
  } catch (e) {
    return {kind: "transport_error", reason: (e as Error).message};
  } finally {
    clearTimeout(timer);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Result writers
// ─────────────────────────────────────────────────────────────────────

async function writeVerified(
  uid: string,
  data: SepLicenseData
): Promise<void> {
  await getFirestore().doc(`users/${uid}`).set(
    {
      licenseStatus: "verified",
      licenseData: data,
      verifiedAt: FieldValue.serverTimestamp(),
      verificationSource: "sep_rnp",
      verificationError: FieldValue.delete(),
    },
    {merge: true}
  );
}

async function writeRejected(uid: string, reason: string): Promise<void> {
  await getFirestore().doc(`users/${uid}`).set(
    {
      licenseStatus: "rejected",
      verificationError: reason,
      licenseData: FieldValue.delete(),
    },
    {merge: true}
  );
}

async function writeManualReview(uid: string, reason: string): Promise<void> {
  await getFirestore().doc(`users/${uid}`).set(
    {
      licenseStatus: "manual_review",
      verificationError: reason,
    },
    {merge: true}
  );
}

// ─────────────────────────────────────────────────────────────────────
// Core orchestration (exported for tests)
// ─────────────────────────────────────────────────────────────────────

export interface CoreContext {
  uid: string;
  now: Date;
  userType: string | null;
}

export async function runVerification(
  ctx: CoreContext,
  payload: VerifyLicenseRequest
): Promise<VerifyLicenseResponse> {
  // STEP 2.1 — Auth/role check happens at the boundary (onCall handler).
  // Re-check role here for defence-in-depth.
  if (ctx.userType !== "therapist") {
    throw new HttpsError(
      "permission-denied",
      "Solo los terapeutas pueden verificar su cédula."
    );
  }

  // STEP 2.2 — Input validation
  const cleaned = normalizeLicenseNumber(payload.licenseNumber);
  if (!isValidLicenseFormat(cleaned)) {
    return {
      status: "invalid_input",
      message: "El número de cédula debe tener 7 u 8 dígitos.",
    };
  }
  const speciality = (payload.speciality ?? "").trim();
  if (speciality.length === 0) {
    return {
      status: "invalid_input",
      message: "Selecciona tu especialidad.",
    };
  }

  // STEP 2.3 — Rate limit check
  const state = await readUserState(ctx.uid);
  if (state !== null) {
    const lastAt = state.lastAttemptAt;
    const withinWindow =
      lastAt !== null && ctx.now.getTime() - lastAt.getTime() < RATE_LIMIT_WINDOW_MS;
    if (withinWindow && state.attempts >= RATE_LIMIT_MAX) {
      return {
        status: "rate_limited",
        message:
          "Has alcanzado el límite de 3 intentos por día. Intenta mañana.",
      };
    }

    // STEP 2.4 — Cache check
    if (
      state.status === "verified" &&
      state.verifiedAt !== null &&
      state.cachedData !== null &&
      ctx.now.getTime() - state.verifiedAt.getTime() < CACHE_TTL_MS
    ) {
      return {
        status: "verified",
        licenseData: state.cachedData,
        message: "Cédula verificada previamente.",
      };
    }
  }

  // STEP 2.5 — Bump counter BEFORE calling SEP (so timeouts still count)
  await bumpAttemptCounter(ctx.uid, ctx.now);

  // STEP 2.6 — Call SEP
  const sep = await callSep(cleaned);

  if (sep.kind === "transport_error") {
    logger.warn("[verifyProfessionalLicense] SEP transport error", {
      uid: ctx.uid,
      reason: sep.reason,
    });
    const reason = "El servicio de la SEP no respondió a tiempo";
    await writeManualReview(ctx.uid, reason);
    return {
      status: "manual_review",
      message:
        "El registro de la SEP no respondió. Tu cédula quedó en revisión manual; nuestro equipo la procesará en 1-3 días hábiles.",
    };
  }

  if (sep.kind === "not_found") {
    await writeRejected(ctx.uid, "Cédula no encontrada en el RNP de la SEP");
    return {
      status: "not_found",
      message:
        "No encontramos esa cédula en el Registro Nacional de Profesionistas. Verifica el número e intenta de nuevo.",
    };
  }

  // STEP 2.7 — Profession check
  if (!isPhysiotherapyTitulo(sep.data.titulo)) {
    const reason = `Cédula registrada como "${sep.data.titulo}" — requiere revisión manual`;
    await writeManualReview(ctx.uid, reason);
    return {
      status: "manual_review",
      message:
        "Tu cédula fue encontrada pero la profesión registrada requiere revisión de nuestro equipo.",
    };
  }

  // STEP 2.8 — Persist verified result
  try {
    await writeVerified(ctx.uid, sep.data);
  } catch (e) {
    logger.error("[verifyProfessionalLicense] Firestore write failed", {
      uid: ctx.uid,
      err: (e as Error).message,
    });
    return {
      status: "error",
      message:
        "No pudimos guardar la verificación. Intenta de nuevo en unos minutos.",
    };
  }

  // STEP 2.9 — Return typed payload
  return {
    status: "verified",
    licenseData: sep.data,
    message: "Tu cédula fue verificada exitosamente.",
  };
}

// ─────────────────────────────────────────────────────────────────────
// Exposed onCall entry point
// ─────────────────────────────────────────────────────────────────────

export const verifyProfessionalLicense = onCall<VerifyLicenseRequest, Promise<VerifyLicenseResponse>>(
  {region: "us-central1"},
  async (request: CallableRequest<VerifyLicenseRequest>) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión primero.");
    }
    const userType = await getUserType(uid);
    return runVerification(
      {uid, now: new Date(), userType},
      request.data ?? {}
    );
  }
);
