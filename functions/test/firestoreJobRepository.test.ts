import { FirestoreImportJobRepository } from '../src/providers/firestoreJobRepository';
import type { Firestore } from 'firebase-admin/firestore';

it('finds a resumable job even when older failed jobs share the URL', async () => {
  const jobs = [
    { jobId: 'old-failure', state: 'failed_terminal', updatedAt: 1 },
    { jobId: 'active', state: 'awaiting_user_upload', updatedAt: 2 },
    { jobId: 'new-failure', state: 'failed_terminal', updatedAt: 3 },
  ];
  const query = { where: jest.fn().mockReturnThis(), get: jest.fn().mockResolvedValue({ empty: false, docs: jobs.map((job) => ({ data: () => job })) }) };
  const db = { collection: jest.fn().mockReturnValue(query) } as unknown as Firestore;
  const result = await new FirestoreImportJobRepository(db).findByUrlHash('test-user', 'url-hash');
  expect(result?.jobId).toBe('active');
  expect(query.where).toHaveBeenCalledWith('userId', '==', 'test-user');
  expect(query.where).toHaveBeenCalledWith('sourceUrlHash', '==', 'url-hash');
});
