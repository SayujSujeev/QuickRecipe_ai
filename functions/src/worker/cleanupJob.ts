import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { db, storage } from '../firebase';
import { config } from '../config';
import { isTerminal } from '../domain/importJobState';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { StorageTemporaryMediaStore } from '../providers/storageMediaStore';
import type { RecipeImportJob } from '../domain/importJob';

const repo = new FirestoreImportJobRepository(db);
const mediaStore = new StorageTemporaryMediaStore(storage);

/**
 * Hard-cleanup safety net. The pipeline deletes temp media immediately on
 * every terminal transition; this scheduled sweep catches anything left
 * behind by a crashed worker or an unexpected error path, per the "no later
 * than 24 hours" retention requirement.
 */
export const cleanupOrphanedImports = onSchedule(
  { schedule: 'every 60 minutes', region: 'us-central1' },
  async () => {
    const cutoff = Date.now() - config.media.tempHardCleanupSeconds * 1000;
    const snap = await db.collection('recipeImportJobs').where('updatedAt', '<', cutoff).get();

    let cleaned = 0;
    for (const doc of snap.docs) {
      const job = doc.data() as RecipeImportJob;
      if (!isTerminal(job.state)) {
        await repo.update(job.jobId, {
          state: 'failed_terminal',
          errorCode: 'INTERNAL',
          errorMessage: 'Import timed out and was cleaned up.',
        });
      }
      await mediaStore.deleteAll(job.jobId);
      cleaned++;
    }

    logger.info('cleanupOrphanedImports finished', { cleaned });
  },
);
