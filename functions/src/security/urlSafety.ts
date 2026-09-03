import { createHash } from 'crypto';
import * as dns from 'dns';
import * as net from 'net';
import { promisify } from 'util';
import { ImportError } from '../domain/errors';
import { config } from '../config';

const dnsLookup = promisify(dns.lookup);

const TRACKING_PARAM_PREFIXES = ['utm_', 'igshid', 'igsh', 'fbclid', 'gclid', 'ref', 'ref_src'];

export type SourceType = 'social_url' | 'instagram_url' | 'uploaded_video' | 'caption_only';

const URL_IN_SHARED_TEXT = /https?:\/\/[^\s<>"']+/i;

/**
 * Social share payloads are rarely a bare URL (for example: "Watch this
 * reel https://... Shared from Instagram"). Extract the first URL before
 * applying the normal URL safety rules.
 */
export function extractFirstSharedUrl(input: string): string | null {
  const match = input.match(URL_IN_SHARED_TEXT);
  if (!match) return null;

  // Sentence punctuation and closing brackets are commonly attached to a
  // URL by share sheets. Keep URL-significant `/`, `=` and query values.
  return match[0].replace(/[\])},.;!?]+$/g, '');
}

/**
 * Normalizes a social/video URL received either directly or inside share
 * text. Known platforms get stable canonical forms; other public HTTPS URLs
 * are retained so new social platforms keep working without an app release.
 * Every actual network request is still protected by [assertPublicHost].
 */
export function canonicalizeSourceUrl(rawUrl: string): string {
  const extracted = extractFirstSharedUrl(rawUrl.trim()) ?? rawUrl.trim();
  let parsed: URL;
  try {
    parsed = new URL(extracted);
  } catch {
    throw new ImportError('SOURCE_URL_INVALID');
  }

  if (
    parsed.protocol !== 'https:' ||
    parsed.username.length > 0 ||
    parsed.password.length > 0 ||
    (parsed.port.length > 0 && parsed.port !== '443') ||
    parsed.hostname.length === 0 ||
    parsed.hostname.length > 253 ||
    parsed.toString().length > 4096
  ) {
    throw new ImportError('SOURCE_URL_INVALID');
  }

  const host = parsed.hostname.toLowerCase();
  if (isObviouslyLocalHost(host)) {
    throw new ImportError('SOURCE_URL_INVALID');
  }
  for (const knownDomain of ['instagram.com', 'youtube.com', 'tiktok.com', 'facebook.com']) {
    if (host.includes(knownDomain) && host !== knownDomain && !host.endsWith(`.${knownDomain}`)) {
      throw new ImportError('SOURCE_URL_INVALID');
    }
  }

  if (host === 'instagram.com' || host === 'www.instagram.com') {
    // Instagram Reel/post paths only: /reel/<id>/, /p/<id>/, /reels/<id>/
    const pathMatch = parsed.pathname.match(/^\/(reel|reels|p)\/([A-Za-z0-9_-]+)\/?$/);
    if (!pathMatch) throw new ImportError('SOURCE_URL_INVALID');

    const [, kind, id] = pathMatch;
    const canonicalKind = kind === 'reels' ? 'reel' : kind;
    return `https://www.instagram.com/${canonicalKind}/${id}/`;
  }

  if (host === 'youtu.be') {
    const id = parsed.pathname.split('/').filter(Boolean)[0];
    if (!id) throw new ImportError('SOURCE_URL_INVALID');
    return `https://www.youtube.com/watch?v=${encodeURIComponent(id)}`;
  }

  if (host === 'youtube.com' || host === 'www.youtube.com' || host === 'm.youtube.com') {
    const shortMatch = parsed.pathname.match(/^\/(shorts|live|embed)\/([A-Za-z0-9_-]+)/);
    const videoId = shortMatch?.[2] ?? parsed.searchParams.get('v');
    if (videoId) return `https://www.youtube.com/watch?v=${encodeURIComponent(videoId)}`;
  }

  parsed.hostname = host;
  parsed.hash = '';
  stripTrackingParamsInPlace(parsed);
  return parsed.toString();
}

export function hashCanonicalUrl(canonicalUrl: string): string {
  return createHash('sha256').update(canonicalUrl).digest('hex');
}

export function stripTrackingParams(rawUrl: string): string {
  const parsed = new URL(rawUrl);
  stripTrackingParamsInPlace(parsed);
  parsed.hash = '';
  return parsed.toString();
}

function stripTrackingParamsInPlace(parsed: URL): void {
  for (const key of [...parsed.searchParams.keys()]) {
    const lower = key.toLowerCase();
    if (TRACKING_PARAM_PREFIXES.some((prefix) => lower.startsWith(prefix))) {
      parsed.searchParams.delete(key);
    }
  }
}

function isObviouslyLocalHost(hostname: string): boolean {
  const lower = hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (
    lower === 'localhost' ||
    lower.endsWith('.localhost') ||
    lower === 'metadata.google.internal' ||
    lower.endsWith('.local')
  ) {
    return true;
  }
  if (net.isIPv4(lower)) return isPrivateIpv4(lower);
  if (net.isIPv6(lower)) return isPrivateIpv6(lower);
  return !lower.includes('.');
}

const PRIVATE_IPV4_RANGES: Array<[string, number]> = [
  ['0.0.0.0', 8],
  ['10.0.0.0', 8],
  ['100.64.0.0', 10],
  ['127.0.0.0', 8],
  ['169.254.0.0', 16], // link-local + cloud metadata (169.254.169.254)
  ['172.16.0.0', 12],
  ['192.0.0.0', 24],
  ['192.168.0.0', 16],
  ['198.18.0.0', 15],
  ['224.0.0.0', 4],
];

function ipToInt(ip: string): number {
  return ip.split('.').reduce((acc, octet) => (acc << 8) + Number(octet), 0) >>> 0;
}

function isPrivateIpv4(ip: string): boolean {
  const ipInt = ipToInt(ip);
  return PRIVATE_IPV4_RANGES.some(([base, prefix]) => {
    const baseInt = ipToInt(base);
    const mask = prefix === 0 ? 0 : (~0 << (32 - prefix)) >>> 0;
    return (ipInt & mask) === (baseInt & mask);
  });
}

function isPrivateIpv6(ip: string): boolean {
  const lower = ip.toLowerCase();
  const mappedIpv4 = lower.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/)?.[1];
  if (mappedIpv4) return isPrivateIpv4(mappedIpv4);
  return (
    lower === '::1' ||
    lower.startsWith('fe80:') || // link-local
    lower.startsWith('fc') ||
    lower.startsWith('fd') || // unique local
    lower === '::' ||
    lower.startsWith('::ffff:127.') // ipv4-mapped loopback
  );
}

/**
 * Resolves the host and rejects it if it (or any resolved A/AAAA record)
 * points at localhost/private/link-local/reserved/metadata ranges. Call
 * this immediately before every outbound fetch — including after following
 * a redirect — to close DNS-rebinding gaps.
 */
export async function assertPublicHost(hostname: string): Promise<void> {
  const lower = hostname.toLowerCase();
  if (isObviouslyLocalHost(lower)) {
    throw new ImportError('SOURCE_URL_INVALID', false, `Blocked disallowed host: ${hostname}`);
  }

  let addresses: dns.LookupAddress[];
  try {
    addresses = await dnsLookup(hostname, { all: true });
  } catch {
    throw new ImportError('SOURCE_NOT_ACCESSIBLE', true, `DNS resolution failed for ${hostname}`);
  }

  for (const { address, family } of addresses) {
    if (family === 4 && isPrivateIpv4(address)) {
      throw new ImportError('SOURCE_URL_INVALID', false, `Blocked private IPv4: ${address}`);
    }
    if (family === 6 && isPrivateIpv6(address)) {
      throw new ImportError('SOURCE_URL_INVALID', false, `Blocked private IPv6: ${address}`);
    }
  }
}

export const FETCH_SAFETY = {
  maxRedirects: 3,
  connectTimeoutMs: 5000,
  totalTimeoutMs: 20000,
  maxResponseBytes: config.media.maxUploadBytes,
} as const;
