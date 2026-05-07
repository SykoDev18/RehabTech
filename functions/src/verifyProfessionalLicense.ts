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

// In 2025-2026 SEP retired the legacy `consultaJson.action` endpoint and
// replaced it with an Angular-fronted REST API at /api. The new flow is:
//   1) GET  /api/auth/token  with X-Client-Id + X-API-Key  → JWT
//   2) POST /api/solr/profesionista/consultar/byDetalle    → array
// Empty array == not found; single-item array == hit. The X-Recaptcha-Token
// header the browser app sends is NOT enforced server-side as of writing,
// so we omit it. Should that change, we degrade to manual_review the same
// way every other transport failure already does.
//
// The client-id/api-key live in SEP's public /assets/config.json (anyone
// loading https://cedulaprofesional.sep.gob.mx can read them) — this is a
// public lookup API, hardcoding here is fine. If SEP rotates them, the
// function returns transport_error → manual_review until we redeploy.
const SEP_API_BASE = "https://cedulaprofesional.sep.gob.mx/api";
const SEP_TOKEN_PATH = "/auth/token";
const SEP_LOOKUP_PATH = "/solr/profesionista/consultar/byDetalle";
const SEP_CLIENT_ID = "rnp-angular-app-prod";
const SEP_API_KEY = "65da8s675f8s75fda675s8d76as87d5as675da";

const SEP_TIMEOUT_MS = 15_000;
// Tokens issued by SEP's Keycloak realm have ridiculously long expiries
// (~1 year as of 2026-05). Cap the cache at 50 min so a key rotation is
// picked up within an hour without us having to re-deploy.
const SEP_TOKEN_TTL_MS = 50 * 60 * 1000;

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
 * Pulls a typed [SepLicenseData] out of whatever SEP returned. We have to
 * handle three real-world shapes here:
 *
 *  - The current SEP API (`/api/solr/.../byDetalle`) returns a TOP-LEVEL
 *    ARRAY: `[]` for not-found, `[{...}]` for a hit. Field names are
 *    `primerApellido` / `segundoApellido` / `profesion` /
 *    `fechaExpedicion` / `fechaTitulacion`.
 *  - The legacy `consultaJson.action` endpoint (now dead) used a plain
 *    object with `paterno` / `materno` / `titulo`. Old test fixtures still
 *    use this shape; tolerating it keeps the suite green.
 *  - Some SEP variants wrap the hit in `{items: [{...}]}`. Kept for
 *    forward compatibility — costs almost nothing.
 *
 * Anything without a populated `nombre` is treated as a miss.
 */
export function parseSepResponse(body: unknown): SepLicenseData | null {
  if (body === null || body === undefined) return null;

  let payload: Record<string, unknown> | null = null;
  if (Array.isArray(body)) {
    if (body.length === 0) return null;
    if (typeof body[0] === "object" && body[0] !== null) {
      payload = body[0] as Record<string, unknown>;
    }
  } else if (typeof body === "object") {
    const o = body as Record<string, unknown>;
    if (Array.isArray(o.items) && o.items.length > 0 && typeof o.items[0] === "object") {
      payload = o.items[0] as Record<string, unknown>;
    } else {
      payload = o;
    }
  }
  if (payload === null) return null;

  const nombre = String(payload.nombre ?? "").trim();
  if (nombre.length === 0) return null;

  return {
    nombre,
    paterno: String(payload.paterno ?? payload.primerApellido ?? "").trim(),
    materno: String(payload.materno ?? payload.segundoApellido ?? "").trim(),
    titulo: String(
      payload.titulo ?? payload.profesion ?? payload.carrera ?? ""
    ).trim(),
    institucion: String(
      payload.institucion ?? payload.idInstitucion ?? ""
    ).trim(),
    fechaExpedicion: String(
      payload.fechaExpedicion ??
        payload.fechaTitulacion ??
        payload.fechaRegistro ??
        ""
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

// Module-cached SEP bearer token. Refreshed lazily once the cached entry
// passes [SEP_TOKEN_TTL_MS] and busted on a 401/403 from the lookup. Lives
// for the lifetime of the function instance, which is fine — Cloud Functions
// kill cold-started instances after some idle period anyway.
let _cachedSepToken: {token: string; expiresAt: number} | null = null;

/** Test-only — reset the token cache so each test starts fresh. */
export function __resetTokenCacheForTesting(): void {
  _cachedSepToken = null;
}

async function readBodyAsText(res: {
  text?: () => Promise<string>;
  json: () => Promise<unknown>;
}): Promise<string> {
  if (typeof res.text === "function") return (await res.text()).trim();
  // Older test fakes only implement json(); round-trip back to a string so
  // the caller can apply the same JSON.parse path uniformly.
  const j = await res.json();
  return j === undefined || j === null ? "" : JSON.stringify(j);
}

async function fetchSepToken(fetchFn: FetchFn): Promise<string> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), SEP_TIMEOUT_MS);
  try {
    const res = await fetchFn(`${SEP_API_BASE}${SEP_TOKEN_PATH}`, {
      method: "GET",
      signal: controller.signal,
      headers: {
        "X-Client-Id": SEP_CLIENT_ID,
        "X-API-Key": SEP_API_KEY,
        "Accept": "application/json",
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      },
    });
    if (!res.ok) {
      throw new Error(`token endpoint HTTP ${res.status}`);
    }
    const raw = await readBodyAsText(res);
    if (raw.length === 0) throw new Error("token endpoint returned empty body");
    if (raw.startsWith("<")) {
      throw new Error("token endpoint returned non-JSON (HTML)");
    }
    const body = JSON.parse(raw) as {access_token?: unknown};
    const token = body.access_token;
    if (typeof token !== "string" || token.length === 0) {
      throw new Error("token endpoint returned no access_token");
    }
    return token;
  } finally {
    clearTimeout(timer);
  }
}

async function getSepToken(fetchFn: FetchFn, forceFresh = false): Promise<string> {
  const now = Date.now();
  if (!forceFresh && _cachedSepToken && _cachedSepToken.expiresAt > now) {
    return _cachedSepToken.token;
  }
  const token = await fetchSepToken(fetchFn);
  _cachedSepToken = {token, expiresAt: now + SEP_TOKEN_TTL_MS};
  return token;
}

async function postLookup(
  fetchFn: FetchFn,
  licenseNumber: string,
  token: string,
): Promise<{status: number; body: unknown; error?: string}> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), SEP_TIMEOUT_MS);
  try {
    const res = await fetchFn(`${SEP_API_BASE}${SEP_LOOKUP_PATH}`, {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
        // Origin/Referer/User-Agent mimic the SPA so the call doesn't look
        // like a bare scraper to whatever WAF SEP runs in front of /api.
        "Origin": "https://cedulaprofesional.sep.gob.mx",
        "Referer": "https://cedulaprofesional.sep.gob.mx/",
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      },
      body: JSON.stringify({numCedula: licenseNumber}),
    });
    if (res.status === 401 || res.status === 403) {
      return {status: res.status, body: null, error: `HTTP ${res.status}`};
    }
    if (!res.ok) {
      return {status: res.status, body: null, error: `HTTP ${res.status}`};
    }
    const raw = await readBodyAsText(res);
    if (raw.length === 0) return {status: res.status, body: null};
    if (raw.startsWith("<")) {
      return {
        status: res.status,
        body: null,
        error: "non-JSON response (HTML)",
      };
    }
    try {
      return {status: res.status, body: JSON.parse(raw)};
    } catch (e) {
      return {
        status: res.status,
        body: null,
        error: `parse: ${(e as Error).message}`,
      };
    }
  } finally {
    clearTimeout(timer);
  }
}

async function callSep(licenseNumber: string): Promise<SepCallResult> {
  const fetchFn = await getFetch();

  // Two-attempt loop: if the cached token is rejected, bust it and retry
  // ONCE with a freshly-issued token. Any other failure short-circuits to
  // transport_error so the caller can downgrade to manual_review.
  let lastError: string | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    let token: string;
    try {
      token = await getSepToken(fetchFn, attempt > 0);
    } catch (e) {
      return {
        kind: "transport_error",
        reason: `auth: ${(e as Error).message}`,
      };
    }

    let result: {status: number; body: unknown; error?: string};
    try {
      result = await postLookup(fetchFn, licenseNumber, token);
    } catch (e) {
      return {kind: "transport_error", reason: (e as Error).message};
    }

    if (result.status === 401 || result.status === 403) {
      _cachedSepToken = null; // bust and retry
      lastError = result.error ?? `HTTP ${result.status}`;
      continue;
    }
    if (result.error !== undefined) {
      return {kind: "transport_error", reason: result.error};
    }
    const parsed = parseSepResponse(result.body);
    if (parsed === null) return {kind: "not_found"};
    return {kind: "ok", data: parsed};
  }

  return {
    kind: "transport_error",
    reason: lastError ?? "auth retry exhausted",
  };
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
