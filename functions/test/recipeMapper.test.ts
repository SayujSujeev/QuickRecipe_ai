import { mapDraftToCanonicalRecipe } from '../src/domain/recipeMapper';
import { fixtureCompleteDraft } from '../src/providers/mocks';

describe('mapDraftToCanonicalRecipe', () => {
  it('persists serving/time values and estimate labels into the cookbook', () => {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, isEstimated: true, estimateReason: 'Batch size.' };
    draft.times = { ...draft.times, estimatedFields: ['prepMinutes'], estimateReason: 'Chopping.' };
    const mapped = mapDraftToCanonicalRecipe(draft, null, 'https://cdn.example.com/dish.jpg');
    expect(mapped.servings).toEqual(expect.objectContaining({ quantity: 2, isEstimated: true, estimateReason: 'Batch size.' }));
    expect(mapped.times).toEqual(expect.objectContaining({ totalMinutes: 18, estimatedFields: ['prepMinutes'] }));
    expect(mapped.imageUrl).toBe('https://cdn.example.com/dish.jpg');
  });
  it('joins steps in order into instructions text', () => {
    const mapped = mapDraftToCanonicalRecipe(fixtureCompleteDraft(), 'https://www.instagram.com/reel/ABC/');
    expect(mapped.instructions).toBe(
      'Melt butter in a pan over medium-high heat.\nAdd shrimp and cook until pink, about 3 minutes per side.',
    );
  });

  it('formats ingredient measure from quantity+unit when known', () => {
    const mapped = mapDraftToCanonicalRecipe(fixtureCompleteDraft(), null);
    const ingredients = mapped.ingredients as Array<{ name: string; measure: string }>;
    expect(ingredients[0]).toEqual({ name: 'shrimp', measure: '450 g' });
  });

  it('falls back to quantityText for vague amounts', () => {
    const mapped = mapDraftToCanonicalRecipe(fixtureCompleteDraft(), null);
    const ingredients = mapped.ingredients as Array<{ name: string; measure: string }>;
    expect(ingredients[1]).toEqual({ name: 'butter', measure: 'a knob' });
  });

  it('preserves the original source URL for attribution', () => {
    const mapped = mapDraftToCanonicalRecipe(fixtureCompleteDraft(), 'https://www.instagram.com/reel/ABC/');
    expect(mapped.source).toBe('https://www.instagram.com/reel/ABC/');
  });

  it('persists the extracted dish thumbnail', () => {
    const mapped = mapDraftToCanonicalRecipe(
      fixtureCompleteDraft(),
      null,
      'https://cdn.example.com/dish.jpg',
    );
    expect(mapped.imageUrl).toBe('https://cdn.example.com/dish.jpg');
  });

  it('never invents a title when null', () => {
    const mapped = mapDraftToCanonicalRecipe(fixtureCompleteDraft({ title: null }), null);
    expect(mapped.title).toBe('Untitled Recipe');
  });
});
