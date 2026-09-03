import { db, storage } from '../firebase';
import { FirestoreImportJobRepository } from '../providers/firestoreJobRepository';
import { StorageTemporaryMediaStore } from '../providers/storageMediaStore';
import { DefaultMediaSourceResolver } from '../providers/mediaSourceResolver';
import { FirestoreDraftRepository } from '../providers/draftRepository';
import { FfmpegMediaPreprocessor } from '../providers/ffmpegPreprocessor';
import { OpenAiTranscriptionProvider } from '../providers/openaiTranscription';
import { OpenAiRecipeAnalysisProvider } from '../providers/openaiRecipeAnalysis';
import type { PipelineDeps } from './pipeline';

let cached: PipelineDeps | null = null;

export function buildPipelineDeps(): PipelineDeps {
  if (cached) return cached;

  const repo = new FirestoreImportJobRepository(db);
  const mediaStore = new StorageTemporaryMediaStore(storage);
  const draftRepo = new FirestoreDraftRepository(db);

  cached = {
    repo,
    mediaStore,
    sourceResolver: new DefaultMediaSourceResolver(mediaStore),
    preprocessor: new FfmpegMediaPreprocessor(),
    transcription: new OpenAiTranscriptionProvider(),
    analysis: new OpenAiRecipeAnalysisProvider(),
    onPersistDraft: (jobId, userId, draft, transcript, captionUsed, thumbnailUrl) =>
      draftRepo.persist(jobId, userId, draft, transcript, captionUsed, thumbnailUrl),
  };
  return cached;
}
