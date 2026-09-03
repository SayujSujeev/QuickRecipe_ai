import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../firebase';
import { ImportError } from '../domain/errors';
import { assertTransition, isTerminal } from '../domain/importJobState';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { StorageTemporaryMediaStore } from '../providers/storageMediaStore';
import { storage } from '../firebase';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { cancelImportInputSchema } from './schemas';

const repo = new FirestoreImportJobRepository(db);
const mediaStore = new StorageTemporaryMediaStore(storage);

export const cancelImport = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = cancelImportInputSchema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError('invalid-argument', 'Invalid request.');

  try {
    const job = await repo.get(parsed.data.jobId);
    if (!job || job.userId !== uid) throw new ImportError('NOT_FOUND');
    if (isTerminal(job.state)) {
      return { cancelled: job.state === 'cancelled' };
    }

    assertTransition(job.state, 'cancelled');
    await repo.update(job.jobId, {
      state: 'cancelled',
      errorCode: 'IMPORT_CANCELLED',
      errorMessage: 'This import was cancelled.',
    });
    await mediaStore.deleteAll(job.jobId);
    return { cancelled: true };
  } catch (error) {
    throw toHttpsError(error);
  }
});
