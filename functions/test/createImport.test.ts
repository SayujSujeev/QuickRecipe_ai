import { createImport } from '../src/api/createImport';
import type { RecipeImportJob } from '../src/domain/importJob';
import { FirestoreImportJobRepository } from '../src/providers/firestoreJobRepository';

jest.mock('../src/firebase', () => ({ db: {} }));
jest.mock('../src/providers/firestoreJobRepository');

const repo = jest.mocked(FirestoreImportJobRepository).mock.instances[0]!;
const preview = { caption: 'Roast 500g potatoes with 1 tbsp oil for 30 minutes.', thumbnailUrls: [] };
const request = (data: Record<string, unknown>) => ({
  auth: { uid: 'test-user' },
  data: { sourceType: 'instagram_url', sourceUrl: 'https://www.instagram.com/reel/DTQOpCMAM4U/', idempotencyKey: 'test-preview-key', ...data },
}) as Parameters<typeof createImport.run>[0];
const waitingJob = (overrides: Partial<RecipeImportJob> = {}) => ({
  jobId: 'waiting-job', userId: 'test-user', state: 'awaiting_user_upload',
  errorCode: 'SOURCE_NOT_ACCESSIBLE', errorMessage: 'Choose the video file.',
  updatedAt: Date.now(), clientPreview: null, ...overrides,
}) as RecipeImportJob;

beforeEach(() => {
  jest.clearAllMocks();
  jest.mocked(repo.findByIdempotencyKey).mockResolvedValue(null);
  jest.mocked(repo.findByUrlHash).mockResolvedValue(null);
  jest.mocked(repo.countActiveForUser).mockResolvedValue(0);
});

it('stores the phone preview for a new import', async () => {
  const result = await createImport.run(request({ clientPreview: preview }));
  expect(result.job.clientPreview).toEqual(preview);
  expect(repo.create).toHaveBeenCalledWith(expect.objectContaining({ clientPreview: preview, state: 'queued' }));
});

it('drops boilerplate from an old or modified client', async () => {
  const result = await createImport.run(request({ clientPreview: { caption: 'Welcome back to Instagram. Sign in to see more.', thumbnailUrls: [] } }));
  expect(result.job.clientPreview).toBeNull();
});

it('leaves blocked duplicate imports waiting when no new evidence is available', async () => {
  const job = waitingJob();
  jest.mocked(repo.findByUrlHash).mockResolvedValue(job);
  expect((await createImport.run(request({}))).job).toEqual(job);
  expect(repo.update).not.toHaveBeenCalled();
  expect(repo.create).not.toHaveBeenCalled();
});

it('resumes a blocked duplicate with new preview evidence and returns the new state', async () => {
  jest.mocked(repo.findByUrlHash).mockResolvedValue(waitingJob());
  const result = await createImport.run(request({ clientPreview: preview }));
  expect(result.job).toMatchObject({ jobId: 'waiting-job', state: 'queued', clientPreview: preview, errorCode: null });
  expect(repo.update).toHaveBeenCalledTimes(1);
  expect(repo.create).not.toHaveBeenCalled();
});

it('does not repeatedly bill for a previously rejected unchanged preview', async () => {
  jest.mocked(repo.findByUrlHash).mockResolvedValue(waitingJob({ clientPreview: preview }));
  expect((await createImport.run(request({ clientPreview: preview }))).job.state).toBe('awaiting_user_upload');
  expect(repo.update).not.toHaveBeenCalled();
});

it('preserves request-key idempotency even if a later request has a preview', async () => {
  const job = waitingJob();
  jest.mocked(repo.findByIdempotencyKey).mockResolvedValue(job);
  expect((await createImport.run(request({ clientPreview: preview }))).job).toEqual(job);
  expect(repo.update).not.toHaveBeenCalled();
  expect(repo.create).not.toHaveBeenCalled();
});

it('requires authentication before accepting a client preview', async () => {
  const unauthenticated = request({ clientPreview: preview });
  delete unauthenticated.auth;
  await expect(createImport.run(unauthenticated)).rejects.toMatchObject({ code: 'unauthenticated' });
  expect(repo.create).not.toHaveBeenCalled();
});
