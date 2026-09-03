import { randomUUID } from 'crypto';
import type { Firestore } from 'firebase-admin/firestore';
import type { RecipeDraft } from '../domain/recipeSchema';
import type { RecipeDraftCorrection, RecipeDraftDocument } from '../domain/importJob';
import { ImportError } from '../domain/errors';

const DRAFTS = 'recipeDrafts';
const CORRECTIONS = 'recipeDraftCorrections';

export class FirestoreDraftRepository {
  constructor(private readonly db: Firestore) {}

  async persist(
    jobId: string,
    userId: string,
    draft: RecipeDraft,
    transcript: string | null,
    captionUsed: string | null,
    thumbnailUrl: string | null,
  ): Promise<string> {
    const draftId = randomUUID();
    const now = Date.now();
    const doc: RecipeDraftDocument = {
      draftId,
      jobId,
      userId,
      draft,
      transcript,
      captionUsed,
      thumbnailUrl,
      createdAt: now,
      updatedAt: now,
      approvedAt: null,
      approvedRecipeId: null,
    };
    await this.db.collection(DRAFTS).doc(draftId).set(doc);
    return draftId;
  }

  async get(draftId: string): Promise<RecipeDraftDocument | null> {
    const snap = await this.db.collection(DRAFTS).doc(draftId).get();
    return snap.exists ? (snap.data() as RecipeDraftDocument) : null;
  }

  async applyCorrections(
    draftId: string,
    userId: string,
    corrections: Array<{ fieldPath: string; value: unknown }>,
  ): Promise<RecipeDraftDocument> {
    const doc = await this.get(draftId);
    if (!doc || doc.userId !== userId) throw new ImportError('NOT_FOUND');

    let draft: RecipeDraft = doc.draft;
    const records: RecipeDraftCorrection[] = [];
    for (const correction of corrections) {
      const previousValue = getAtPath(draft, correction.fieldPath);
      draft = setAtPath(draft, correction.fieldPath, correction.value);
      records.push({
        correctionId: randomUUID(),
        draftId,
        userId,
        fieldPath: correction.fieldPath,
        previousValue,
        correctedValue: correction.value,
        createdAt: Date.now(),
      });
    }

    const batch = this.db.batch();
    batch.set(
      this.db.collection(DRAFTS).doc(draftId),
      { draft, updatedAt: Date.now() },
      { merge: true },
    );
    for (const record of records) {
      batch.set(this.db.collection(CORRECTIONS).doc(record.correctionId), record);
    }
    await batch.commit();

    return { ...doc, draft, updatedAt: Date.now() };
  }

  async markApproved(draftId: string, recipeId: string): Promise<void> {
    await this.db
      .collection(DRAFTS)
      .doc(draftId)
      .set({ approvedAt: Date.now(), approvedRecipeId: recipeId }, { merge: true });
  }
}

/** Minimal, safe dotted/bracket path accessors scoped to plain JSON structures (no prototype access). */
function getAtPath(obj: unknown, fieldPath: string): unknown {
  const parts = parsePath(fieldPath);
  let current: unknown = obj;
  for (const part of parts) {
    if (current === null || typeof current !== 'object') return undefined;
    current = (current as Record<string, unknown>)[part];
  }
  return current;
}

function setAtPath<T>(obj: T, fieldPath: string, value: unknown): T {
  const parts = parsePath(fieldPath);
  const clone = structuredClone(obj) as Record<string, unknown> | unknown[];
  let current: Record<string, unknown> | unknown[] = clone;
  for (let i = 0; i < parts.length - 1; i++) {
    const key = parts[i]!;
    const next = (current as Record<string, unknown>)[key as never] as
      | Record<string, unknown>
      | unknown[];
    current = next;
  }
  const lastKey = parts[parts.length - 1]!;
  (current as Record<string, unknown>)[lastKey as never] = value as never;
  return clone as T;
}

function parsePath(fieldPath: string): string[] {
  if (!/^[a-zA-Z0-9_.[\]]+$/.test(fieldPath)) {
    throw new ImportError('INTERNAL', false, `Rejected unsafe field path: ${fieldPath}`);
  }
  return fieldPath
    .replace(/\[(\d+)\]/g, '.$1')
    .split('.')
    .filter(Boolean);
}
