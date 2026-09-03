import {
  extractCaption,
  extractPublicMetadata,
  extractThumbnailUrl,
} from '../src/providers/mediaSourceResolver';

describe('extractCaption', () => {
  it('extracts og:description with property-first attribute order', () => {
    const html = '<head><meta property="og:description" content="1kg chicken, marinate 30 min" /></head>';
    expect(extractCaption(html)).toBe('1kg chicken, marinate 30 min');
  });

  it('extracts og:description with content-first attribute order', () => {
    const html = '<meta content="2 cups flour and butter" property="og:description">';
    expect(extractCaption(html)).toBe('2 cups flour and butter');
  });

  it('unwraps the caption from Instagram og:title format, including newlines', () => {
    const html =
      '<meta property="og:title" content="Ralston D&#039;Souza on Instagram: &quot;Chicken Tikka\n\nIngredients\n85g Greek yoghurt\n1 tbsp ginger garlic paste&quot;" />';
    expect(extractCaption(html)).toBe(
      'Chicken Tikka\n\nIngredients\n85g Greek yoghurt\n1 tbsp ginger garlic paste',
    );
  });

  it('prefers the longest candidate when several tags exist', () => {
    const html =
      '<meta property="og:description" content="42 likes, 3 comments" />' +
      '<meta property="og:title" content="Chef on Instagram: &quot;Full recipe: 200g pasta, 2 cloves garlic, olive oil, chilli flakes&quot;" />';
    expect(extractCaption(html)).toBe(
      'Full recipe: 200g pasta, 2 cloves garlic, olive oil, chilli flakes',
    );
  });

  it('falls back to the plain description meta tag', () => {
    const html = '<meta name="description" content="Pasta with garlic and olive oil">';
    expect(extractCaption(html)).toBe('Pasta with garlic and olive oil');
  });

  it('decodes named, decimal, and hex HTML entities', () => {
    const html =
      '<meta property="og:description" content="Salt &amp; pepper &quot;to taste&quot; &#8212; it&#x2019;s done">';
    expect(extractCaption(html)).toBe('Salt & pepper "to taste" — it’s done');
  });

  it('returns null when no caption-bearing tag exists', () => {
    expect(extractCaption('<html><body>login required</body></html>')).toBeNull();
  });

  it('extracts a secure OpenGraph thumbnail with arbitrary attribute order', () => {
    const html = '<meta content="https://cdn.example.com/dish.jpg" data-x="1" property="og:image">';
    expect(extractThumbnailUrl(html)).toBe('https://cdn.example.com/dish.jpg');
  });

  it('falls back to JSON-LD recipe metadata and resolves relative images', () => {
    const html = `<script type="application/ld+json">${JSON.stringify({
      '@type': 'VideoObject',
      name: 'Crispy chilli potatoes',
      description: '500g potatoes, chilli and garlic. Fry and toss in sauce.',
      thumbnailUrl: '/images/potatoes.jpg',
    })}</script>`;
    expect(extractPublicMetadata(html, 'https://video.example.com/post/1')).toEqual({
      caption: '500g potatoes, chilli and garlic. Fry and toss in sauce.',
      thumbnailUrl: 'https://video.example.com/images/potatoes.jpg',
    });
  });
});
