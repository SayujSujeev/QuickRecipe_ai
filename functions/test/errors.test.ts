import { ImportError, userMessageFor } from '../src/domain/errors';

describe('ImportError', () => {
  it('exposes a stable user-safe message distinct from the debug message', () => {
    const error = new ImportError('SOURCE_NOT_ACCESSIBLE', true, 'raw provider stack trace: xyz');
    expect(error.userMessage).toContain('video file');
    expect(error.userMessage).not.toContain('stack trace');
  });

  it('defaults the debug message to the user message when none is given', () => {
    const error = new ImportError('RATE_LIMITED');
    expect(error.message).toBe(userMessageFor('RATE_LIMITED'));
  });

  it('every error code has a non-empty user-safe message', () => {
    const codes: Array<Parameters<typeof userMessageFor>[0]> = [
      'SOURCE_URL_INVALID', 'SOURCE_NOT_ACCESSIBLE', 'UPLOAD_REQUIRED', 'FILE_TOO_LARGE',
      'VIDEO_TOO_LONG', 'MEDIA_UNSUPPORTED', 'NO_AUDIO_CONTINUING_VISUAL_ONLY',
      'TRANSCRIPTION_TEMPORARILY_UNAVAILABLE', 'ANALYSIS_TEMPORARILY_UNAVAILABLE',
      'NOT_A_RECIPE', 'RECIPE_NEEDS_REVIEW', 'RATE_LIMITED', 'QUOTA_EXCEEDED',
      'IMPORT_CANCELLED', 'UNAUTHENTICATED', 'NOT_FOUND', 'INTERNAL',
    ];
    for (const code of codes) {
      expect(userMessageFor(code).length).toBeGreaterThan(0);
    }
  });
});
