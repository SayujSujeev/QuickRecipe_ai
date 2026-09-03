import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../firebase';
import { ImportError } from '../domain/errors';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { FirestoreDraftRepository } from '../providers/draftRepository';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { updateDraftInputSchema } from './schemas';

const repo = new FirestoreImportJobRepository(db);
const draftRepo = new FirestoreDraftRepository(db);

export const updateDraft = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = updateDraftInputSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError('invalid-argument', 'Invalid draft correction request.', parsed.error.flatten());
  }

  try {
    const job = await repo.get(parsed.data.jobId);
    if (!job || job.userId !== uid) throw new ImportError('NOT_FOUND');
    if (!job.draftId) throw new ImportError('NOT_FOUND', false, 'Job has no draft yet');

    const updated = await draftRepo.applyCorrections(
      job.draftId,
      uid,
      parsed.data.corrections.map((c) => ({ fieldPath: c.fieldPath, value: c.value })),
    );
    return { draft: updated };
  } catch (error) {
    throw toHttpsError(error);
  }
});
