import { randomUUID } from 'crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../firebase';
import { config } from '../config';
import { ImportError } from '../domain/errors';
import { newStageTimestamps, type RecipeImportJob } from '../domain/importJob';
import { isTerminal, STATE_PROGRESS } from '../domain/importJobState';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { canonicalizeSourceUrl, hashCanonicalUrl } from '../security/urlSafety';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { createImportInputSchema } from './schemas';
import { usablePreviewCaption } from '../domain/publicPreview';

const repo = new FirestoreImportJobRepository(db);

export const createImport = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = createImportInputSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError('invalid-argument', 'Invalid import request.', parsed.error.flatten());
  }
  const input = parsed.data;
  const previewCaption = usablePreviewCaption(input.clientPreview?.caption);
  const clientPreview = previewCaption
    ? { caption: previewCaption, thumbnailUrls: input.clientPreview!.thumbnailUrls }
    : null;

  try {
    // Idempotency: replaying the same client-generated key returns the
    // existing job instead of creating duplicate (and duplicately billed)
    // processing.
    const existing = await repo.findByIdempotencyKey(uid, input.idempotencyKey);
    if (existing) {
      return { job: existing };
    }

    let sourceUrl: string | null = null;
    let sourceUrlHash: string | null = null;
    if (input.sourceType === 'instagram_url' || input.sourceType === 'social_url') {
      if (!input.sourceUrl) throw new ImportError('SOURCE_URL_INVALID');
      sourceUrl = canonicalizeSourceUrl(input.sourceUrl);
      sourceUrlHash = hashCanonicalUrl(sourceUrl);

      const duplicate = await repo.findByUrlHash(uid, sourceUrlHash);
      if (duplicate && !isTerminal(duplicate.state)) {
        // If the earlier job's dispatch was lost and it's been sitting in
        // `queued`, re-kick the worker trigger instead of returning a job
        // that will never progress.
        const staleQueued =
          duplicate.state === 'queued' && Date.now() - duplicate.updatedAt > 2 * 60 * 1000;
        // Re-sharing a blocked link must not loop through the same cloud login
        // page. Only new public evidence from the device can resume this way.
        const newPreview = duplicate.state === 'awaiting_user_upload' && clientPreview &&
          clientPreview.caption !== duplicate.clientPreview?.caption;
        if (staleQueued || newPreview) {
          const patch: Partial<RecipeImportJob> = {
            state: 'queued',
            progressPercent: STATE_PROGRESS.queued,
            requeuedAt: Date.now(),
            errorCode: null,
            errorMessage: null,
            ...(newPreview ? { clientPreview } : {}),
          };
          await repo.update(duplicate.jobId, patch);
          return { job: { ...duplicate, ...patch } };
        }
        return { job: duplicate };
      }
      // Terminal duplicates (failed/cancelled) don't block a fresh attempt.
    }

    const activeCount = await repo.countActiveForUser(uid);
    if (activeCount >= config.quotas.maxConcurrentJobsPerUser) {
      throw new ImportError('QUOTA_EXCEEDED');
    }

    const now = Date.now();
    const jobId = randomUUID();
    const job: RecipeImportJob = {
      jobId,
      userId: uid,
      idempotencyKey: input.idempotencyKey,
      sourceType: input.sourceType,
      sourceUrl,
      sourceUrlHash,
      caption: input.caption ?? null,
      clientPreview,
      uploadStoragePath: input.sourceType === 'uploaded_video' ? `recipeImports/${uid}/${jobId}/source` : null,
      targetLanguage: input.targetLanguage,
      measurementSystem: input.measurementSystem,
      // social URL jobs start processing immediately (the Firestore
      // worker trigger fires on `queued`); uploaded_video jobs wait for the
      // client to upload the file and call processImport.
      state: input.sourceType === 'uploaded_video' ? 'awaiting_user_upload' : 'queued',
      progressPercent:
        input.sourceType === 'uploaded_video'
          ? STATE_PROGRESS.awaiting_user_upload
          : STATE_PROGRESS.queued,
      errorCode: null,
      errorMessage: null,
      retryCount: 0,
      requeuedAt: null,
      timestamps: newStageTimestamps(now),
      transcriptionModel: null,
      transcriptionRequestId: null,
      analysisModel: null,
      analysisRequestId: null,
      usage: [],
      audioDurationSeconds: null,
      videoDurationSeconds: null,
      frameCount: null,
      frameManifest: null,
      thumbnailUrl: null,
      schemaVersion: config.schemaVersion,
      promptVersion: config.promptVersion,
      preprocessingVersion: config.preprocessingVersion,
      draftId: null,
      finalRecipeId: null,
      createdAt: now,
      updatedAt: now,
    };
    await repo.create(job);
    return { job };
  } catch (error) {
    throw toHttpsError(error);
  }
});
