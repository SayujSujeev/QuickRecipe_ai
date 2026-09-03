import { readFileSync } from 'fs';
import { resolve } from 'path';
import { createImportInputSchema } from '../src/api/schemas';
import { canonicalizeSourceUrl } from '../src/security/urlSafety';

// The Flutter request-builder tests use these same fixtures. Keep the mobile
// payload and callable schema compatible across independently deployed versions.
const fixtures = JSON.parse(readFileSync(
  resolve(__dirname, '../../test/fixtures/recipe_import_requests.json'), 'utf8',
)) as Array<{
  description: string;
  sharedText: string;
  sourceType: string;
  sourceUrl: string;
}>;

describe('mobile createImport contract', () => {
  it.each(fixtures)('accepts $description', (fixture) => {
    const parsed = createImportInputSchema.parse({
      sourceType: fixture.sourceType,
      sourceUrl: fixture.sourceUrl,
      targetLanguage: 'en',
      measurementSystem: 'metric',
      idempotencyKey: 'request-test-key',
    });
    expect(canonicalizeSourceUrl(parsed.sourceUrl!))
      .toBe(canonicalizeSourceUrl(fixture.sharedText));
  });

  it('continues accepting both Instagram wire tags', () => {
    for (const sourceType of ['instagram_url', 'social_url']) {
      expect(createImportInputSchema.safeParse({
        sourceType,
        sourceUrl: 'https://www.instagram.com/reel/DaSvyD2zWLs/',
        idempotencyKey: 'request-test-key',
      }).success).toBe(true);
    }
  });
});
