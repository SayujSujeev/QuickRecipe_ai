import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { ImportError } from '../domain/errors';

/** Requires an authenticated caller and returns their uid. */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Please sign in to import recipes.');
  }
  return uid;
}

/** Translates our internal ImportError into a client-safe HttpsError, never leaking internals. */
export function toHttpsError(error: unknown): HttpsError {
  if (error instanceof ImportError) {
    const code = error.code === 'RATE_LIMITED' || error.code === 'QUOTA_EXCEEDED'
      ? 'resource-exhausted'
      : error.code === 'NOT_FOUND'
        ? 'not-found'
        : error.code === 'UNAUTHENTICATED'
          ? 'unauthenticated'
          : 'failed-precondition';
    return new HttpsError(code, error.userMessage, { code: error.code });
  }
  if (error instanceof HttpsError) return error;

  // Unexpected error: never leak it to the client, but log it so it's
  // actually diagnosable server-side instead of vanishing into a generic
  // "internal" response.
  logger.error('Unhandled error in callable function', {
    message: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined,
  });
  return new HttpsError('internal', 'Something went wrong on our end. Please try again.', {
    code: 'INTERNAL',
  });
}
