import type { Firestore } from 'firebase-admin/firestore';
import type { ImportJobRepository } from './types';
import type { RecipeImportJob } from '../domain/importJob';
import { isTerminal } from '../domain/importJobState';

const COLLECTION = 'recipeImportJobs';

export class FirestoreImportJobRepository implements ImportJobRepository {
  constructor(private readonly db: Firestore) {}

  private col() {
    return this.db.collection(COLLECTION);
  }

  async create(job: RecipeImportJob): Promise<void> {
    await this.col().doc(job.jobId).create(job as unknown as FirebaseFirestore.DocumentData);
  }

  async get(jobId: string): Promise<RecipeImportJob | null> {
    const snap = await this.col().doc(jobId).get();
    if (!snap.exists) return null;
    return snap.data() as RecipeImportJob;
  }

  async findByIdempotencyKey(userId: string, idempotencyKey: string): Promise<RecipeImportJob | null> {
    const snap = await this.col()
      .where('userId', '==', userId)
      .where('idempotencyKey', '==', idempotencyKey)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0]!.data() as RecipeImportJob;
  }

  async findByUrlHash(userId: string, sourceUrlHash: string): Promise<RecipeImportJob | null> {
    const snap = await this.col()
      .where('userId', '==', userId)
      .where('sourceUrlHash', '==', sourceUrlHash)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0]!.data() as RecipeImportJob;
  }

  async update(jobId: string, patch: Partial<RecipeImportJob>): Promise<void> {
    await this.col()
      .doc(jobId)
      .set({ ...patch, updatedAt: Date.now() }, { merge: true });
  }

  async countActiveForUser(userId: string): Promise<number> {
    const snap = await this.col().where('userId', '==', userId).get();
    let count = 0;
    for (const doc of snap.docs) {
      const job = doc.data() as RecipeImportJob;
      if (!isTerminal(job.state)) count++;
    }
    return count;
  }
}
