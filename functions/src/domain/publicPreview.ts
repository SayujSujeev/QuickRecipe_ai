/** Public previews (including those supplied by the app) are untrusted evidence,
 * not instructions and not proof that the underlying video was accessible. */
export interface ClientPublicPreview {
  caption: string;
  thumbnailUrls: string[];
}

export function isPreviewBoilerplate(text: string): boolean {
  const normalized = text.toLowerCase().replace(/\s+/g, ' ').trim();
  return [
    'instagram', 'tiktok', 'youtube', 'facebook', 'tiktok - make your day',
    'log in or sign up to view', 'login • instagram', 'page not found',
    'content unavailable', 'this page isn’t available', 'this page is not available',
  ].includes(normalized) || [
    /^welcome (?:back )?to instagram\b/,
    /^(?:log|sign)\s?in (?:to|or sign\s?up)\b/,
    /^create an account or log in\b/,
    /^join instagram\b/,
    /^instagram\s*[-|•]\s*(?:log|sign)\s?in\b/,
    /^see instagram photos and videos from\b/,
  ].some((pattern) => pattern.test(normalized));
}

export function usablePreviewCaption(caption: string | null | undefined): string | null {
  const trimmed = caption?.trim();
  return trimmed && trimmed.length >= 8 && !isPreviewBoilerplate(trimmed)
    ? trimmed.slice(0, 5000) : null;
}
