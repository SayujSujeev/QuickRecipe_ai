import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import type { RecipeImportJob } from '../domain/importJob';
import { runImportPipeline } from './pipeline';
import { buildPipelineDeps } from './deps';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

/**
 * Firestore-triggered worker: runs the import pipeline whenever a job
 * document enters the `queued` state (or is re-kicked via `requeuedAt`
 * while already queued). This replaces the earlier Cloud Tasks dispatch,
 * which proved undebuggable on this project — tasks were silently dropped
 * before ever reaching the worker. A Firestore trigger has no separate
 * invoker/queue IAM chain: the write itself is the dispatch.
 *
 * Retries are handled by our own state machine (`failed_retryable` +
 * processImport re-queue), so Eventarc-level retry stays disabled to avoid
 * duplicate pipeline runs.
 */
export const processImportOnQueued = onDocumentWritten(
  {
    document: 'recipeImportJobs/{jobId}',
    region: 'us-central1',
    memory: '2GiB',
    timeoutSeconds: 540,
    retry: false,
    // Secrets must be declared per-function in 2nd gen or the env var is
    // absent at runtime even when set in Secret Manager.
    secrets: [openaiApiKey],
  },
  async (event) => {
    const after = event.data?.after?.data() as RecipeImportJob | undefined;
    if (!after || after.state !== 'queued') return;

    const before = event.data?.before?.data() as RecipeImportJob | undefined;
    const enteredQueued = !before || before.state !== 'queued';
    const rekicked = before !== undefined && before.requeuedAt !== after.requeuedAt;
    if (!enteredQueued && !rekicked) return;

    const jobId = event.params.jobId;
    try {
      await runImportPipeline(jobId, buildPipelineDeps());
    } catch (error) {
      // Pipeline already persisted failed_retryable/failed_terminal state;
      // log for diagnosis but never rethrow (retry: false would drop it anyway).
      // NB: don't use a `message` key here — the logger overwrites it.
      logger.error('processImportOnQueued pipeline failed', {
        jobId,
        reason: error instanceof Error ? error.message : String(error),
        errorStack: error instanceof Error ? error.stack : undefined,
      });
    }
  },
);
