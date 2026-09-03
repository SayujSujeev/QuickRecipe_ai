/**
 * Stable, user-safe error codes. Never surface stack traces, provider
 * response bodies, or storage paths to clients — always translate into one
 * of these before returning/persisting.
 */
export type ImportErrorCode =
  | 'SOURCE_URL_INVALID'
  | 'SOURCE_NOT_ACCESSIBLE'
  | 'UPLOAD_REQUIRED'
  | 'FILE_TOO_LARGE'
  | 'VIDEO_TOO_LONG'
  | 'MEDIA_UNSUPPORTED'
  | 'NO_AUDIO_CONTINUING_VISUAL_ONLY'
  | 'TRANSCRIPTION_TEMPORARILY_UNAVAILABLE'
  | 'ANALYSIS_TEMPORARILY_UNAVAILABLE'
  | 'NOT_A_RECIPE'
  | 'RECIPE_NEEDS_REVIEW'
  | 'RATE_LIMITED'
  | 'QUOTA_EXCEEDED'
  | 'IMPORT_CANCELLED'
  | 'UNAUTHENTICATED'
  | 'NOT_FOUND'
  | 'INTERNAL';

const USER_MESSAGES: Record<ImportErrorCode, string> = {
  SOURCE_URL_INVALID: 'That link doesn’t look like a supported recipe video URL.',
  SOURCE_NOT_ACCESSIBLE:
    'We could not get enough recipe detail from this link. Public videos can also return a login page or an incomplete preview. Share or choose the video file to continue.',
  UPLOAD_REQUIRED: 'Please upload the video to continue importing this recipe.',
  FILE_TOO_LARGE: 'That video file is too large to import.',
  VIDEO_TOO_LONG: 'That video is longer than the current import limit.',
  MEDIA_UNSUPPORTED: 'That file format isn’t supported yet.',
  NO_AUDIO_CONTINUING_VISUAL_ONLY: 'No spoken audio was found; continuing with visual analysis only.',
  TRANSCRIPTION_TEMPORARILY_UNAVAILABLE: 'Transcription is temporarily unavailable. Please try again shortly.',
  ANALYSIS_TEMPORARILY_UNAVAILABLE: 'Recipe analysis is temporarily unavailable. Please try again shortly.',
  NOT_A_RECIPE: 'This video doesn’t appear to contain a recipe.',
  RECIPE_NEEDS_REVIEW: 'We created a draft recipe, but please review a few uncertain details.',
  RATE_LIMITED: 'You’re importing too quickly. Please wait a moment and try again.',
  QUOTA_EXCEEDED: 'You’ve reached your import limit for now.',
  IMPORT_CANCELLED: 'This import was cancelled.',
  UNAUTHENTICATED: 'Please sign in to import recipes.',
  NOT_FOUND: 'We couldn’t find that import.',
  INTERNAL: 'Something went wrong on our end. Please try again.',
};

export class ImportError extends Error {
  readonly code: ImportErrorCode;
  readonly retryable: boolean;

  constructor(code: ImportErrorCode, retryable = false, debugMessage?: string) {
    super(debugMessage ?? USER_MESSAGES[code]);
    this.name = 'ImportError';
    this.code = code;
    this.retryable = retryable;
  }

  get userMessage(): string {
    return USER_MESSAGES[this.code];
  }
}

export function userMessageFor(code: ImportErrorCode): string {
  return USER_MESSAGES[code];
}
