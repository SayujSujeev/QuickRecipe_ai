import {
  assertTransition,
  canTransition,
  isTerminal,
} from '../src/domain/importJobState';

describe('import job state machine', () => {
  it('allows the happy path in order', () => {
    const happyPath = [
      'queued',
      'acquiring_source',
      'preprocessing',
      'transcribing',
      'analyzing',
      'validating',
      'completed',
    ] as const;
    for (let i = 0; i < happyPath.length - 1; i++) {
      expect(canTransition(happyPath[i]!, happyPath[i + 1]!)).toBe(true);
    }
  });

  it('allows validating -> needs_review -> completed', () => {
    expect(canTransition('validating', 'needs_review')).toBe(true);
    expect(canTransition('needs_review', 'completed')).toBe(true);
  });

  it('allows the upload-fallback branch', () => {
    expect(canTransition('validating', 'awaiting_user_upload')).toBe(true);
    expect(canTransition('acquiring_source', 'awaiting_user_upload')).toBe(true);
    expect(canTransition('awaiting_user_upload', 'preprocessing')).toBe(true);
    // After the fallback upload, processImport re-queues the job for the worker.
    expect(canTransition('awaiting_user_upload', 'queued')).toBe(true);
  });

  it('rejects skipping stages', () => {
    expect(canTransition('queued', 'analyzing')).toBe(false);
    expect(() => assertTransition('queued', 'analyzing')).toThrow();
  });

  it('rejects transitions out of terminal states', () => {
    expect(canTransition('completed', 'queued')).toBe(false);
    expect(canTransition('failed_terminal', 'queued')).toBe(false);
    expect(canTransition('cancelled', 'queued')).toBe(false);
  });

  it('allows cancellation from active states', () => {
    expect(canTransition('preprocessing', 'cancelled')).toBe(true);
    expect(canTransition('transcribing', 'cancelled')).toBe(true);
  });

  it('flags terminal states correctly', () => {
    expect(isTerminal('completed')).toBe(true);
    expect(isTerminal('failed_terminal')).toBe(true);
    expect(isTerminal('cancelled')).toBe(true);
    expect(isTerminal('queued')).toBe(false);
    expect(isTerminal('needs_review')).toBe(false);
  });

  it('rejects a no-op transition to the same state', () => {
    expect(canTransition('preprocessing', 'preprocessing')).toBe(false);
  });
});
