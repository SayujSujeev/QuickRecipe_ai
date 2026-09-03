import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db, storage } from '../firebase';
import { ImportError } from '../domain/errors';
import { assertTransition, STATE_PROGRESS } from '../domain/importJobState';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { processImportInputSchema } from './schemas';

const repo = new FirestoreImportJobRepository(db);

/**
 * (Re)starts processing for a job: after a fallback video upload
 * (`awaiting_user_upload`), to retry a `failed_retryable` job, or to
 * re-kick a job stuck in `queued`. Processing itself is dispatched by the
 * Firestore trigger watching for the `queued` state.
 */
export const processImport = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = processImportInputSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError('invalid-argument', 'Invalid request.');
  }

  try {
    const job = await repo.get(parsed.data.jobId);
    if (!job || job.userId !== uid) throw new ImportError('NOT_FOUND');

    if (job.state !== 'queued' && job.state !== 'awaiting_user_upload' && job.state !== 'failed_retryable') {
      throw new ImportError('IMPORT_CANCELLED', false, `Cannot start processing from state ${job.state}`);
    }

    // If the user uploaded a video for this job (initial upload flow or the
    // Instagram-fallback path), record its path so the resolver uses it.
    const expectedUploadPath = `recipeImports/${job.userId}/${job.jobId}/source`;
    const [uploadExists] = await storage.bucket().file(expectedUploadPath).exists();
    if (uploadExists) {
      await repo.update(job.jobId, { uploadStoragePath: expectedUploadPath });
    } else if (job.state === 'awaiting_user_upload') {
      // Recovering from an inaccessible source requires the upload.
      throw new ImportError('UPLOAD_REQUIRED');
    }

    if (job.state === 'queued') {
      // Already queued (e.g. the original dispatch was lost): bump
      // requeuedAt so the worker trigger fires again.
      await repo.update(job.jobId, { requeuedAt: Date.now() });
    } else {
      assertTransition(job.state, 'queued');
      await repo.update(job.jobId, {
        state: 'queued',
        progressPercent: STATE_PROGRESS.queued,
        requeuedAt: Date.now(),
        errorCode: null,
        errorMessage: null,
      });
    }

    return { started: true };
  } catch (error) {
    throw toHttpsError(error);
  }
});
