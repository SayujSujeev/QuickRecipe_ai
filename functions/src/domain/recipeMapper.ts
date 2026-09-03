import type { RecipeDraft } from './recipeSchema';

/**
 * Maps an approved RecipeDraft into the shape of the existing `recipes`
 * Firestore collection (see the Flutter `MealRecipe` model / `RecipeRepository`),
 * so imported recipes show up in the same cookbook as TheMealDB imports.
 */
export function mapDraftToCanonicalRecipe(
  draft: RecipeDraft,
  sourceUrl: string | null,
  thumbnailUrl: string | null = null,
): Record<string, unknown> {
  const instructions = draft.steps
    .slice()
    .sort((a, b) => a.order - b.order)
    .map((s) => s.instruction)
    .join('\n');

  const ingredients = draft.ingredients.map((ingredient) => ({
    name: ingredient.name,
    measure: formatMeasure(ingredient),
  }));

  return {
    title: draft.title ?? 'Untitled Recipe',
    imageUrl: thumbnailUrl ?? '',
    instructions,
    ingredients,
    category: draft.courses[0] ?? null,
    area: draft.cuisines[0] ?? null,
    tags: [...draft.cuisines, ...draft.courses, ...draft.dietaryTags],
    source: sourceUrl,
    youtube: null,
    importedFromReel: true,
    importSchemaVersion: draft.schemaVersion,
  };
}

function formatMeasure(ingredient: RecipeDraft['ingredients'][number]): string {
  if (ingredient.quantity !== null) {
    return [ingredient.quantity, ingredient.unit].filter(Boolean).join(' ').trim();
  }
  return ingredient.quantityText ?? '';
}
