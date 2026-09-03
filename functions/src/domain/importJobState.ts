export type ImportJobState =
  | 'queued'
  | 'acquiring_source'
  | 'awaiting_user_upload'
  | 'preprocessing'
  | 'transcribing'
  | 'analyzing'
  | 'validating'
  | 'needs_review'
  | 'completed'
  | 'failed_retryable'
  | 'failed_terminal'
  | 'cancelled';

export const TERMINAL_STATES: ReadonlySet<ImportJobState> = new Set([
  'completed',
  'failed_terminal',
  'cancelled',
]);

/** Allowed forward transitions. Cancellation is allowed from any non-terminal state. */
const TRANSITIONS: Record<ImportJobState, ImportJobState[]> = {
  queued: ['acquiring_source', 'failed_retryable', 'failed_terminal', 'cancelled'],
  acquiring_source: [
    'preprocessing',
    'awaiting_user_upload',
    'failed_retryable',
    'failed_terminal',
    'cancelled',
  ],
  awaiting_user_upload: ['queued', 'preprocessing', 'failed_terminal', 'cancelled'],
  preprocessing: ['transcribing', 'failed_retryable', 'failed_terminal', 'cancelled'],
  transcribing: ['analyzing', 'failed_retryable', 'failed_terminal', 'cancelled'],
  analyzing: ['validating', 'failed_retryable', 'failed_terminal', 'cancelled'],
  validating: ['needs_review', 'completed', 'failed_retryable', 'failed_terminal', 'cancelled'],
  needs_review: ['completed', 'cancelled'],
  completed: [],
  failed_retryable: ['queued', 'acquiring_source', 'preprocessing', 'failed_terminal', 'cancelled'],
  failed_terminal: [],
  cancelled: [],
};

export function isTerminal(state: ImportJobState): boolean {
  return TERMINAL_STATES.has(state);
}

export function canTransition(from: ImportJobState, to: ImportJobState): boolean {
  if (from === to) return false;
  return TRANSITIONS[from].includes(to);
}

export function assertTransition(from: ImportJobState, to: ImportJobState): void {
  if (!canTransition(from, to)) {
    throw new Error(`Illegal import job transition: ${from} -> ${to}`);
  }
}

/** Coarse progress percentage for client display, monotonic within the happy path. */
export const STATE_PROGRESS: Record<ImportJobState, number> = {
  queued: 2,
  acquiring_source: 10,
  awaiting_user_upload: 10,
  preprocessing: 30,
  transcribing: 50,
  analyzing: 75,
  validating: 90,
  needs_review: 95,
  completed: 100,
  failed_retryable: 0,
  failed_terminal: 0,
  cancelled: 0,
};

export const STATE_LABEL: Record<ImportJobState, string> = {
  queued: 'Preparing source',
  acquiring_source: 'Preparing source',
  awaiting_user_upload: 'Waiting for upload',
  preprocessing: 'Processing video',
  transcribing: 'Transcribing audio',
  analyzing: 'Creating recipe',
  validating: 'Creating recipe',
  needs_review: 'Ready for review',
  completed: 'Ready for review',
  failed_retryable: 'Retrying',
  failed_terminal: 'Failed',
  cancelled: 'Cancelled',
};
