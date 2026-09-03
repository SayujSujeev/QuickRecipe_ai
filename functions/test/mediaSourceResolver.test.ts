import { promises as fs } from 'fs';
import sharp from 'sharp';
import { DefaultMediaSourceResolver } from '../src/providers/mediaSourceResolver';
import type { RecipeImportJob } from '../src/domain/importJob';
import type { TemporaryMediaStore } from '../src/providers/types';
import { assertPublicHost } from '../src/security/urlSafety';

jest.mock('../src/security/urlSafety', () => ({
  ...jest.requireActual('../src/security/urlSafety'),
  assertPublicHost: jest.fn(),
}));

const sourceUrl = 'https://www.instagram.com/reel/ABC123/';
const job = { sourceType: 'instagram_url', sourceUrl, uploadStoragePath: null } as RecipeImportJob;
const store: TemporaryMediaStore = {
  uploadLocalFile: jest.fn(), persistThumbnail: jest.fn(), downloadToLocal: jest.fn(), deleteAll: jest.fn(),
};
const resolver = new DefaultMediaSourceResolver(store);
const localFiles: string[] = [];
let png: Buffer;

function html(images: string[]): Response {
  return new Response('<meta property="og:description" content="500g chicken, garlic, butter. Sear and coat in sauce.">' +
    images.map((url) => `<meta property="og:image" content="${url}">`).join(''),
  { headers: { 'content-type': 'text/html' } });
}

async function resolveImage(): Promise<string | null> {
  const result = await resolver.resolve(job);
  expect(result.kind).toBe('caption');
  if (result.kind !== 'caption') throw new Error('Expected caption');
  if (result.localThumbnailPath) localFiles.push(result.localThumbnailPath);
  return result.localThumbnailPath;
}

beforeAll(async () => {
  png = await sharp({ create: { width: 160, height: 120, channels: 3, background: '#b76c44' } }).png().toBuffer();
});
beforeEach(() => {
  jest.mocked(assertPublicHost).mockReset().mockResolvedValue(undefined);
});
afterEach(async () => {
  jest.restoreAllMocks();
  await Promise.all(localFiles.splice(0).map((file) => fs.rm(file, { force: true })));
});

it('tries the next image after an expired CDN URL and converts PNG to JPEG', async () => {
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(html(['https://cdn.example.com/expired.jpg', 'https://cdn.example.com/dish.png']))
    .mockResolvedValueOnce(new Response('Expired', { status: 403 }))
    .mockResolvedValueOnce(new Response(new Uint8Array(png), { headers: { 'content-type': 'image/png' } }));
  const localPath = await resolveImage();
  expect(localPath).not.toBeNull();
  expect((await sharp(localPath!).metadata()).format).toBe('jpeg');
  expect(globalThis.fetch).toHaveBeenCalledTimes(3);
});

it.each([true, false])('retains head metadata on oversized HTML (content-length header: %s)', async (declaresLength) => {
  const body = '<meta property="og:description" content="500g chicken, sear and coat in garlic sauce.">' +
    '<meta property="og:image" content="https://cdn.example.com/dish.jpg">' +
    '<script>' + 'x'.repeat(700_000) + '</script>';
  const headers: Record<string, string> = { 'content-type': 'text/html' };
  if (declaresLength) headers['content-length'] = String(body.length);
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(new Response(body, { headers }))
    .mockResolvedValueOnce(new Response(new Uint8Array(png)));
  expect(await resolveImage()).not.toBeNull();
});

it('does not relax the image size limit when allowing an HTML prefix', async () => {
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(html(['https://cdn.example.com/huge.jpg', 'https://cdn.example.com/dish.jpg']))
    .mockResolvedValueOnce(new Response(new Uint8Array(png), { headers: { 'content-length': String(13 * 1024 * 1024) } }))
    .mockResolvedValueOnce(new Response(new Uint8Array(png)));
  expect(await resolveImage()).not.toBeNull();
  expect(globalThis.fetch).toHaveBeenCalledTimes(3);
});

it('uses the alternate page representation if the first preview is unusable', async () => {
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(html(['https://cdn.example.com/broken.jpg']))
    .mockResolvedValueOnce(new Response('<html>login</html>', { headers: { 'content-type': 'image/jpeg' } }))
    .mockResolvedValueOnce(html(['https://cdn.example.com/working.jpg']))
    .mockResolvedValueOnce(new Response(new Uint8Array(png), { headers: { 'content-type': 'application/octet-stream' } }));
  expect(await resolveImage()).not.toBeNull();
  expect(globalThis.fetch).toHaveBeenCalledTimes(4);
});

it('revalidates thumbnail redirects and never fetches a private destination', async () => {
  jest.mocked(assertPublicHost).mockImplementation(async (host) => {
    if (host === '127.0.0.1') throw new Error('Blocked private host');
  });
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(html(['https://cdn.example.com/redirect.jpg', 'https://cdn.example.com/working.jpg']))
    .mockResolvedValueOnce(new Response(null, { status: 302, headers: { location: 'https://127.0.0.1/private' } }))
    .mockResolvedValueOnce(new Response(new Uint8Array(png)));
  expect(await resolveImage()).not.toBeNull();
  expect(assertPublicHost).toHaveBeenCalledWith('127.0.0.1');
  const requested = jest.mocked(fetch).mock.calls.map(([url]) => String(url));
  expect(requested).not.toContain('https://127.0.0.1/private');
});

it('rejects a tracking pixel and keeps the usable caption when no photo exists', async () => {
  const pixel = await sharp({ create: { width: 1, height: 1, channels: 3, background: 'white' } }).png().toBuffer();
  jest.spyOn(globalThis, 'fetch')
    .mockResolvedValueOnce(html(['https://cdn.example.com/pixel.png']))
    .mockResolvedValueOnce(new Response(new Uint8Array(pixel)))
    .mockResolvedValueOnce(html([]));
  expect(await resolveImage()).toBeNull();
});

it('bounds image attempts and does not retry the same expired candidate', async () => {
  const images = Array.from({ length: 10 }, (_, i) => `https://cdn.example.com/${i}.jpg`);
  jest.spyOn(globalThis, 'fetch').mockImplementation(async (url) =>
    String(url) === sourceUrl ? html(images) : new Response('Expired', { status: 403 }));
  expect(await resolveImage()).toBeNull();
  expect(globalThis.fetch).toHaveBeenCalledTimes(6); // two pages + four image attempts
});
