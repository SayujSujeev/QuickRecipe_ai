import { randomUUID } from 'crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../firebase';
import { ImportError } from '../domain/errors';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { FirestoreDraftRepository } from '../providers/draftRepository';
import { mapDraftToCanonicalRecipe } from '../domain/recipeMapper';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { approveImportInputSchema } from './schemas';

const repo = new FirestoreImportJobRepository(db);
const draftRepo = new FirestoreDraftRepository(db);

export const approveImport = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireUid(request);
  const parsed = approveImportInputSchema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError('invalid-argument', 'Invalid request.');

  try {
    const job = await repo.get(parsed.data.jobId);
    if (!job || job.userId !== uid) throw new ImportError('NOT_FOUND');
    if (!job.draftId) throw new ImportError('NOT_FOUND', false, 'Job has no draft to approve');
    if (job.state !== 'needs_review' && job.state !== 'completed') {
      throw new ImportError('IMPORT_CANCELLED', false, `Cannot approve from state ${job.state}`);
    }

    const draftDoc = await draftRepo.get(job.draftId);
    if (!draftDoc) throw new ImportError('NOT_FOUND');

    const recipeId = randomUUID();
    const recipeDoc = mapDraftToCanonicalRecipe(
      draftDoc.draft,
      job.sourceUrl,
      draftDoc.thumbnailUrl ?? job.thumbnailUrl ?? null,
    );

    await db.runTransaction(async (tx) => {
      tx.set(db.collection('recipes').doc(recipeId), {
        ...recipeDoc,
        importedAt: new Date(),
      });
      tx.set(db.collection('recipeImportJobs').doc(job.jobId), { finalRecipeId: recipeId }, { merge: true });
      tx.set(
        db.collection('recipeDrafts').doc(job.draftId!),
        { approvedAt: Date.now(), approvedRecipeId: recipeId },
        { merge: true },
      );
    });

    return { recipeId };
  } catch (error) {
    throw toHttpsError(error);
  }
});
