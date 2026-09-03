import * as os from 'os';
import * as path from 'path';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import type { MediaSourceResolver, ResolvedSource, TemporaryMediaStore } from './types';
import type { RecipeImportJob } from '../domain/importJob';
import { ImportError } from '../domain/errors';
import { assertPublicHost, FETCH_SAFETY } from '../security/urlSafety';

const MIN_USEFUL_CAPTION_CHARS = 8;
const MAX_HTML_BYTES = 600_000;
const MAX_THUMBNAIL_BYTES = 12 * 1024 * 1024;
const REDIRECT_STATUSES = new Set([301, 302, 303, 307, 308]);

export interface PublicSocialMetadata {
  caption: string | null;
  thumbnailUrl: string | null;
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

    const metadata = await recoverPublicMetadata(job.sourceUrl).catch(() => null);
    const caption = metadata?.caption?.trim() ?? '';
    if (caption.length < MIN_USEFUL_CAPTION_CHARS) {
      throw new ImportError('SOURCE_NOT_ACCESSIBLE');
    }

    const localThumbnailPath = metadata?.thumbnailUrl
      ? await downloadPublicThumbnail(metadata.thumbnailUrl).catch(() => null)
      : null;
    return { kind: 'caption', caption, localThumbnailPath };
  }
}

async function recoverPublicMetadata(sourceUrl: string): Promise<PublicSocialMetadata | null> {
  const userAgents = sourceUrl.includes('instagram.com')
    ? [
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126 Mobile Safari/537.36',
      ]
    : [
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126 Mobile Safari/537.36',
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      ];

  let best: PublicSocialMetadata = { caption: null, thumbnailUrl: null };
  for (const userAgent of userAgents) {
    const fetched = await fetchPublicResource(
      sourceUrl,
      { Accept: 'text/html,application/xhtml+xml', 'User-Agent': userAgent },
      MAX_HTML_BYTES,
    ).catch(() => null);
    if (!fetched || !fetched.contentType.toLowerCase().includes('text/html')) continue;

    const metadata = extractPublicMetadata(fetched.body.toString('utf8'), fetched.finalUrl);
    best = {
      caption: chooseLonger(best.caption, metadata.caption),
      thumbnailUrl: best.thumbnailUrl ?? metadata.thumbnailUrl,
    };
    if (best.caption && best.thumbnailUrl) break;
  }
  return best.caption || best.thumbnailUrl ? best : null;
}

async function downloadPublicThumbnail(thumbnailUrl: string): Promise<string | null> {
  const fetched = await fetchPublicResource(
    thumbnailUrl,
    {
      Accept: 'image/avif,image/webp,image/apng,image/jpeg,image/png,image/*',
      'User-Agent': 'CookSense-LinkPreview/1.0',
    },
    MAX_THUMBNAIL_BYTES,
  );
  if (!fetched.contentType.toLowerCase().startsWith('image/')) return null;

  const extension = imageExtension(fetched.contentType);
  const localPath = path.join(os.tmpdir(), `cooksense-thumbnail-${randomUUID()}${extension}`);
  await fs.writeFile(localPath, fetched.body);
  return localPath;
}

async function fetchPublicResource(
  rawUrl: string,
  headers: Record<string, string>,
  maxBytes: number,
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
        if (redirects === FETCH_SAFETY.maxRedirects) {
          throw new ImportError('SOURCE_NOT_ACCESSIBLE', true, 'Too many source redirects');
        }
        const location = response.headers.get('location');
        if (!location) throw new ImportError('SOURCE_NOT_ACCESSIBLE');
        current = new URL(location, current);
        continue;
      }

      if (!response.ok || !response.body) {
        throw new ImportError(
          'SOURCE_NOT_ACCESSIBLE',
          response.status >= 500 || response.status === 429,
          `Source returned HTTP ${response.status}`,
        );
      }

      const declaredSize = Number.parseInt(response.headers.get('content-length') ?? '0', 10);
      if (declaredSize > maxBytes) throw new ImportError('FILE_TOO_LARGE');

      const chunks: Buffer[] = [];
      let received = 0;
      const reader = response.body.getReader();
      let nextChunk = await reader.read();
      while (!nextChunk.done) {
        const { value } = nextChunk;
        received += value.byteLength;
        if (received > maxBytes) {
          await reader.cancel().catch(() => undefined);
          throw new ImportError('FILE_TOO_LARGE');
        }
        chunks.push(Buffer.from(value));
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

  let thumbnailUrl: string | null = null;
  for (const candidate of thumbnailCandidates) {
    try {
      const parsed = baseUrl ? new URL(candidate, baseUrl) : new URL(candidate);
      if (parsed.protocol === 'https:') {
        thumbnailUrl = parsed.toString();
        break;
      }
    } catch {
      // Ignore malformed image URLs and continue to the next candidate.
    }
  }

  return { caption, thumbnailUrl };
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
  for (const key of ['thumbnailUrl', 'contentUrl']) {
    const candidate = object[key];
    if (typeof candidate === 'string') thumbnails.push(candidate);
    if (Array.isArray(candidate)) {
      for (const item of candidate) if (typeof item === 'string') thumbnails.push(item);
    }
  }
  const image = object.image;
  if (typeof image === 'string') thumbnails.push(image);
  if (image && typeof image === 'object') {
    const imageUrl = (image as Record<string, unknown>).url;
    if (typeof imageUrl === 'string') thumbnails.push(imageUrl);
  }

  for (const child of Object.values(object)) {
    if (child && typeof child === 'object') collectJsonLdMetadata(child, captions, thumbnails, depth + 1);
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

function imageExtension(contentType: string): string {
  const lower = contentType.toLowerCase();
  if (lower.includes('png')) return '.png';
  if (lower.includes('webp')) return '.webp';
  if (lower.includes('avif')) return '.avif';
  return '.jpg';
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
