import { chooseDishThumbnailFrame, runImportPipeline, type PipelineDeps } from '../src/worker/pipeline';
import {
  MockMediaPreprocessor,
  MockMediaSourceResolver,
  MockRecipeAnalysisProvider,
  MockTranscriptionProvider,
  fixtureCompleteDraft,
} from '../src/providers/mocks';
import type { ImportJobRepository, TemporaryMediaStore } from '../src/providers/types';
import type { RecipeImportJob } from '../src/domain/importJob';
import { newStageTimestamps } from '../src/domain/importJob';
import { ImportError } from '../src/domain/errors';

// Fixture paths are not real generated files. Never remove an unrelated file
// that happens to use one of these names on the test machine.
jest.mock('../src/providers/storageMediaStore', () => ({
  cleanupLocalFile: jest.fn().mockResolvedValue(undefined),
}));

function baseJob(overrides: Partial<RecipeImportJob> = {}): RecipeImportJob {
  const now = Date.now();
  return {
    jobId: 'job_1',
    userId: 'user_1',
    idempotencyKey: 'idem_1',
    sourceType: 'uploaded_video',
    sourceUrl: null,
    sourceUrlHash: null,
    caption: 'Garlic butter shrimp recipe',
    uploadStoragePath: 'recipeImports/user_1/job_1/source',
    targetLanguage: 'en',
    measurementSystem: 'metric',
    state: 'queued',
    progressPercent: 2,
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
    schemaVersion: '1.0.0',
    promptVersion: '1.0.0',
    preprocessingVersion: '1.0.0',
    draftId: null,
    finalRecipeId: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

class InMemoryJobRepository implements ImportJobRepository {
  jobs = new Map<string, RecipeImportJob>();

  async create(job: RecipeImportJob): Promise<void> {
    this.jobs.set(job.jobId, job);
  }
  async get(jobId: string): Promise<RecipeImportJob | null> {
    return this.jobs.get(jobId) ?? null;
  }
  async findByIdempotencyKey(): Promise<RecipeImportJob | null> {
    return null;
  }
  async findByUrlHash(): Promise<RecipeImportJob | null> {
    return null;
  }
  async update(jobId: string, patch: Partial<RecipeImportJob>): Promise<void> {
    const existing = this.jobs.get(jobId);
    if (!existing) throw new Error('job not found');
    this.jobs.set(jobId, { ...existing, ...patch });
  }
  async countActiveForUser(): Promise<number> {
    return 0;
  }
}

class InMemoryMediaStore implements TemporaryMediaStore {
  deletedJobIds: string[] = [];
  persistedThumbnailPaths: string[] = [];
  async uploadLocalFile(_jobId: string, localPath: string): Promise<string> {
    return `temp/${localPath}`;
  }
  async downloadToLocal(storagePath: string): Promise<string> {
    return storagePath;
  }
  async persistThumbnail(_userId: string, _jobId: string, localPath: string): Promise<string> {
    this.persistedThumbnailPaths.push(localPath);
    return 'https://cdn.example.com/recipe.jpg';
  }
  async deleteAll(jobId: string): Promise<void> {
    this.deletedJobIds.push(jobId);
  }
}

function makeDeps(overrides: Partial<PipelineDeps> = {}) {
  const repo = new InMemoryJobRepository();
  const mediaStore = new InMemoryMediaStore();
  const persistedDrafts: Array<{ jobId: string; userId: string; thumbnailUrl: string | null }> = [];

  const deps: PipelineDeps = {
    repo,
    mediaStore,
    sourceResolver: new MockMediaSourceResolver({
      kind: 'video',
      localVideoPath: '/tmp/video.mp4',
      mimeType: 'video/mp4',
      byteSize: 1000,
    }),
    preprocessor: new MockMediaPreprocessor(
      { durationSeconds: 30, hasAudioStream: true, container: 'mp4', videoCodec: 'h264' },
      { localPath: '/tmp/audio.mp3', byteSize: 1000, durationSeconds: 30 },
      [
        { localPath: '/tmp/f0.jpg', timestampMs: 0, reason: 'first' },
        { localPath: '/tmp/f1.jpg', timestampMs: 15000, reason: 'scene_change' },
        { localPath: '/tmp/f2.jpg', timestampMs: 30000, reason: 'final' },
      ],
    ),
    transcription: new MockTranscriptionProvider({
      text: 'Melt butter, add shrimp, cook three minutes.',
      languageCodes: ['en'],
      model: 'gpt-transcribe',
      requestId: 'req_1',
      durationSeconds: 30,
      usage: null,
    }),
    analysis: new MockRecipeAnalysisProvider(fixtureCompleteDraft()),
    onPersistDraft: async (jobId, userId, _draft, _transcript, _caption, thumbnailUrl) => {
      persistedDrafts.push({ jobId, userId, thumbnailUrl });
      return 'draft_1';
    },
    ...overrides,
  };

  return { deps, repo, mediaStore, persistedDrafts };
}

describe('runImportPipeline (happy path)', () => {
  it('retries thumbnail persistence once and saves the recovered URL with the draft', async () => {
    const { deps, repo, mediaStore, persistedDrafts } = makeDeps();
    const persist = jest.spyOn(mediaStore, 'persistThumbnail')
      .mockRejectedValueOnce(new Error('temporary storage outage'));
    await repo.create(baseJob());
    await runImportPipeline('job_1', deps);
    expect(persist).toHaveBeenCalledTimes(2);
    expect(persistedDrafts[0]!.thumbnailUrl).toBe('https://cdn.example.com/recipe.jpg');
  });

  it('preserves estimates and routes the draft to review', async () => {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, isEstimated: true, estimateReason: 'Based on ingredient quantities.' };
    const onPersistDraft = jest.fn().mockResolvedValue('draft_1');
    const { deps, repo } = makeDeps({ analysis: new MockRecipeAnalysisProvider(draft), onPersistDraft });
    await repo.create(baseJob());
    await runImportPipeline('job_1', deps);
    expect((await repo.get('job_1'))!.state).toBe('needs_review');
    expect(onPersistDraft.mock.calls[0]![2].servings.isEstimated).toBe(true);
  });
  it('walks queued -> completed and persists a draft', async () => {
    const { deps, repo, mediaStore, persistedDrafts } = makeDeps();
    await repo.create(baseJob());

    await runImportPipeline('job_1', deps);

    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).toBe('completed');
    expect(finalJob!.draftId).toBe('draft_1');
    expect(finalJob!.frameCount).toBe(3);
    expect(persistedDrafts).toEqual([{
      jobId: 'job_1',
      userId: 'user_1',
      thumbnailUrl: 'https://cdn.example.com/recipe.jpg',
    }]);
    expect(finalJob!.thumbnailUrl).toBe('https://cdn.example.com/recipe.jpg');
    expect(mediaStore.persistedThumbnailPaths).toEqual(['/tmp/f1.jpg']);
    expect(mediaStore.deletedJobIds).toContain('job_1');
  });

  it('routes low-confidence drafts to needs_review instead of completed', async () => {
    const { deps, repo } = makeDeps({
      analysis: new MockRecipeAnalysisProvider(fixtureCompleteDraft({ overallConfidence: 0.4 })),
    });
    await repo.create(baseJob());

    await runImportPipeline('job_1', deps);

    expect((await repo.get('job_1'))!.state).toBe('needs_review');
  });

  it('fails terminally with NOT_A_RECIPE when the model says so, without persisting a draft', async () => {
    const { deps, repo, persistedDrafts } = makeDeps({
      analysis: new MockRecipeAnalysisProvider(fixtureCompleteDraft({ status: 'not_a_recipe' })),
    });
    await repo.create(baseJob());

    await runImportPipeline('job_1', deps);

    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).toBe('failed_terminal');
    expect(finalJob!.errorCode).toBe('NOT_A_RECIPE');
    expect(persistedDrafts).toHaveLength(0);
  });

  it('continues with an empty transcript and no-audio marker when the video is silent', async () => {
    const { deps, repo } = makeDeps({
      preprocessor: new MockMediaPreprocessor(
        { durationSeconds: 20, hasAudioStream: false, container: 'mp4', videoCodec: 'h264' },
        null,
        [{ localPath: '/tmp/f0.jpg', timestampMs: 0, reason: 'first' }],
      ),
    });
    await repo.create(baseJob());

    await runImportPipeline('job_1', deps);

    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).not.toBe('failed_terminal');
    expect(finalJob!.errorCode).toBe('NO_AUDIO_CONTINUING_VISUAL_ONLY');
  });

  it('rejects videos longer than the configured max duration', async () => {
    const { deps, repo } = makeDeps({
      preprocessor: new MockMediaPreprocessor(
        { durationSeconds: 999, hasAudioStream: true, container: 'mp4', videoCodec: 'h264' },
        null,
        [],
      ),
    });
    await repo.create(baseJob());

    await expect(runImportPipeline('job_1', deps)).rejects.toBeInstanceOf(ImportError);
    const finalJob = await repo.get('job_1');
    expect(finalJob!.errorCode).toBe('VIDEO_TOO_LONG');
    expect(finalJob!.state).toBe('failed_terminal');
  });

  it('is a no-op for a job already in a terminal state', async () => {
    const { deps, repo } = makeDeps();
    await repo.create(baseJob({ state: 'cancelled' }));

    await runImportPipeline('job_1', deps);

    expect((await repo.get('job_1'))!.state).toBe('cancelled');
  });

  it('offers video upload recovery when public metadata cannot be recovered', async () => {
    const { deps, repo } = makeDeps({
      sourceResolver: {
        resolve: async () => {
          throw new ImportError('SOURCE_NOT_ACCESSIBLE', false);
        },
      },
    });
    await repo.create(baseJob({ sourceType: 'instagram_url', sourceUrl: 'https://www.instagram.com/reel/ABC/' }));

    await runImportPipeline('job_1', deps);

    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).toBe('awaiting_user_upload');
    expect(finalJob!.errorCode).toBe('SOURCE_NOT_ACCESSIBLE');
    expect(finalJob!.errorMessage).toContain('video file');
  });

  it('completes a caption-only import without preprocessing or transcription', async () => {
    const analyzeCalls: Array<{ caption: string | null; transcript: string; frameCount: number }> = [];
    const { deps, repo, persistedDrafts } = makeDeps({
      sourceResolver: new MockMediaSourceResolver({
        kind: 'caption',
        caption: 'Garlic butter shrimp: 450g shrimp, a knob of butter. Melt, add shrimp, cook 3 min per side.',
        localThumbnailPath: null,
      }),
      preprocessor: {
        probe: async () => {
          throw new Error('probe must not run for caption-only imports');
        },
        extractAudio: async () => {
          throw new Error('extractAudio must not run for caption-only imports');
        },
        extractFrames: async () => {
          throw new Error('extractFrames must not run for caption-only imports');
        },
      },
      analysis: {
        analyze: async (input) => {
          analyzeCalls.push({
            caption: input.caption,
            transcript: input.transcript,
            frameCount: input.frames.length,
          });
          return { draft: fixtureCompleteDraft(), model: 'mock-model', requestId: null, usage: null };
        },
      },
    });
    await repo.create(
      baseJob({
        sourceType: 'instagram_url',
        sourceUrl: 'https://www.instagram.com/reel/ABC/',
        uploadStoragePath: null,
        caption: null,
      }),
    );

    await runImportPipeline('job_1', deps);

    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).toBe('completed');
    expect(finalJob!.caption).toContain('Garlic butter shrimp');
    expect(persistedDrafts).toHaveLength(1);
    expect(analyzeCalls).toEqual([
      expect.objectContaining({ transcript: '', frameCount: 0 }),
    ]);
    expect(analyzeCalls[0]!.caption).toContain('Garlic butter shrimp');
  });

  it('cleans up temp media and fails terminally for a non-recoverable resolver error', async () => {
    const { deps, repo, mediaStore } = makeDeps({
      sourceResolver: {
        resolve: async () => {
          throw new ImportError('UPLOAD_REQUIRED', false);
        },
      },
    });
    await repo.create(baseJob());

    await expect(runImportPipeline('job_1', deps)).rejects.toBeInstanceOf(ImportError);
    expect(mediaStore.deletedJobIds).toContain('job_1');
    const finalJob = await repo.get('job_1');
    expect(finalJob!.state).toBe('failed_terminal');
    expect(finalJob!.errorCode).toBe('UPLOAD_REQUIRED');
  });
});

describe('chooseDishThumbnailFrame', () => {
  it('prefers a later-middle scene over the intro and end card', () => {
    expect(chooseDishThumbnailFrame([
      { localPath: 'intro.jpg', timestampMs: 0, reason: 'first' },
      { localPath: 'prep.jpg', timestampMs: 10_000, reason: 'scene_change' },
      { localPath: 'dish.jpg', timestampMs: 24_000, reason: 'scene_change' },
      { localPath: 'end.jpg', timestampMs: 30_000, reason: 'final' },
    ])?.localPath).toBe('dish.jpg');
  });
});
