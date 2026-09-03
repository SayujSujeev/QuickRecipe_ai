import { config } from '../config';
import type { ExtractedFrame } from '../providers/types';

const MIN_GAP_MS = 350;

/**
 * Enforces the frame cap and near-duplicate dedupe on an already-extracted
 * frame list (scene-change + fallback uniform samples from the
 * preprocessor). Always keeps the first, middle, and final frames when
 * present. Pure/deterministic so it's unit-testable without FFmpeg.
 */
export function selectFrameSubset(frames: ExtractedFrame[], durationSeconds: number): ExtractedFrame[] {
  if (frames.length === 0) return [];

  const sorted = [...frames].sort((a, b) => a.timestampMs - b.timestampMs);

  const deduped: ExtractedFrame[] = [];
  for (const frame of sorted) {
    const prev = deduped[deduped.length - 1];
    if (prev && frame.timestampMs - prev.timestampMs < MIN_GAP_MS && frame.reason !== 'first' && frame.reason !== 'final') {
      continue;
    }
    deduped.push(frame);
  }

  const cap = durationSeconds <= 90 ? config.media.framesShortVideo : config.media.framesLongVideo;
  if (deduped.length <= cap) return deduped;

  const mustKeep = new Set<number>();
  const firstIdx = deduped.findIndex((f) => f.reason === 'first');
  const finalIdx = [...deduped].reverse().findIndex((f) => f.reason === 'final');
  const middleIdx = Math.floor(deduped.length / 2);
  if (firstIdx >= 0) mustKeep.add(firstIdx);
  if (finalIdx >= 0) mustKeep.add(deduped.length - 1 - finalIdx);
  mustKeep.add(middleIdx);

  // Evenly sample the remaining budget across the full timeline for diversity.
  const budget = cap - mustKeep.size;
  const remainingIndices = deduped.map((_, i) => i).filter((i) => !mustKeep.has(i));
  const step = Math.max(1, Math.floor(remainingIndices.length / Math.max(budget, 1)));
  const picked = new Set(mustKeep);
  for (let i = 0; i < remainingIndices.length && picked.size < cap; i += step) {
    picked.add(remainingIndices[i]!);
  }

  return [...picked].sort((a, b) => a - b).map((i) => deduped[i]!);
}
