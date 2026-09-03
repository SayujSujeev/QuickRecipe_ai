import * as os from 'os';
import * as path from 'path';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import sharp from 'sharp';
import type { MediaSourceResolver, ResolvedSource, TemporaryMediaStore } from './types';
import type { RecipeImportJob } from '../domain/importJob';
import { ImportError } from '../domain/errors';
import { assertPublicHost, FETCH_SAFETY } from '../security/urlSafety';

const MIN_USEFUL_CAPTION_CHARS = 8;
const MAX_HTML_BYTES = 600_000;
const MAX_THUMBNAIL_BYTES = 12 * 1024 * 1024;
const MAX_THUMBNAIL_ATTEMPTS = 4;
const BROWSER_USER_AGENT = 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126 Mobile Safari/537.36';
const REDIRECT_STATUSES = new Set([301, 302, 303, 307, 308]);

export interface PublicSocialMetadata {
  caption: string | null;
  thumbnailUrl: string | null;
  thumbnailUrls: string[];
}

/**
 * Resolves user-uploaded video into the full audiovisual pipeline, while URL
 * imports use only public link-preview metadata. No protected video is scraped
 * or downloaded. A URL that exposes too little evidence is sent to the upload
 * recovery state by the pipeline instead of becoming a dead-end failure.
 */
export class DefaultMediaSourceResolver implements MediaSourceResolver {
  constructor(private readonly mediaStore: TemporaryMediaStore) {}

  async resolve(job: RecipeImportJob): Promise<ResolvedSource> {
    if (job.uploadStoragePath) {
      const localVideoPath = await this.mediaStore.downloadToLocal(job.uploadStoragePath);
      return { kind: 'video', localVideoPath, mimeType: 'video/mp4', byteSize: 0 };
    }

    if (job.sourceType === 'caption_only') {
      const caption = job.caption?.trim();
      if (!caption) throw new ImportError('SOURCE_NOT_ACCESSIBLE');
      return { kind: 'caption', caption, localThumbnailPath: null };
    }

    if (job.sourceType === 'uploaded_video') throw new ImportError('UPLOAD_REQUIRED');
    if (!job.sourceUrl) throw new ImportError('SOURCE_URL_INVALID');

    let caption = '';
    let localThumbnailPath: string | null = null;
    const attempted = new Set<string>();
    for await (const metadata of recoverPublicMetadata(job.sourceUrl)) {
      caption = chooseLonger(caption, metadata.caption)?.trim() ?? '';
      if (!localThumbnailPath) {
        for (const candidate of metadata.thumbnailUrls) {
          if (attempted.has(candidate) || attempted.size >= MAX_THUMBNAIL_ATTEMPTS) continue;
          attempted.add(candidate);
          localThumbnailPath = await downloadPublicThumbnail(candidate, job.sourceUrl).catch(() => null);
          if (localThumbnailPath) break;
        }
      }
      if (caption.length >= MIN_USEFUL_CAPTION_CHARS && localThumbnailPath) break;
    }
    if (caption.length < MIN_USEFUL_CAPTION_CHARS) {
      if (localThumbnailPath) await fs.rm(localThumbnailPath, { force: true }).catch(() => undefined);
      throw new ImportError('SOURCE_NOT_ACCESSIBLE');
    }
    return { kind: 'caption', caption, localThumbnailPath };
  }
}

async function* recoverPublicMetadata(sourceUrl: string): AsyncGenerator<PublicSocialMetadata> {
  const host = new URL(sourceUrl).hostname;
  const userAgents = (host === 'instagram.com' || host === 'www.instagram.com')
    ? [
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        BROWSER_USER_AGENT,
      ]
    : [
        BROWSER_USER_AGENT,
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      ];

  for (const userAgent of userAgents) {
    const fetched = await fetchPublicResource(
      sourceUrl,
      { Accept: 'text/html,application/xhtml+xml', 'User-Agent': userAgent },
      MAX_HTML_BYTES,
      true,
    ).catch(() => null);
    if (!fetched || !fetched.contentType.toLowerCase().includes('text/html')) continue;

    // The next representation is tried if its first preview image failed,
    // rather than treating the existence of an image URL as success.
    yield extractPublicMetadata(fetched.body.toString('utf8'), fetched.finalUrl);
  }
}

async function downloadPublicThumbnail(thumbnailUrl: string, sourceUrl: string): Promise<string | null> {
  const fetched = await fetchPublicResource(
    thumbnailUrl,
    {
      Accept: 'image/avif,image/webp,image/apng,image/jpeg,image/png,image/*',
      'User-Agent': BROWSER_USER_AGENT,
      Referer: `${new URL(sourceUrl).origin}/`,
    },
    MAX_THUMBNAIL_BYTES,
  );
  // Decode the actual bytes, not just the server's often-inaccurate MIME type.
  // This also stops login HTML, video URLs and tracking pixels being saved as
  // dish photos, and ensures the vision API really receives JPEG bytes.
  const image = sharp(fetched.body, { limitInputPixels: 40_000_000 });
  const metadata = await image.metadata();
  if (!['jpeg', 'png', 'webp', 'heif', 'avif', 'gif'].includes(metadata.format ?? '') ||
      (metadata.width ?? 0) < 80 || (metadata.height ?? 0) < 80) return null;
  const jpeg = await image.rotate()
    .resize({ width: 1200, height: 1200, fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 86 }).toBuffer();
  const localPath = path.join(os.tmpdir(), `cooksense-thumbnail-${randomUUID()}.jpg`);
  await fs.writeFile(localPath, jpeg);
  return localPath;
}

async function fetchPublicResource(
  rawUrl: string,
  headers: Record<string, string>,
  maxBytes: number,
  allowHtmlPrefix = false,
): Promise<{ body: Buffer; contentType: string; finalUrl: string }> {
  let current = new URL(rawUrl);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_SAFETY.totalTimeoutMs);

  try {
    for (let redirects = 0; redirects <= FETCH_SAFETY.maxRedirects; redirects++) {
      if (
        current.protocol !== 'https:' ||
        current.username ||
        current.password ||
        (current.port && current.port !== '443')
      ) {
        throw new ImportError('SOURCE_URL_INVALID');
      }
      await assertPublicHost(current.hostname);

      const response = await fetch(current, {
        redirect: 'manual',
        signal: controller.signal,
        headers,
      });

      if (REDIRECT_STATUSES.has(response.status)) {
        await response.body?.cancel().catch(() => undefined);
        if (redirects === FETCH_SAFETY.maxRedirects) {
          throw new ImportError('SOURCE_NOT_ACCESSIBLE', true, 'Too many source redirects');
        }
        const location = response.headers.get('location');
        if (!location) throw new ImportError('SOURCE_NOT_ACCESSIBLE');
        current = new URL(location, current);
        continue;
      }

      if (!response.ok || !response.body) {
        await response.body?.cancel().catch(() => undefined);
        throw new ImportError(
          'SOURCE_NOT_ACCESSIBLE',
          response.status >= 500 || response.status === 429,
          `Source returned HTTP ${response.status}`,
        );
      }

      const declaredSize = Number.parseInt(response.headers.get('content-length') ?? '0', 10);
      if (declaredSize > maxBytes && !allowHtmlPrefix) {
        await response.body.cancel().catch(() => undefined);
        throw new ImportError('FILE_TOO_LARGE');
      }

      const chunks: Buffer[] = [];
      let received = 0;
      const reader = response.body.getReader();
      let nextChunk = await reader.read();
      while (!nextChunk.done) {
        const { value } = nextChunk;
        const remaining = maxBytes - received;
        if (value.byteLength > remaining) {
          await reader.cancel().catch(() => undefined);
          if (!allowHtmlPrefix) throw new ImportError('FILE_TOO_LARGE');
          // Social pages can contain megabytes of scripts after the useful
          // head metadata. Read a bounded prefix instead of discarding valid
          // previews just because the rest of the document is large.
          chunks.push(Buffer.from(value.subarray(0, remaining)));
          break;
        }
        received += value.byteLength;
        chunks.push(Buffer.from(value));
        if (allowHtmlPrefix && received === maxBytes) {
          await reader.cancel().catch(() => undefined);
          break;
        }
        nextChunk = await reader.read();
      }
      return {
        body: Buffer.concat(chunks),
        contentType: response.headers.get('content-type') ?? '',
        finalUrl: current.toString(),
      };
    }
  } finally {
    clearTimeout(timeout);
  }
  throw new ImportError('SOURCE_NOT_ACCESSIBLE');
}

/** Extracts caption/title and thumbnail candidates from OpenGraph, Twitter,
 * standard meta tags, and JSON-LD. Attribute order and quote style are both
 * intentionally ignored because real social pages vary them frequently. */
export function extractPublicMetadata(html: string, baseUrl?: string): PublicSocialMetadata {
  const captionCandidates: string[] = [];
  const thumbnailCandidates: string[] = [];

  for (const tag of html.match(/<meta\b[^>]*>/gi) ?? []) {
    const attrs = parseHtmlAttributes(tag);
    const key = (attrs.property ?? attrs.name ?? attrs.itemprop ?? '').toLowerCase();
    const content = attrs.content ? decodeHtmlEntities(attrs.content).trim() : '';
    if (!content) continue;

    if (['og:description', 'twitter:description', 'description', 'og:title', 'twitter:title'].includes(key)) {
      captionCandidates.push(cleanSocialCaption(content));
    }
    if (['og:image:secure_url', 'og:image', 'twitter:image', 'twitter:image:src', 'thumbnailurl'].includes(key)) {
      thumbnailCandidates.push(content);
    }
  }

  for (const tag of html.match(/<(?:video|link)\b[^>]*>/gi) ?? []) {
    const attrs = parseHtmlAttributes(tag);
    const candidate = attrs.poster ?? (attrs.rel?.toLowerCase() === 'image_src' ? attrs.href : null);
    if (candidate) thumbnailCandidates.push(decodeHtmlEntities(candidate));
  }

  for (const scriptMatch of html.matchAll(
    /<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi,
  )) {
    try {
      const value = JSON.parse(decodeHtmlEntities(scriptMatch[1]!.trim())) as unknown;
      collectJsonLdMetadata(value, captionCandidates, thumbnailCandidates, 0);
    } catch {
      // Malformed JSON-LD is common and should not discard valid OG tags.
    }
  }

  const cleanedCaptions = captionCandidates
    .map((value) => value.trim())
    .filter((value) => value.length > 0 && !isBoilerplate(value));
  const caption = cleanedCaptions.length === 0
    ? null
    : cleanedCaptions.reduce((longest, value) => (value.length > longest.length ? value : longest));

  const thumbnailUrls: string[] = [];
  for (const candidate of thumbnailCandidates) {
    try {
      const parsed = baseUrl ? new URL(candidate, baseUrl) : new URL(candidate);
      if (parsed.protocol === 'https:' && !parsed.username && !parsed.password &&
          (!parsed.port || parsed.port === '443') && !thumbnailUrls.includes(parsed.toString())) {
        thumbnailUrls.push(parsed.toString());
      }
    } catch {
      // Ignore malformed image URLs and continue to the next candidate.
    }
  }

  return { caption, thumbnailUrl: thumbnailUrls[0] ?? null, thumbnailUrls };
}

/** Backwards-compatible helper used by focused extraction tests. */
export function extractCaption(html: string): string | null {
  return extractPublicMetadata(html).caption;
}

export function extractThumbnailUrl(html: string, baseUrl?: string): string | null {
  return extractPublicMetadata(html, baseUrl).thumbnailUrl;
}

function parseHtmlAttributes(tag: string): Record<string, string> {
  const attrs: Record<string, string> = {};
  const attributePattern = /([:\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g;
  for (const match of tag.matchAll(attributePattern)) {
    attrs[match[1]!.toLowerCase()] = match[2] ?? match[3] ?? match[4] ?? '';
  }
  return attrs;
}

function collectJsonLdMetadata(
  value: unknown,
  captions: string[],
  thumbnails: string[],
  depth: number,
): void {
  if (depth > 8 || value === null || typeof value !== 'object') return;
  if (Array.isArray(value)) {
    for (const item of value.slice(0, 50)) collectJsonLdMetadata(item, captions, thumbnails, depth + 1);
    return;
  }

  const object = value as Record<string, unknown>;
  for (const key of ['description', 'caption', 'name', 'headline']) {
    if (typeof object[key] === 'string') captions.push(cleanSocialCaption(object[key]));
  }
  // VideoObject.contentUrl is the video, NOT its poster image. Only treat
  // contentUrl as an image when JSON-LD explicitly describes an ImageObject.
  const types = Array.isArray(object['@type']) ? object['@type'] : [object['@type']];
  const imageKeys = types.includes('ImageObject') ? ['thumbnailUrl', 'contentUrl'] : ['thumbnailUrl'];
  for (const key of imageKeys) {
    const candidate = object[key];
    if (typeof candidate === 'string') thumbnails.push(candidate);
    if (Array.isArray(candidate)) {
      for (const item of candidate) if (typeof item === 'string') thumbnails.push(item);
    }
  }
  collectImageUrls(object.image, thumbnails);

  for (const child of Object.values(object)) {
    if (child && typeof child === 'object') collectJsonLdMetadata(child, captions, thumbnails, depth + 1);
  }
}

function collectImageUrls(value: unknown, thumbnails: string[], depth = 0): void {
  if (depth > 8) return;
  if (typeof value === 'string') thumbnails.push(value);
  else if (Array.isArray(value)) {
    for (const item of value.slice(0, 50)) collectImageUrls(item, thumbnails, depth + 1);
  } else if (value && typeof value === 'object') {
    const image = value as Record<string, unknown>;
    for (const key of ['url', 'contentUrl', '@id']) {
      if (typeof image[key] === 'string') thumbnails.push(image[key]);
    }
  }
}

function cleanSocialCaption(text: string): string {
  const instagram = text.match(/on Instagram:\s*["“]([\s\S]*)["”]\s*$/i);
  if (instagram?.[1]) return instagram[1].trim();
  return text
    .replace(/\s*[-|]\s*(Instagram|TikTok|YouTube|Facebook)\s*$/i, '')
    .trim();
}

function isBoilerplate(text: string): boolean {
  const normalized = text.toLowerCase().replace(/\s+/g, ' ').trim();
  return [
    'instagram',
    'tiktok',
    'youtube',
    'facebook',
    'tiktok - make your day',
    'log in or sign up to view',
  ].includes(normalized);
}

function chooseLonger(first: string | null, second: string | null): string | null {
  if (!first) return second;
  if (!second) return first;
  return second.length > first.length ? second : first;
}

function decodeHtmlEntities(text: string): string {
  return text
    .replace(/&#(\d+);/g, (_, code: string) => String.fromCodePoint(Number.parseInt(code, 10)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, code: string) => String.fromCodePoint(Number.parseInt(code, 16)))
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&apos;|&#0*39;/gi, "'")
    .replace(/&nbsp;/gi, ' ');
}
