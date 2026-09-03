import { selectFrameSubset } from '../src/worker/frameSelection';
import type { ExtractedFrame } from '../src/providers/types';

function frame(timestampMs: number, reason: ExtractedFrame['reason'] = 'scene_change'): ExtractedFrame {
  return { localPath: `/tmp/${timestampMs}.jpg`, timestampMs, reason };
}

describe('selectFrameSubset', () => {
  it('returns an empty array for no frames', () => {
    expect(selectFrameSubset([], 30)).toEqual([]);
  });

  it('keeps all frames when under the cap for a short video', () => {
    const frames = [frame(0, 'first'), frame(5000), frame(10000, 'final')];
    expect(selectFrameSubset(frames, 15)).toHaveLength(3);
  });

  it('drops near-duplicate frames closer than the minimum gap', () => {
    const frames = [frame(0, 'first'), frame(100), frame(200), frame(10000, 'final')];
    const result = selectFrameSubset(frames, 15);
    expect(result.length).toBeLessThan(frames.length);
  });

  it('caps at 12 frames for videos up to 90 seconds', () => {
    const frames = Array.from({ length: 40 }, (_, i) => frame(i * 2000));
    const result = selectFrameSubset(frames, 80);
    expect(result.length).toBeLessThanOrEqual(12);
  });

  it('caps at 16 frames for videos between 91 and 180 seconds', () => {
    const frames = Array.from({ length: 60 }, (_, i) => frame(i * 3000));
    const result = selectFrameSubset(frames, 170);
    expect(result.length).toBeLessThanOrEqual(16);
  });

  it('keeps frames chronologically ordered', () => {
    const frames = [frame(9000), frame(0, 'first'), frame(4500), frame(12000, 'final')];
    const result = selectFrameSubset(frames, 12);
    const timestamps = result.map((f) => f.timestampMs);
    expect(timestamps).toEqual([...timestamps].sort((a, b) => a - b));
  });
});
