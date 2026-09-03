import {
  needsReview,
  recipeDraftJsonSchema,
  recipeDraftSchema,
  reconcileTotalMinutes,
  validateRecipeDraftDomain,
} from '../src/domain/recipeSchema';
import { fixtureCompleteDraft } from '../src/providers/mocks';

describe('recipeDraftSchema', () => {
  it('accepts labeled planning estimates and remains compatible with legacy drafts', () => {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, isEstimated: true, estimateReason: 'Based on batch size.' };
    draft.times = { ...draft.times, estimatedFields: ['prepMinutes'], estimateReason: 'Chopping and mixing.' };
    expect(recipeDraftSchema.safeParse(draft).success).toBe(true);
    expect(validateRecipeDraftDomain(draft)).toEqual([]);
    expect(recipeDraftSchema.safeParse(fixtureCompleteDraft()).success).toBe(true);
  });
  it('accepts a well-formed complete draft', () => {
    const result = recipeDraftSchema.safeParse(fixtureCompleteDraft());
    expect(result.success).toBe(true);
  });

  it('rejects additional properties (strict mode)', () => {
    const draft = { ...fixtureCompleteDraft(), extraField: 'nope' };
    const result = recipeDraftSchema.safeParse(draft);
    expect(result.success).toBe(false);
  });

  it('rejects out-of-range confidence values', () => {
    const draft = fixtureCompleteDraft({ overallConfidence: 1.5 });
    expect(recipeDraftSchema.safeParse(draft).success).toBe(false);
  });

  it('allows null quantity alongside quantityText for vague amounts', () => {
    const draft = fixtureCompleteDraft();
    const parsed = recipeDraftSchema.parse(draft);
    expect(parsed.ingredients[1]!.quantity).toBeNull();
    expect(parsed.ingredients[1]!.quantityText).toBe('a knob');
  });
});

describe('recipeDraftJsonSchema', () => {
  it('requires estimate metadata in new structured output, including nested objects', () => {
    function check(value: unknown): void {
      if (!value || typeof value !== 'object') return;
      const object = value as Record<string, unknown>;
      if (object.type === 'object') {
        expect(new Set(object.required as string[])).toEqual(new Set(Object.keys(object.properties as object)));
      }
      Object.values(object).forEach(check);
    }
    check(recipeDraftJsonSchema());
  });
  it('sets additionalProperties: false on every nested object', () => {
    const schema = recipeDraftJsonSchema();
    const asString = JSON.stringify(schema);
    const objectCount = (asString.match(/"type":"object"/g) || []).length;
    const additionalPropsFalseCount = (asString.match(/"additionalProperties":false/g) || []).length;
    expect(additionalPropsFalseCount).toBeGreaterThan(0);
    expect(additionalPropsFalseCount).toBe(objectCount);
  });

  it('marks every property required at the root', () => {
    const schema = recipeDraftJsonSchema() as { required: string[]; properties: Record<string, unknown> };
    expect(new Set(schema.required)).toEqual(new Set(Object.keys(schema.properties)));
  });
});

describe('validateRecipeDraftDomain', () => {
  it('rejects unsubstantiated estimate metadata for a corrective retry', () => {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, quantity: null, isEstimated: true };
    draft.times = { ...draft.times, prepMinutes: null, estimatedFields: ['prepMinutes'] };
    expect(validateRecipeDraftDomain(draft).map((i) => i.path)).toEqual([
      'servings', 'times.estimateReason', 'times.prepMinutes',
    ]);
  });
  it('finds no issues on a valid draft', () => {
    expect(validateRecipeDraftDomain(fixtureCompleteDraft())).toEqual([]);
  });

  it('flags duplicate ingredient ids', () => {
    const draft = fixtureCompleteDraft();
    draft.ingredients[1] = { ...draft.ingredients[1]!, id: draft.ingredients[0]!.id };
    const issues = validateRecipeDraftDomain(draft);
    expect(issues.some((i) => i.message.includes('unique'))).toBe(true);
  });

  it('flags non-sequential step order', () => {
    const draft = fixtureCompleteDraft();
    draft.steps[1] = { ...draft.steps[1]!, order: 5 };
    const issues = validateRecipeDraftDomain(draft);
    expect(issues.some((i) => i.message.includes('sequential'))).toBe(true);
  });

  it('flags a step referencing an unknown ingredient id', () => {
    const draft = fixtureCompleteDraft();
    draft.steps[0] = { ...draft.steps[0]!, ingredientIds: ['does_not_exist'] };
    const issues = validateRecipeDraftDomain(draft);
    expect(issues.some((i) => i.message.includes('unknown ingredient'))).toBe(true);
  });
});

describe('reconcileTotalMinutes', () => {
  it('marks a derived total estimated if either of its parts was estimated', () => {
    const draft = fixtureCompleteDraft({ times: {
      prepMinutes: 10, cookMinutes: 20, totalMinutes: null, confidence: 0.6, evidence: [],
      estimatedFields: ['prepMinutes'], estimateReason: 'Typical chopping time.',
    } });
    const reconciled = reconcileTotalMinutes(draft);
    expect(reconciled.times.totalMinutes).toBe(30);
    expect(reconciled.times.cookMinutes).toBe(20);
    expect(reconciled.times.estimatedFields).toEqual(['prepMinutes', 'totalMinutes']);
  });
  it('fills totalMinutes only when null and both parts are known', () => {
    const draft = fixtureCompleteDraft({
      times: { prepMinutes: 5, cookMinutes: 10, totalMinutes: null, confidence: 0.9, evidence: [] },
    });
    expect(reconcileTotalMinutes(draft).times.totalMinutes).toBe(15);
  });

  it('never overwrites an existing totalMinutes value', () => {
    const draft = fixtureCompleteDraft({
      times: { prepMinutes: 5, cookMinutes: 10, totalMinutes: 999, confidence: 0.9, evidence: [] },
    });
    expect(reconcileTotalMinutes(draft).times.totalMinutes).toBe(999);
  });

  it('leaves totalMinutes null when a part is unknown', () => {
    const draft = fixtureCompleteDraft({
      times: { prepMinutes: null, cookMinutes: 10, totalMinutes: null, confidence: 0.9, evidence: [] },
    });
    expect(reconcileTotalMinutes(draft).times.totalMinutes).toBeNull();
  });
});

describe('needsReview', () => {
  it('requires review for estimates even when overall confidence is high', () => {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, isEstimated: true, estimateReason: 'Batch size.' };
    expect(needsReview(draft, 0.8)).toBe(true);
    draft.servings = null;
    draft.times.estimatedFields = ['prepMinutes'];
    expect(needsReview(draft, 0.8)).toBe(true);
  });
  it('is false for a high-confidence complete draft with known quantities', () => {
    expect(needsReview(fixtureCompleteDraft(), 0.8)).toBe(false);
  });

  it('is true when status is not_a_recipe or needs_review', () => {
    expect(needsReview(fixtureCompleteDraft({ status: 'not_a_recipe' }), 0.8)).toBe(true);
    expect(needsReview(fixtureCompleteDraft({ status: 'needs_review' }), 0.8)).toBe(true);
  });

  it('is true when overall confidence is below threshold', () => {
    expect(needsReview(fixtureCompleteDraft({ overallConfidence: 0.5 }), 0.8)).toBe(true);
  });

  it('is true when there are no steps', () => {
    expect(needsReview(fixtureCompleteDraft({ steps: [] }), 0.8)).toBe(true);
  });

  it('is true when >25% of quantity-required ingredients have unknown quantity', () => {
    const draft = fixtureCompleteDraft();
    draft.ingredients = [
      { ...draft.ingredients[0]!, quantity: null, quantityText: null },
      { ...draft.ingredients[0]!, id: 'ing_3', quantity: 1, quantityText: null },
      { ...draft.ingredients[0]!, id: 'ing_4', quantity: 1, quantityText: null },
    ];
    expect(needsReview(draft, 0.8)).toBe(true);
  });
});
