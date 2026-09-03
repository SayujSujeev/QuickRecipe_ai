import type { ImportErrorCode } from './errors';
import type { ImportJobState } from './importJobState';
import type { RecipeDraft } from './recipeSchema';
import type { SourceType } from '../security/urlSafety';

export interface FrameManifestEntry {
  index: number;
  timestampMs: number;
  storagePath: string;
  reason: 'first' | 'middle' | 'final' | 'scene_change' | 'uniform_sample';
}

export interface ModelUsage {
  model: string;
  requestId: string | null;
  inputTokens: number | null;
  outputTokens: number | null;
  cachedTokens: number | null;
  reasoningTokens: number | null;
  estimatedCostUsd: number | null;
}

export interface StageTimestamps {
  queuedAt: number;
  acquiringSourceAt: number | null;
  preprocessingAt: number | null;
  transcribingAt: number | null;
  analyzingAt: number | null;
  validatingAt: number | null;
  completedAt: number | null;
}

/** Firestore document shape: recipeImportJobs/{jobId} */
export interface RecipeImportJob {
  jobId: string;
  userId: string;
  idempotencyKey: string;

  sourceType: SourceType;
  sourceUrl: string | null;
  sourceUrlHash: string | null;
  caption: string | null;
  uploadStoragePath: string | null;

  targetLanguage: string;
  measurementSystem: 'metric' | 'imperial';

  state: ImportJobState;
  progressPercent: number;
  errorCode: ImportErrorCode | null;
  errorMessage: string | null;
  retryCount: number;

  /**
   * Bumped whenever processing is (re)requested while the state is already
   * `queued` — the Firestore worker trigger fires on entering `queued` OR on
   * this value changing, so a stale stuck job can be re-kicked.
   */
  requeuedAt: number | null;

  timestamps: StageTimestamps;

  transcriptionModel: string | null;
  transcriptionRequestId: string | null;
  analysisModel: string | null;
  analysisRequestId: string | null;
  usage: ModelUsage[];

  audioDurationSeconds: number | null;
  videoDurationSeconds: number | null;
  frameCount: number | null;
  frameManifest: FrameManifestEntry[] | null;
  thumbnailUrl: string | null;

  schemaVersion: string;
  promptVersion: string;
  preprocessingVersion: string;

  draftId: string | null;
  finalRecipeId: string | null;

  createdAt: number;
  updatedAt: number;
}

/** Firestore document shape: recipeDrafts/{draftId} */
export interface RecipeDraftDocument {
  draftId: string;
  jobId: string;
  userId: string;
  draft: RecipeDraft;
  transcript: string | null;
  captionUsed: string | null;
  thumbnailUrl: string | null;
  createdAt: number;
  updatedAt: number;
  approvedAt: number | null;
  approvedRecipeId: string | null;
}

/** Firestore document shape: recipeDraftCorrections/{correctionId} */
export interface RecipeDraftCorrection {
  correctionId: string;
  draftId: string;
  userId: string;
  fieldPath: string;
  previousValue: unknown;
  correctedValue: unknown;
  createdAt: number;
}

export function newStageTimestamps(now: number): StageTimestamps {
  return {
    queuedAt: now,
    acquiringSourceAt: null,
    preprocessingAt: null,
    transcribingAt: null,
    analyzingAt: null,
    validatingAt: null,
    completedAt: null,
  };
}
