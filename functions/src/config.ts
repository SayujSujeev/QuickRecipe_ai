/**
 * Central, overridable configuration for the recipe-import pipeline.
 * Values come from Firebase Functions parameters/env so limits and model
 * names can change without a code deploy.
 */

function envInt(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function envFloat(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number.parseFloat(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function envStr(name: string, fallback: string): string {
  return process.env[name] ?? fallback;
}

export const config = {
  openai: {
    transcriptionModel: envStr('OPENAI_TRANSCRIPTION_MODEL', 'gpt-transcribe'),
    recipeModel: envStr('OPENAI_RECIPE_MODEL', 'gpt-5.6-luna'),
    reasoningEffort: envStr('OPENAI_RECIPE_REASONING_EFFORT', 'low'),
    maxOutputTokens: envInt('OPENAI_RECIPE_MAX_OUTPUT_TOKENS', 3000),
    fallbackRecipeModel: process.env.OPENAI_RECIPE_FALLBACK_MODEL || null,
  },
  media: {
    maxVideoDurationSeconds: envInt('IMPORT_MAX_VIDEO_DURATION_SECONDS', 180),
    maxUploadBytes: envInt('IMPORT_MAX_UPLOAD_BYTES', 150 * 1024 * 1024),
    maxTranscriptionAudioBytes: 25 * 1024 * 1024,
    framesShortVideo: 12, // videos up to 90s
    framesLongVideo: 16, // videos 91-180s
    frameLongEdgePx: 768,
    tempRetentionSeconds: envInt('IMPORT_TEMP_RETENTION_SECONDS', 60 * 60),
    tempHardCleanupSeconds: envInt('IMPORT_TEMP_HARD_CLEANUP_SECONDS', 24 * 60 * 60),
  },
  quotas: {
    maxConcurrentJobsPerUser: envInt('IMPORT_MAX_CONCURRENT_JOBS_PER_USER', 2),
    maxDailyImportsPerUser: envInt('IMPORT_MAX_DAILY_IMPORTS_PER_USER', 20),
  },
  validation: {
    confidenceReviewThreshold: envFloat('IMPORT_CONFIDENCE_REVIEW_THRESHOLD', 0.8),
    unknownQuantityReviewRatio: 0.25,
  },
  schemaVersion: '1.0.0',
  promptVersion: '1.0.0',
  preprocessingVersion: '1.0.0',
} as const;
