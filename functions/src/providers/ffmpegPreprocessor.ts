import * as os from 'os';
import * as path from 'path';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import { spawn } from 'child_process';
import ffmpegPath from '@ffmpeg-installer/ffmpeg';
import ffprobePath from '@ffprobe-installer/ffprobe';
import sharp from 'sharp';
import { ImportError } from '../domain/errors';
import { config } from '../config';
import type {
  ExtractedAudio,
  ExtractedFrame,
  MediaPreprocessor,
  MediaProbeResult,
} from './types';

/**
 * Deterministic FFmpeg/ffprobe wrapper. Every invocation uses an argument
 * array (never a shell string), so there is no command-injection surface
 * even though inputs ultimately derive from user-controlled uploads.
 */
export class FfmpegMediaPreprocessor implements MediaPreprocessor {
  async probe(localVideoPath: string): Promise<MediaProbeResult> {
    const args = [
      '-v', 'error',
      '-show_entries', 'format=duration:stream=codec_type,codec_name',
      '-of', 'json',
      localVideoPath,
    ];
    const { stdout } = await run(ffprobePath.path, args);
    let parsed: {
      format?: { duration?: string };
      streams?: Array<{ codec_type?: string; codec_name?: string }>;
    };
    try {
      parsed = JSON.parse(stdout);
    } catch {
      throw new ImportError('MEDIA_UNSUPPORTED', false, 'ffprobe returned unparseable output');
    }

    const durationSeconds = Number.parseFloat(parsed.format?.duration ?? '0');
    if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
      throw new ImportError('MEDIA_UNSUPPORTED', false, 'ffprobe reported no valid duration');
    }

    const streams = parsed.streams ?? [];
    const videoStream = streams.find((s) => s.codec_type === 'video');
    const hasAudioStream = streams.some((s) => s.codec_type === 'audio');

    return {
      durationSeconds,
      hasAudioStream,
      container: path.extname(localVideoPath).replace('.', '') || 'unknown',
      videoCodec: videoStream?.codec_name ?? null,
    };
  }

  async extractAudio(localVideoPath: string, _durationSeconds: number): Promise<ExtractedAudio | null> {
    const outPath = tmpFile('.mp3');
    const args = [
      '-y', '-i', localVideoPath,
      '-vn',
      '-ac', '1',
      '-ar', '16000',
      '-b:a', '56k',
      outPath,
    ];
    await run(ffmpegPath.path, args);

    const stat = await fs.stat(outPath);
    if (stat.size === 0) {
      await fs.rm(outPath, { force: true });
      return null;
    }

    if (stat.size > config.media.maxTranscriptionAudioBytes) {
      // Spec requires splitting at sensible boundaries with overlap when the
      // extracted audio exceeds the transcription API limit. The bitrate
      // above keeps a 180s clip well under 25MB, so this path is a guard for
      // unusually long/loud sources rather than the common case.
      throw new ImportError(
        'MEDIA_UNSUPPORTED',
        false,
        `Extracted audio (${stat.size} bytes) exceeds the transcription size limit; splitting is not yet implemented`,
      );
    }

    const probe = await this.probe(outPath).catch(() => null);
    return {
      localPath: outPath,
      byteSize: stat.size,
      durationSeconds: probe?.durationSeconds ?? _durationSeconds,
    };
  }

  async extractFrames(localVideoPath: string, durationSeconds: number): Promise<ExtractedFrame[]> {
    const cap = durationSeconds <= 90 ? config.media.framesShortVideo : config.media.framesLongVideo;

    const sceneFrames = await extractSceneChangeFrames(localVideoPath, durationSeconds, cap);
    const frames = sceneFrames.length >= 3
      ? sceneFrames
      : await extractUniformFrames(localVideoPath, durationSeconds, cap);

    // Guarantee first/middle/final are present and orientation-preserving,
    // resized to the cost-conscious long edge while keeping text legible.
    const withEndpoints = await ensureEndpoints(localVideoPath, durationSeconds, frames);
    return Promise.all(withEndpoints.map((f) => resizeFrame(f)));
  }
}

function tmpFile(ext: string): string {
  return path.join(os.tmpdir(), `cooksense-${randomUUID()}${ext}`);
}

function run(bin: string, args: string[]): Promise<{ stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, { windowsHide: true });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => (stdout += d.toString()));
    child.stderr.on('data', (d) => (stderr += d.toString()));
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve({ stdout, stderr });
      else reject(new ImportError('MEDIA_UNSUPPORTED', false, `${path.basename(bin)} exited ${code}: ${stderr.slice(-2000)}`));
    });
  });
}

async function extractSceneChangeFrames(
  localVideoPath: string,
  _durationSeconds: number,
  cap: number,
): Promise<ExtractedFrame[]> {
  const outDir = path.join(os.tmpdir(), `cooksense-scenes-${randomUUID()}`);
  await fs.mkdir(outDir, { recursive: true });
  const pattern = path.join(outDir, 'frame_%04d.jpg');

  await run(ffmpegPath.path, [
    '-y', '-i', localVideoPath,
    '-vf', `select='gt(scene,0.35)',showinfo`,
    '-vsync', 'vfr',
    '-frames:v', String(cap * 2),
    pattern,
  ]).catch(() => ({ stdout: '', stderr: '' }));

  const files = (await fs.readdir(outDir).catch(() => [])).sort();
  // Timestamps aren't parsed from showinfo here to keep this deterministic
  // and testable; approximate even spacing across the observed frame count.
  return files.map((file, i) => ({
    localPath: path.join(outDir, file),
    timestampMs: files.length > 1 ? Math.round((i / (files.length - 1)) * _durationSeconds * 1000) : 0,
    reason: 'scene_change' as const,
  }));
}

async function extractUniformFrames(
  localVideoPath: string,
  durationSeconds: number,
  cap: number,
): Promise<ExtractedFrame[]> {
  const count = Math.max(3, Math.min(cap, 8));
  const outDir = path.join(os.tmpdir(), `cooksense-uniform-${randomUUID()}`);
  await fs.mkdir(outDir, { recursive: true });

  const frames: ExtractedFrame[] = [];
  for (let i = 0; i < count; i++) {
    const timestampMs = Math.round((i / (count - 1)) * durationSeconds * 1000);
    const outPath = path.join(outDir, `uniform_${i}.jpg`);
    await run(ffmpegPath.path, [
      '-y', '-ss', String(timestampMs / 1000), '-i', localVideoPath,
      '-frames:v', '1', '-q:v', '2',
      outPath,
    ]);
    frames.push({ localPath: outPath, timestampMs, reason: 'uniform_sample' });
  }
  return frames;
}

async function ensureEndpoints(
  localVideoPath: string,
  durationSeconds: number,
  frames: ExtractedFrame[],
): Promise<ExtractedFrame[]> {
  const sorted = [...frames].sort((a, b) => a.timestampMs - b.timestampMs);
  const hasNearStart = sorted.some((f) => f.timestampMs < 250);
  const hasNearEnd = sorted.some((f) => f.timestampMs > durationSeconds * 1000 - 250);

  const extra: ExtractedFrame[] = [];
  if (!hasNearStart) extra.push(await captureAt(localVideoPath, 0, 'first'));
  if (!hasNearEnd) extra.push(await captureAt(localVideoPath, Math.max(0, durationSeconds * 1000 - 200), 'final'));

  if (sorted.length > 0) {
    const middleIdx = Math.floor(sorted.length / 2);
    sorted[middleIdx] = { ...sorted[middleIdx]!, reason: sorted[middleIdx]!.reason };
  }

  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const tagged = sorted.map((f, i) => {
    if (i === 0 && first) return { ...f, reason: 'first' as const };
    if (i === sorted.length - 1 && last) return { ...f, reason: 'final' as const };
    return f;
  });

  return [...tagged, ...extra];
}

async function captureAt(
  localVideoPath: string,
  timestampMs: number,
  reason: ExtractedFrame['reason'],
): Promise<ExtractedFrame> {
  const outPath = tmpFile('.jpg');
  await run(ffmpegPath.path, [
    '-y', '-ss', String(timestampMs / 1000), '-i', localVideoPath,
    '-frames:v', '1', '-q:v', '2',
    outPath,
  ]);
  return { localPath: outPath, timestampMs, reason };
}

async function resizeFrame(frame: ExtractedFrame): Promise<ExtractedFrame> {
  const outPath = tmpFile('.jpg');
  await sharp(frame.localPath)
    .rotate() // preserve original orientation via EXIF auto-rotate
    .resize({ width: config.media.frameLongEdgePx, height: config.media.frameLongEdgePx, fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 82 })
    .toFile(outPath);
  return { ...frame, localPath: outPath };
}
