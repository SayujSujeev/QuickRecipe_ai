import {
  canonicalizeSourceUrl,
  extractFirstSharedUrl,
  hashCanonicalUrl,
  stripTrackingParams,
} from '../src/security/urlSafety';
import { ImportError } from '../src/domain/errors';

describe('canonicalizeSourceUrl', () => {
  it('normalizes a reel URL to the canonical host/path', () => {
    expect(canonicalizeSourceUrl('https://www.instagram.com/reel/ABC123/')).toBe(
      'https://www.instagram.com/reel/ABC123/',
    );
  });

  it('normalizes instagram.com (no www) and /reels/ to canonical form', () => {
    expect(canonicalizeSourceUrl('https://instagram.com/reels/ABC123')).toBe(
      'https://www.instagram.com/reel/ABC123/',
    );
  });

  it('strips tracking query params and fragments', () => {
    expect(
      canonicalizeSourceUrl(
        'https://www.instagram.com/reel/ABC123/?igshid=xyz&utm_source=ig#comments',
      ),
    ).toBe('https://www.instagram.com/reel/ABC123/');
  });

  it('rejects non-https schemes', () => {
    expect(() => canonicalizeSourceUrl('http://www.instagram.com/reel/ABC123/')).toThrow(
      ImportError,
    );
  });

  it('accepts future public social hosts while stripping tracking', () => {
    expect(canonicalizeSourceUrl('https://video.example.com/post/ABC?utm_source=share&clip=1'))
      .toBe('https://video.example.com/post/ABC?clip=1');
  });

  it('rejects hosts that merely contain "instagram.com" as a substring', () => {
    expect(() =>
      canonicalizeSourceUrl('https://instagram.com.evil.example.com/reel/ABC123/'),
    ).toThrow(ImportError);
  });

  it('rejects unsupported paths (e.g. profile pages)', () => {
    expect(() => canonicalizeSourceUrl('https://www.instagram.com/someuser/')).toThrow(
      ImportError,
    );
  });

  it('rejects malformed URLs', () => {
    expect(() => canonicalizeSourceUrl('not a url')).toThrow(ImportError);
  });

  it('extracts a URL from native share-sheet prose', () => {
    expect(canonicalizeSourceUrl(
      'Try this pasta! https://www.instagram.com/reel/ABC123/?igsh=share Shared via Instagram',
    )).toBe('https://www.instagram.com/reel/ABC123/');
  });

  it('normalizes YouTube shorts and short links', () => {
    expect(canonicalizeSourceUrl('https://youtube.com/shorts/abc_123?si=x'))
      .toBe('https://www.youtube.com/watch?v=abc_123');
    expect(canonicalizeSourceUrl('https://youtu.be/abc_123?t=20'))
      .toBe('https://www.youtube.com/watch?v=abc_123');
  });

  it('rejects local and credential-bearing URLs', () => {
    expect(() => canonicalizeSourceUrl('https://localhost/reel/ABC')).toThrow(ImportError);
    expect(() => canonicalizeSourceUrl('https://user:pass@example.com/video')).toThrow(ImportError);
  });
});

describe('extractFirstSharedUrl', () => {
  it('trims punctuation attached by the sharing app', () => {
    expect(extractFirstSharedUrl('Cook this (https://example.com/video/1).'))
      .toBe('https://example.com/video/1');
  });
});

describe('hashCanonicalUrl', () => {
  it('is deterministic for the same input', () => {
    const url = 'https://www.instagram.com/reel/ABC123/';
    expect(hashCanonicalUrl(url)).toBe(hashCanonicalUrl(url));
  });

  it('differs for different canonical URLs', () => {
    expect(hashCanonicalUrl('https://www.instagram.com/reel/AAA/')).not.toBe(
      hashCanonicalUrl('https://www.instagram.com/reel/BBB/'),
    );
  });
});

describe('stripTrackingParams', () => {
  it('removes known tracking params but keeps others', () => {
    const result = stripTrackingParams(
      'https://www.instagram.com/reel/ABC123/?utm_campaign=x&keep=1',
    );
    expect(result).toContain('keep=1');
    expect(result).not.toContain('utm_campaign');
  });
});
