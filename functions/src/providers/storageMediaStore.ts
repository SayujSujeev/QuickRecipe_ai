import * as os from 'os';
import * as path from 'path';
import { promises as fs } from 'fs';
import { randomUUID } from 'crypto';
import type { Storage } from 'firebase-admin/storage';
import sharp from 'sharp';
import type { TemporaryMediaStore } from './types';

const TEMP_PREFIX = 'recipeImportsTemp';

/**
 * Short-lived Storage-backed temp media store. Objects live under
 * `recipeImportsTemp/{jobId}/...` (distinct from the client-writable
 * `recipeImports/{userId}/{jobId}/` upload path) and are deleted after the
 * job reaches a terminal state or by the scheduled TTL sweep — never kept
 * beyond that.
 */
export class StorageTemporaryMediaStore implements TemporaryMediaStore {
  constructor(private readonly storage: Storage, private readonly bucketName?: string) {}

  private bucket() {
    return this.bucketName ? this.storage.bucket(this.bucketName) : this.storage.bucket();
  }

  async uploadLocalFile(jobId: string, localPath: string, kind: 'video' | 'audio' | 'frame'): Promise<string> {
    const ext = path.extname(localPath) || defaultExtFor(kind);
    const storagePath = `${TEMP_PREFIX}/${jobId}/${kind}/${randomUUID()}${ext}`;
    await this.bucket().upload(localPath, {
      destination: storagePath,
      metadata: { cacheControl: 'no-store' },
    });
    return storagePath;
  }

  /**
   * Keeps one compact dish image after temporary video evidence is deleted.
   * Firebase's download token produces a stable HTTPS URL that Image.network
   * can render without making the whole bucket public.
   */
  async persistThumbnail(userId: string, jobId: string, localPath: string): Promise<string> {
    const outputPath = path.join(os.tmpdir(), `cooksense-recipe-thumbnail-${randomUUID()}.jpg`);
    await sharp(localPath)
      .rotate()
      .resize({ width: 1200, height: 1200, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 86, mozjpeg: true })
      .toFile(outputPath);

    const storagePath = `recipeThumbnails/${userId}/${jobId}.jpg`;
    const downloadToken = randomUUID();
    const bucket = this.bucket();
    try {
      await bucket.upload(outputPath, {
        destination: storagePath,
        metadata: {
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=31536000,immutable',
          metadata: { firebaseStorageDownloadTokens: downloadToken },
        },
      });
    } finally {
      await fs.rm(outputPath, { force: true }).catch(() => undefined);
    }

    return `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucket.name)}` +
      `/o/${encodeURIComponent(storagePath)}?alt=media&token=${encodeURIComponent(downloadToken)}`;
  }

  async downloadToLocal(storagePath: string): Promise<string> {
    const localPath = path.join(os.tmpdir(), `cooksense-${randomUUID()}${path.extname(storagePath)}`);
    await this.bucket().file(storagePath).download({ destination: localPath });
    return localPath;
  }

  async deleteAll(jobId: string): Promise<void> {
    await this.bucket()
      .deleteFiles({ prefix: `${TEMP_PREFIX}/${jobId}/` })
      .catch(() => undefined);
    // Also remove the user-uploaded source file for this job, if any.
    await this.bucket()
      .deleteFiles({ prefix: `recipeImports/`, matchGlob: `**/${jobId}/**` })
      .catch(() => undefined);
  }
}

function defaultExtFor(kind: 'video' | 'audio' | 'frame'): string {
  switch (kind) {
    case 'video':
      return '.mp4';
    case 'audio':
      return '.mp3';
    case 'frame':
      return '.jpg';
  }
}

export async function cleanupLocalFile(localPath: string): Promise<void> {
  await fs.rm(localPath, { force: true }).catch(() => undefined);
}
