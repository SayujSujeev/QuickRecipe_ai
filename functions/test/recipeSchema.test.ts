import {
  needsReview,
  recipeDraftJsonSchema,
  recipeDraftSchema,
  reconcileTotalMinutes,
  validateRecipeDraftDomain,
} from '../src/domain/recipeSchema';
import { fixtureCompleteDraft } from '../src/providers/mocks';

describe('recipeDraftSchema', () => {
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
