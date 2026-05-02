/**
 * Unit tests for verifyProfessionalLicense.
 *
 * Strategy:
 *   - jest.mock replaces `firebase-admin/firestore` with an in-memory fake.
 *     The exported `Timestamp` is a real class so `instanceof Timestamp`
 *     in the production code keeps working.
 *   - SEP is stubbed via the module's `__setFetchForTesting` seam.
 */

// `mock`-prefixed names are allowed inside jest.mock factories (Jest hoist rule).
class mockTimestamp {
  constructor(public readonly _date: Date) {}
  toDate(): Date {
    return this._date;
  }
  static fromDate(d: Date): mockTimestamp {
    return new mockTimestamp(d);
  }
}

const mockDocStore: Record<string, Record<string, unknown>> = {};

const mockResolveSentinels = (
  data: Record<string, unknown>
): Record<string, unknown> => {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(data)) {
    if (
      v !== null &&
      typeof v === "object" &&
      (v as Record<string, unknown>).__delete === true
    ) {
      // FieldValue.delete() — drop the key entirely.
      continue;
    }
    if (
      v !== null &&
      typeof v === "object" &&
      (v as Record<string, unknown>).__serverTs === true
    ) {
      out[k] = new mockTimestamp(new Date());
      continue;
    }
    out[k] = v;
  }
  return out;
};

const mockDocRef = (path: string) => ({
  get: async () => ({
    exists: mockDocStore[path] !== undefined,
    data: () => mockDocStore[path],
  }),
  set: async (data: Record<string, unknown>, _opts?: {merge?: boolean}) => {
    mockDocStore[path] = {
      ...(mockDocStore[path] ?? {}),
      ...mockResolveSentinels(data),
    };
  },
});

const mockFirestoreInstance = {
  doc: (path: string) => mockDocRef(path),
  runTransaction: async <T>(
    fn: (tx: {
      get: (ref: ReturnType<typeof mockDocRef>) => Promise<{
        exists: boolean;
        data: () => Record<string, unknown> | undefined;
      }>;
      set: (
        ref: ReturnType<typeof mockDocRef>,
        data: Record<string, unknown>,
        opts?: {merge?: boolean}
      ) => void;
    }) => Promise<T>
  ): Promise<T> =>
    fn({
      get: async (ref) => ref.get(),
      set: async (ref, data) => {
        await ref.set(data);
      },
    }),
};

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: () => mockFirestoreInstance,
  FieldValue: {
    delete: () => ({__delete: true}),
    serverTimestamp: () => ({__serverTs: true}),
  },
  Timestamp: mockTimestamp,
}));

// Silence firebase-functions logger so test output stays clean.
jest.mock("firebase-functions/v2", () => ({
  logger: {info: jest.fn(), warn: jest.fn(), error: jest.fn(), debug: jest.fn()},
}));

// ─────────────────────────────────────────────────────────────────────
// Now import the module under test.
// ─────────────────────────────────────────────────────────────────────

import {
  __setFetchForTesting,
  isPhysiotherapyTitulo,
  isValidLicenseFormat,
  normalizeLicenseNumber,
  parseSepResponse,
  runVerification,
} from "../verifyProfessionalLicense";

beforeEach(() => {
  for (const k of Object.keys(mockDocStore)) delete mockDocStore[k];
  __setFetchForTesting(null);
});

afterAll(() => {
  __setFetchForTesting(null);
});

const UID = "therapist_uid";
const NOW = new Date("2026-05-01T12:00:00Z");
const OK_PAYLOAD = {
  nombre: "ANA",
  paterno: "GARCIA",
  materno: "LOPEZ",
  titulo: "Fisioterapia",
  institucion: "UNAM",
  fechaExpedicion: "2018-06-15",
};

const stubSepOk = (payload: Record<string, unknown>) =>
  __setFetchForTesting(
    async () =>
      ({
        ok: true,
        status: 200,
        json: async () => payload,
      } as never)
  );

const stubSepNotFound = () =>
  __setFetchForTesting(
    async () =>
      ({
        ok: true,
        status: 200,
        json: async () => null,
      } as never)
  );

const stubSepHttpError = (status: number) =>
  __setFetchForTesting(
    async () =>
      ({
        ok: false,
        status,
        json: async () => ({}),
      } as never)
  );

const stubSepThrow = (msg: string) =>
  __setFetchForTesting(async () => {
    throw new Error(msg);
  });

const stubSepBadJson = () =>
  __setFetchForTesting(
    async () =>
      ({
        ok: true,
        status: 200,
        json: async () => {
          throw new SyntaxError("Unexpected token < in JSON");
        },
      } as never)
  );

// ─────────────────────────────────────────────────────────────────────
// Pure helper tests
// ─────────────────────────────────────────────────────────────────────

describe("normalizeLicenseNumber", () => {
  test("strips spaces", () => {
    expect(normalizeLicenseNumber("1234 5678")).toBe("12345678");
  });
  test("strips dashes", () => {
    expect(normalizeLicenseNumber("1234-5678")).toBe("12345678");
  });
  test("non-string returns empty", () => {
    expect(normalizeLicenseNumber(undefined)).toBe("");
    expect(normalizeLicenseNumber(123)).toBe("");
  });
});

describe("isValidLicenseFormat (input validation)", () => {
  test("rejects empty", () => expect(isValidLicenseFormat("")).toBe(false));
  test("rejects 6 digits", () => expect(isValidLicenseFormat("123456")).toBe(false));
  test("rejects 9 digits", () => expect(isValidLicenseFormat("123456789")).toBe(false));
  test("rejects letters", () => expect(isValidLicenseFormat("ABCD1234")).toBe(false));
  test("accepts 7 digits", () => expect(isValidLicenseFormat("1234567")).toBe(true));
  test("accepts 8 digits", () => expect(isValidLicenseFormat("12345678")).toBe(true));
});

describe("isPhysiotherapyTitulo (profession validation)", () => {
  test("accepts fisioterapia", () => {
    expect(isPhysiotherapyTitulo("Licenciatura en Fisioterapia")).toBe(true);
  });
  test("accepts rehabilitación", () => {
    expect(isPhysiotherapyTitulo("Terapia en Rehabilitación")).toBe(true);
  });
  test("accepts terapia física", () => {
    expect(isPhysiotherapyTitulo("Maestría en Terapia Física")).toBe(true);
  });
  test("rejects abogado", () => {
    expect(isPhysiotherapyTitulo("Licenciado en Derecho")).toBe(false);
  });
  test("rejects médico cirujano", () => {
    expect(isPhysiotherapyTitulo("Médico Cirujano")).toBe(false);
  });
});

describe("parseSepResponse", () => {
  test("null body → not found", () => {
    expect(parseSepResponse(null)).toBeNull();
  });
  test("empty object → not found", () => {
    expect(parseSepResponse({})).toBeNull();
  });
  test("populated object → parsed", () => {
    const out = parseSepResponse(OK_PAYLOAD);
    expect(out?.nombre).toBe("ANA");
    expect(out?.titulo).toBe("Fisioterapia");
  });
  test("items[0] wrapper → parsed", () => {
    const out = parseSepResponse({items: [OK_PAYLOAD]});
    expect(out?.nombre).toBe("ANA");
  });
});

// ─────────────────────────────────────────────────────────────────────
// Orchestration tests
// ─────────────────────────────────────────────────────────────────────

describe("runVerification — input validation path", () => {
  test("rejects non-therapist with permission-denied", async () => {
    await expect(
      runVerification(
        {uid: UID, now: NOW, userType: "patient"},
        {licenseNumber: "12345678", speciality: "Fisioterapia"}
      )
    ).rejects.toMatchObject({code: "permission-denied"});
  });

  test("returns invalid_input for short cedula", async () => {
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "123", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("invalid_input");
  });

  test("strips spaces before validating", async () => {
    stubSepOk(OK_PAYLOAD);
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "1234 5678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("verified");
  });

  test("missing speciality → invalid_input", async () => {
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: ""}
    );
    expect(res.status).toBe("invalid_input");
  });
});

describe("runVerification — rate limiting", () => {
  test("blocks 4th attempt within 24h", async () => {
    const oneHourAgo = new Date(NOW.getTime() - 60 * 60 * 1000);
    mockDocStore[`users/${UID}`] = {
      verificationAttempts: 3,
      lastAttemptAt: new mockTimestamp(oneHourAgo),
      licenseStatus: "rejected",
    };
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("rate_limited");
  });

  test("allows attempt after 24h window resets", async () => {
    const longAgo = new Date(NOW.getTime() - 25 * 60 * 60 * 1000);
    mockDocStore[`users/${UID}`] = {
      verificationAttempts: 3,
      lastAttemptAt: new mockTimestamp(longAgo),
      licenseStatus: "rejected",
    };
    stubSepOk(OK_PAYLOAD);
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("verified");
  });
});

describe("runVerification — cache behaviour", () => {
  test("returns cached verified result if < 30 days old", async () => {
    const tenDaysAgo = new Date(NOW.getTime() - 10 * 24 * 60 * 60 * 1000);
    mockDocStore[`users/${UID}`] = {
      verificationAttempts: 1,
      lastAttemptAt: new mockTimestamp(tenDaysAgo),
      licenseStatus: "verified",
      verifiedAt: new mockTimestamp(tenDaysAgo),
      licenseData: OK_PAYLOAD,
    };
    let sepCalled = false;
    __setFetchForTesting(async () => {
      sepCalled = true;
      return {ok: true, status: 200, json: async () => OK_PAYLOAD} as never;
    });
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("verified");
    expect(sepCalled).toBe(false);
  });

  test("calls SEP when cached verification is older than 30 days", async () => {
    const longAgo = new Date(NOW.getTime() - 60 * 24 * 60 * 60 * 1000);
    mockDocStore[`users/${UID}`] = {
      verificationAttempts: 1,
      lastAttemptAt: new mockTimestamp(longAgo),
      licenseStatus: "verified",
      verifiedAt: new mockTimestamp(longAgo),
      licenseData: OK_PAYLOAD,
    };
    let sepCalled = false;
    __setFetchForTesting(async () => {
      sepCalled = true;
      return {ok: true, status: 200, json: async () => OK_PAYLOAD} as never;
    });
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("verified");
    expect(sepCalled).toBe(true);
  });
});

describe("runVerification — profession check", () => {
  test("non-physio titulo → manual_review and Firestore reflects it", async () => {
    stubSepOk({...OK_PAYLOAD, titulo: "Licenciado en Derecho"});
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("manual_review");
    expect(mockDocStore[`users/${UID}`].licenseStatus).toBe("manual_review");
  });
});

describe("runVerification — SEP error handling", () => {
  test("SEP throws → manual_review", async () => {
    stubSepThrow("aborted");
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("manual_review");
  });

  test("SEP HTTP 500 → manual_review", async () => {
    stubSepHttpError(500);
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("manual_review");
  });

  test("SEP malformed JSON → manual_review", async () => {
    stubSepBadJson();
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("manual_review");
  });

  test("SEP returns null → not_found + Firestore rejected", async () => {
    stubSepNotFound();
    const res = await runVerification(
      {uid: UID, now: NOW, userType: "therapist"},
      {licenseNumber: "12345678", speciality: "Fisioterapia"}
    );
    expect(res.status).toBe("not_found");
    expect(mockDocStore[`users/${UID}`].licenseStatus).toBe("rejected");
  });
});
