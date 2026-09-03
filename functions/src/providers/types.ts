import type { RecipeDraft } from '../domain/recipeSchema';
import type { FrameManifestEntry, ModelUsage, RecipeImportJob } from '../domain/importJob';

/**
 * Resolves a permitted source into analyzable evidence: a local video file
 * (uploaded media) or public caption text (compliant Instagram metadata —
 * the same signal ChatGPT-style link handling uses; the video itself is
 * never scraped).
 */
export interface MediaSourceResolver {
  resolve(job: RecipeImportJob): Promise<ResolvedSource>;
}

export type ResolvedSource = ResolvedVideo | ResolvedCaption;

export interface ResolvedVideo {
  kind: 'video';
  localVideoPath: string;
  mimeType: string;
  byteSize: number;
}

export interface ResolvedCaption {
  kind: 'caption';
  caption: string;
  localThumbnailPath: string | null;
}

/** Deterministic FFmpeg/ffprobe-based audio + frame extraction. */
export interface MediaPreprocessor {
  probe(localVideoPath: string): Promise<MediaProbeResult>;
  extractAudio(localVideoPath: string, durationSeconds: number): Promise<ExtractedAudio | null>;
  extractFrames(localVideoPath: string, durationSeconds: number): Promise<ExtractedFrame[]>;
}

export interface MediaProbeResult {
  durationSeconds: number;
  hasAudioStream: boolean;
  container: string;
  videoCodec: string | null;
}

export interface ExtractedAudio {
  localPath: string;
  byteSize: number;
  durationSeconds: number;
}

export interface ExtractedFrame {
  localPath: string;
  timestampMs: number;
  reason: FrameManifestEntry['reason'];
}

export interface TranscriptionResult {
  text: string;
  languageCodes: string[];
  model: string;
  requestId: string | null;
  durationSeconds: number;
  usage: ModelUsage | null;
}

export interface TranscriptionProvider {
  transcribe(audioPath: string, options: { promptContext: string }): Promise<TranscriptionResult>;
}

export interface AnalysisInput {
  caption: string | null;
  transcript: string;
  frames: Array<{ timestampMs: number; localPath: string }>;
  targetLanguage: string;
  measurementSystem: 'metric' | 'imperial';
  correctivePrompt?: string;
}

export interface AnalysisResult {
  draft: RecipeDraft;
  model: string;
  requestId: string | null;
  usage: ModelUsage | null;
}

export interface RecipeAnalysisProvider {
  analyze(input: AnalysisInput): Promise<AnalysisResult>;
}

/** Short-lived, encrypted temp storage for media during a single job's processing. */
export interface TemporaryMediaStore {
  uploadLocalFile(jobId: string, localPath: string, kind: 'video' | 'audio' | 'frame'): Promise<string>;
  persistThumbnail(userId: string, jobId: string, localPath: string): Promise<string>;
  downloadToLocal(storagePath: string): Promise<string>;
  deleteAll(jobId: string): Promise<void>;
}

export interface ImportJobRepository {
  create(job: RecipeImportJob): Promise<void>;
  get(jobId: string): Promise<RecipeImportJob | null>;
  findByIdempotencyKey(userId: string, idempotencyKey: string): Promise<RecipeImportJob | null>;
  findByUrlHash(userId: string, sourceUrlHash: string): Promise<RecipeImportJob | null>;
  update(jobId: string, patch: Partial<RecipeImportJob>): Promise<void>;
  countActiveForUser(userId: string): Promise<number>;
}
