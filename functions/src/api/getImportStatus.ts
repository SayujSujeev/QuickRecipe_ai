import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../firebase';
import { ImportError } from '../domain/errors';
import { STATE_LABEL } from '../domain/importJobState';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { FirestoreDraftRepository } from '../providers/draftRepository';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { jobIdInputSchema } from './schemas';

const repo = new FirestoreImportJobRepository(db);
const draftRepo = new FirestoreDraftRepository(db);

export const getImportStatus = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = jobIdInputSchema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError('invalid-argument', 'Invalid request.');

  try {
    const job = await repo.get(parsed.data.jobId);
    if (!job || job.userId !== uid) throw new ImportError('NOT_FOUND');

    const draft = job.draftId ? await draftRepo.get(job.draftId) : null;

    return {
      job,
      stageLabel: STATE_LABEL[job.state],
      draft,
    };
  } catch (error) {
    throw toHttpsError(error);
  }
});
