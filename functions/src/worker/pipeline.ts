import { ImportError } from '../domain/errors';
import type { RecipeImportJob } from '../domain/importJob';
import { assertTransition, STATE_PROGRESS as PROGRESS } from '../domain/importJobState';
import {
  needsReview,
  reconcileTotalMinutes,
  validateRecipeDraftDomain,
  type RecipeDraft,
} from '../domain/recipeSchema';
import { config } from '../config';
import type {
  ImportJobRepository,
  MediaPreprocessor,
  MediaSourceResolver,
  RecipeAnalysisProvider,
  TemporaryMediaStore,
  TranscriptionProvider,
} from '../providers/types';
import { selectFrameSubset } from './frameSelection';
import { cleanupLocalFile } from '../providers/storageMediaStore';
import { usablePreviewCaption } from '../domain/publicPreview';

export interface PipelineDeps {
  repo: ImportJobRepository;
  sourceResolver: MediaSourceResolver;
  preprocessor: MediaPreprocessor;
  transcription: TranscriptionProvider;
  analysis: RecipeAnalysisProvider;
  mediaStore: TemporaryMediaStore;
  onPersistDraft: (
    jobId: string,
    userId: string,
    draft: RecipeDraft,
    transcript: string | null,
    captionUsed: string | null,
    thumbnailUrl: string | null,
  ) => Promise<string>;
}

const TRANSCRIPTION_PROMPT_CONTEXT =
  'Cooking recipe narration. Preserve ingredient names, quantities, units, ' +
  'temperatures, durations, cookware, and action verbs exactly. The speaker may ' +
  'mix English with Malayalam, Hindi, Tamil, or another language. Do not translate ' +
  'or normalize measurements in the transcript.';

/**
 * Runs one import job end-to-end. Restart-safe: re-invoking this for a job
 * that already advanced past a stage is a no-op for that stage because each
 * stage checks/derives from the persisted job state before acting. Always
 * cleans up temporary media on both success and terminal failure.
 */
export async function runImportPipeline(jobId: string, deps: PipelineDeps): Promise<void> {
  const { repo } = deps;
  let job = await repo.get(jobId);
  if (!job) throw new ImportError('NOT_FOUND');
  // Only a queued job may start processing; anything else means a duplicate
  // trigger firing or a job that already advanced/terminated — no-op.
  if (job.state !== 'queued') {
    return;
  }

  let thumbnailLocalPath: string | null = null;
  try {
    job = await transitionTo(deps, job, 'acquiring_source', 'acquiringSourceAt');
    // URL sources may expose only public metadata. If there is not enough
    // evidence, the catch block parks the job in awaiting_user_upload so the
    // user can recover by selecting/sharing the actual video.
    const resolved = await deps.sourceResolver.resolve(job);

    let transcriptText = '';
    let frames: Awaited<ReturnType<typeof selectFrameSubset>> = [];

    if (resolved.kind === 'video') {
      job = await transitionTo(deps, job, 'preprocessing', 'preprocessingAt');
      const probe = await deps.preprocessor.probe(resolved.localVideoPath);
      if (probe.durationSeconds > config.media.maxVideoDurationSeconds) {
        throw new ImportError('VIDEO_TOO_LONG');
      }

      const audio = probe.hasAudioStream
        ? await deps.preprocessor.extractAudio(resolved.localVideoPath, probe.durationSeconds)
        : null;
      const rawFrames = await deps.preprocessor.extractFrames(resolved.localVideoPath, probe.durationSeconds);
      frames = selectFrameSubset(rawFrames, probe.durationSeconds);
      thumbnailLocalPath = chooseDishThumbnailFrame(frames)?.localPath ?? null;

      const frameManifest = await Promise.all(
        frames.map(async (f, index) => ({
          index,
          timestampMs: f.timestampMs,
          storagePath: await deps.mediaStore.uploadLocalFile(job!.jobId, f.localPath, 'frame'),
          reason: f.reason,
        })),
      );

      await repo.update(job.jobId, {
        videoDurationSeconds: probe.durationSeconds,
        frameCount: frameManifest.length,
        frameManifest,
        preprocessingVersion: config.preprocessingVersion,
      });

      job = await transitionTo(deps, job, 'transcribing', 'transcribingAt');
      if (audio) {
        const transcription = await deps.transcription.transcribe(audio.localPath, {
          promptContext: TRANSCRIPTION_PROMPT_CONTEXT,
        });
        transcriptText = transcription.text;
        await repo.update(job.jobId, {
          audioDurationSeconds: transcription.durationSeconds,
          transcriptionModel: transcription.model,
          transcriptionRequestId: transcription.requestId,
          usage: transcription.usage ? [...job.usage, transcription.usage] : job.usage,
        });
      } else {
        await repo.update(job.jobId, {
          errorCode: 'NO_AUDIO_CONTINUING_VISUAL_ONLY',
        });
      }
    } else {
      // Public social metadata has no video to transcribe. If a public poster
      // image is available, also give it to vision and retain it as the dish
      // thumbnail after the temporary evidence is removed.
      // The resolver's recovered caption must not be replaced by stale login
      // text or share-sheet prose saved on a previous attempt.
      const supplied = usablePreviewCaption(job.caption);
      const caption = supplied && supplied !== resolved.caption && job.sourceType !== 'caption_only'
        ? `${resolved.caption}\n\nAdditional user-supplied context:\n${supplied}`
        : resolved.caption;
      thumbnailLocalPath = resolved.localThumbnailPath;
      if (resolved.localThumbnailPath) {
        frames = [{
          localPath: resolved.localThumbnailPath,
          timestampMs: 0,
          reason: 'middle',
        }];
      }
      await repo.update(job.jobId, { caption });
      job = { ...job, caption };
      job = await transitionTo(deps, job, 'preprocessing', 'preprocessingAt');
      job = await transitionTo(deps, job, 'transcribing', 'transcribingAt');
    }

    job = await transitionTo(deps, job, 'analyzing', 'analyzingAt');
    const sourceEvidence = {
      kind: resolved.kind === 'video' ? 'video' as const
        : job.sourceType === 'caption_only' ? 'caption' as const : 'public_preview' as const,
      captionChars: job.caption?.length ?? 0,
      imageCount: frames.length,
    };
    await repo.update(job.jobId, { sourceEvidence, promptVersion: config.promptVersion });
    console.info('Recipe import evidence ready', { jobId: job.jobId, ...sourceEvidence });
    let analysis = await deps.analysis.analyze({
      caption: job.caption,
      transcript: transcriptText,
      frames: frames.map((f) => ({ timestampMs: f.timestampMs, localPath: f.localPath })),
      targetLanguage: job.targetLanguage,
      measurementSystem: job.measurementSystem,
    });

    job = await transitionTo(deps, job, 'validating', 'validatingAt');
    let draft = reconcileTotalMinutes(analysis.draft);
    let issues = validateRecipeDraftDomain(draft);

    if (issues.length > 0) {
      // One corrective retry only, describing the concrete problem.
      const correctivePrompt = `The previous draft had validation issues: ${issues
        .map((i) => `${i.path}: ${i.message}`)
        .join('; ')}. Fix only these issues while preserving all other evidence-based content.`;
      analysis = await deps.analysis.analyze({
        caption: job.caption,
        transcript: transcriptText,
        frames: frames.map((f) => ({ timestampMs: f.timestampMs, localPath: f.localPath })),
        targetLanguage: job.targetLanguage,
        measurementSystem: job.measurementSystem,
        correctivePrompt,
      });
      draft = reconcileTotalMinutes(analysis.draft);
      issues = validateRecipeDraftDomain(draft);
      if (issues.length > 0) {
        throw new ImportError('ANALYSIS_TEMPORARILY_UNAVAILABLE', true, `Persistent validation issues: ${issues.map((i) => i.message).join('; ')}`);
      }
    }

    await repo.update(job.jobId, {
      analysisModel: analysis.model,
      analysisRequestId: analysis.requestId,
      usage: analysis.usage ? [...job.usage, analysis.usage] : job.usage,
    });

    if (draft.status === 'not_a_recipe') {
      // A preview is not the video. An uninformative caption must not cause a
      // terminal claim about a video we never analyzed.
      if (sourceEvidence.kind === 'public_preview') {
        console.info('Recipe import needs full video evidence', { jobId: job.jobId, ...sourceEvidence });
        await repo.update(job.jobId, {
          errorCode: 'SOURCE_NOT_ACCESSIBLE',
          errorMessage: 'The link preview does not contain enough recipe information. Share or choose the video file so we can read its audio and on-screen steps.',
        });
        job = await transitionTo(deps, job, 'awaiting_user_upload');
        await deps.mediaStore.deleteAll(job.jobId);
        return;
      }
      await repo.update(job.jobId, {
        errorCode: 'NOT_A_RECIPE',
        errorMessage: 'The source does not appear to describe a recipe.',
      });
      job = await transitionTo(deps, job, 'failed_terminal');
      await deps.mediaStore.deleteAll(job.jobId);
      return;
    }

    let thumbnailUrl = job.thumbnailUrl ?? null;
    if (thumbnailLocalPath) {
      // A transient Storage failure should not permanently lose an otherwise
      // valid source image. Retry once before continuing without a new image.
      for (let attempt = 0; attempt < 2; attempt++) {
        try {
          thumbnailUrl = await deps.mediaStore.persistThumbnail(job.userId, job.jobId, thumbnailLocalPath);
          break;
        } catch {
          if (attempt === 1) {
            console.warn('Could not persist recipe thumbnail', { jobId: job.jobId });
          }
        }
      }
    }
    if (thumbnailUrl) {
      await repo.update(job.jobId, { thumbnailUrl });
      job = { ...job, thumbnailUrl };
    }

    const draftId = await deps.onPersistDraft(
      job.jobId,
      job.userId,
      draft,
      transcriptText.length > 0 ? transcriptText : null,
      job.caption,
      thumbnailUrl,
    );
    await repo.update(job.jobId, { draftId });

    const requiresReview = needsReview(draft, config.validation.confidenceReviewThreshold);
    job = await transitionTo(
      deps,
      job,
      requiresReview ? 'needs_review' : 'completed',
      'completedAt',
    );

    await deps.mediaStore.deleteAll(job.jobId);
  } catch (error) {
    const importError = error instanceof ImportError ? error : new ImportError('INTERNAL', false, String(error));
    const current = await repo.get(jobId);
    if (current && current.state !== 'cancelled') {
      const canRecoverWithVideo =
        importError.code === 'SOURCE_NOT_ACCESSIBLE' &&
        current.state === 'acquiring_source' &&
        (current.sourceType === 'social_url' || current.sourceType === 'instagram_url');
      if (canRecoverWithVideo) {
        console.info('Recipe import public preview unavailable', { jobId, errorCode: importError.code });
        await repo.update(jobId, {
          state: 'awaiting_user_upload',
          progressPercent: PROGRESS.awaiting_user_upload,
          errorCode: importError.code,
          errorMessage: importError.userMessage,
        });
        await deps.mediaStore.deleteAll(jobId).catch(() => undefined);
        return;
      }

      const nextState = importError.retryable && current.retryCount < 3 ? 'failed_retryable' : 'failed_terminal';
      await repo.update(jobId, {
        state: nextState,
        errorCode: importError.code,
        errorMessage: importError.userMessage,
        retryCount: nextState === 'failed_retryable' ? current.retryCount + 1 : current.retryCount,
      });
    }
    await deps.mediaStore.deleteAll(jobId).catch(() => undefined);
    throw importError;
  } finally {
    if (thumbnailLocalPath) await cleanupLocalFile(thumbnailLocalPath);
  }
}

/**
 * Recipe reels most often show the plated dish in their later-middle frames;
 * avoid the very first/title frame and the final end-card when alternatives
 * exist. This stays deterministic and independent of model output.
 */
export function chooseDishThumbnailFrame<T extends { timestampMs: number; reason: string }>(
  frames: T[],
): T | null {
  if (frames.length === 0) return null;
  const maxTimestamp = Math.max(...frames.map((frame) => frame.timestampMs));
  const preferred = frames.filter(
    (frame) => frame.reason !== 'first' && frame.reason !== 'final',
  );
  const candidates = preferred.length > 0 ? preferred : frames;
  const target = maxTimestamp * 0.75;
  return [...candidates].sort(
    (a, b) => Math.abs(a.timestampMs - target) - Math.abs(b.timestampMs - target),
  )[0] ?? null;
}

async function transitionTo(
  deps: PipelineDeps,
  job: RecipeImportJob,
  next: RecipeImportJob['state'],
  timestampKey?: keyof RecipeImportJob['timestamps'],
): Promise<RecipeImportJob> {
  assertTransition(job.state, next);
  const timestamps = timestampKey ? { ...job.timestamps, [timestampKey]: Date.now() } : job.timestamps;
  const updated: RecipeImportJob = {
    ...job,
    state: next,
    progressPercent: PROGRESS[next],
    timestamps,
    updatedAt: Date.now(),
  };
  await deps.repo.update(job.jobId, {
    state: next,
    progressPercent: updated.progressPercent,
    timestamps,
  });
  return updated;
}
