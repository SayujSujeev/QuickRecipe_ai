import { z } from 'zod';

/**
 * Versioned structured-recipe schema (spec section "Structured recipe
 * schema"). This is the single source of truth: the Zod schema both
 * validates provider output at runtime and generates the strict JSON Schema
 * sent to the Responses API via `text.format`.
 *
 * Structured Outputs strict mode requires every object property to be
 * required and every optional value to be modeled as nullable instead of
 * absent, with `additionalProperties: false` everywhere.
 */

const confidence = z.number().min(0).max(1);

export const evidenceSourceType = z.enum(['caption', 'transcript', 'frame', 'visual_inference']);

export const evidenceReferenceSchema = z
  .object({
    sourceType: evidenceSourceType,
    sourceRef: z.string(),
    quote: z.string().nullable(),
  })
  .strict();

export const ingredientSchema = z
  .object({
    id: z.string(),
    group: z.string().nullable(),
    name: z.string(),
    quantity: z.number().nonnegative().nullable(),
    quantityText: z.string().nullable(),
    unit: z.string().nullable(),
    originalText: z.string().nullable(),
    preparation: z.string().nullable(),
    optional: z.boolean(),
    confidence,
    evidence: z.array(evidenceReferenceSchema),
  })
  .strict();

export const temperatureSchema = z
  .object({
    value: z.number().nullable(),
    unit: z.enum(['celsius', 'fahrenheit', 'other']),
  })
  .strict();

export const stepSchema = z
  .object({
    order: z.number().int().positive(),
    instruction: z.string(),
    durationSeconds: z.number().int().nonnegative().nullable(),
    temperature: temperatureSchema.nullable(),
    ingredientIds: z.array(z.string()),
    equipment: z.array(z.string()),
    confidence,
    evidence: z.array(evidenceReferenceSchema),
  })
  .strict();

export const timeSchema = z
  .object({
    prepMinutes: z.number().int().nonnegative().nullable(),
    cookMinutes: z.number().int().nonnegative().nullable(),
    totalMinutes: z.number().int().nonnegative().nullable(),
    confidence,
    evidence: z.array(evidenceReferenceSchema),
  })
  .strict();

export const servingSchema = z
  .object({
    quantity: z.number().nonnegative().nullable(),
    label: z.string().nullable(),
    confidence,
    evidence: z.array(evidenceReferenceSchema),
  })
  .strict();

export const recipeDraftSchema = z
  .object({
    schemaVersion: z.string(),
    status: z.enum(['complete', 'needs_review', 'not_a_recipe']),
    title: z.string().nullable(),
    description: z.string().nullable(),
    originalLanguageCodes: z.array(z.string()),
    outputLanguageCode: z.string(),
    cuisines: z.array(z.string()),
    courses: z.array(z.string()),
    dietaryTags: z.array(z.string()),
    servings: servingSchema.nullable(),
    times: timeSchema,
    ingredients: z.array(ingredientSchema),
    steps: z.array(stepSchema),
    equipment: z.array(z.string()),
    allergenFlags: z.array(z.string()),
    missingInformation: z.array(z.string()),
    warnings: z.array(z.string()),
    overallConfidence: confidence,
  })
  .strict();

export type RecipeDraft = z.infer<typeof recipeDraftSchema>;
export type RecipeDraftIngredient = z.infer<typeof ingredientSchema>;
export type RecipeDraftStep = z.infer<typeof stepSchema>;
export type EvidenceReference = z.infer<typeof evidenceReferenceSchema>;

/**
 * Strict-mode JSON Schema for the Responses API `text.format`. Hand-written
 * (rather than derived via a zod-to-json-schema library) to keep exact
 * control over `additionalProperties: false` and required-field strictness
 * that OpenAI's strict Structured Outputs mode enforces.
 */
export function recipeDraftJsonSchema(): Record<string, unknown> {
  const evidenceRef = {
    type: 'object',
    additionalProperties: false,
    required: ['sourceType', 'sourceRef', 'quote'],
    properties: {
      sourceType: { type: 'string', enum: ['caption', 'transcript', 'frame', 'visual_inference'] },
      sourceRef: { type: 'string' },
      quote: { type: ['string', 'null'] },
    },
  };

  const ingredient = {
    type: 'object',
    additionalProperties: false,
    required: [
      'id', 'group', 'name', 'quantity', 'quantityText', 'unit',
      'originalText', 'preparation', 'optional', 'confidence', 'evidence',
    ],
    properties: {
      id: { type: 'string' },
      group: { type: ['string', 'null'] },
      name: { type: 'string' },
      quantity: { type: ['number', 'null'] },
      quantityText: { type: ['string', 'null'] },
      unit: { type: ['string', 'null'] },
      originalText: { type: ['string', 'null'] },
      preparation: { type: ['string', 'null'] },
      optional: { type: 'boolean' },
      confidence: { type: 'number' },
      evidence: { type: 'array', items: evidenceRef },
    },
  };

  const temperature = {
    type: 'object',
    additionalProperties: false,
    required: ['value', 'unit'],
    properties: {
      value: { type: ['number', 'null'] },
      unit: { type: 'string', enum: ['celsius', 'fahrenheit', 'other'] },
    },
  };

  const step = {
    type: 'object',
    additionalProperties: false,
    required: [
      'order', 'instruction', 'durationSeconds', 'temperature',
      'ingredientIds', 'equipment', 'confidence', 'evidence',
    ],
    properties: {
      order: { type: 'integer' },
      instruction: { type: 'string' },
      durationSeconds: { type: ['integer', 'null'] },
      temperature: { anyOf: [temperature, { type: 'null' }] },
      ingredientIds: { type: 'array', items: { type: 'string' } },
      equipment: { type: 'array', items: { type: 'string' } },
      confidence: { type: 'number' },
      evidence: { type: 'array', items: evidenceRef },
    },
  };

  const times = {
    type: 'object',
    additionalProperties: false,
    required: ['prepMinutes', 'cookMinutes', 'totalMinutes', 'confidence', 'evidence'],
    properties: {
      prepMinutes: { type: ['integer', 'null'] },
      cookMinutes: { type: ['integer', 'null'] },
      totalMinutes: { type: ['integer', 'null'] },
      confidence: { type: 'number' },
      evidence: { type: 'array', items: evidenceRef },
    },
  };

  const serving = {
    type: 'object',
    additionalProperties: false,
    required: ['quantity', 'label', 'confidence', 'evidence'],
    properties: {
      quantity: { type: ['number', 'null'] },
      label: { type: ['string', 'null'] },
      confidence: { type: 'number' },
      evidence: { type: 'array', items: evidenceRef },
    },
  };

  return {
    type: 'object',
    additionalProperties: false,
    required: [
      'schemaVersion', 'status', 'title', 'description', 'originalLanguageCodes',
      'outputLanguageCode', 'cuisines', 'courses', 'dietaryTags', 'servings',
      'times', 'ingredients', 'steps', 'equipment', 'allergenFlags',
      'missingInformation', 'warnings', 'overallConfidence',
    ],
    properties: {
      schemaVersion: { type: 'string' },
      status: { type: 'string', enum: ['complete', 'needs_review', 'not_a_recipe'] },
      title: { type: ['string', 'null'] },
      description: { type: ['string', 'null'] },
      originalLanguageCodes: { type: 'array', items: { type: 'string' } },
      outputLanguageCode: { type: 'string' },
      cuisines: { type: 'array', items: { type: 'string' } },
      courses: { type: 'array', items: { type: 'string' } },
      dietaryTags: { type: 'array', items: { type: 'string' } },
      servings: { anyOf: [serving, { type: 'null' }] },
      times,
      ingredients: { type: 'array', items: ingredient },
      steps: { type: 'array', items: step },
      equipment: { type: 'array', items: { type: 'string' } },
      allergenFlags: { type: 'array', items: { type: 'string' } },
      missingInformation: { type: 'array', items: { type: 'string' } },
      warnings: { type: 'array', items: { type: 'string' } },
      overallConfidence: { type: 'number' },
    },
  };
}

export interface DomainValidationIssue {
  path: string;
  message: string;
}

/**
 * Domain-level checks beyond shape validation: ID uniqueness, referential
 * integrity, sequential step order. Never "corrects" evidence — only
 * reports problems so the caller can request one corrective retry or fall
 * back to needs_review.
 */
export function validateRecipeDraftDomain(draft: RecipeDraft): DomainValidationIssue[] {
  const issues: DomainValidationIssue[] = [];

  const ids = draft.ingredients.map((i) => i.id);
  const uniqueIds = new Set(ids);
  if (uniqueIds.size !== ids.length) {
    issues.push({ path: 'ingredients', message: 'Ingredient ids must be unique.' });
  }

  const sortedOrders = [...draft.steps].map((s) => s.order).sort((a, b) => a - b);
  for (let i = 0; i < sortedOrders.length; i++) {
    if (sortedOrders[i] !== i + 1) {
      issues.push({ path: 'steps', message: 'Step order must be sequential starting at 1.' });
      break;
    }
  }

  for (const step of draft.steps) {
    for (const ingredientId of step.ingredientIds) {
      if (!uniqueIds.has(ingredientId)) {
        issues.push({
          path: `steps[order=${step.order}].ingredientIds`,
          message: `References unknown ingredient id "${ingredientId}".`,
        });
      }
    }
  }

  if (draft.times.totalMinutes !== null) {
    const { prepMinutes, cookMinutes, totalMinutes } = draft.times;
    if (prepMinutes !== null && cookMinutes !== null && prepMinutes + cookMinutes !== totalMinutes) {
      // Not corrected automatically — only recalculated when the model didn't
      // already supply a supported total. A mismatch here is left as-is
      // (evidence-derived) rather than silently overwritten.
    }
  }

  return issues;
}

/** Recalculates totalMinutes only when both parts are known and total was left null. */
export function reconcileTotalMinutes(draft: RecipeDraft): RecipeDraft {
  if (
    draft.times.totalMinutes === null &&
    draft.times.prepMinutes !== null &&
    draft.times.cookMinutes !== null
  ) {
    return {
      ...draft,
      times: { ...draft.times, totalMinutes: draft.times.prepMinutes + draft.times.cookMinutes },
    };
  }
  return draft;
}

export function needsReview(draft: RecipeDraft, confidenceThreshold: number): boolean {
  if (draft.status !== 'complete') return true;
  if (draft.overallConfidence < confidenceThreshold) return true;
  if (draft.steps.length === 0) return true;

  const ingredientsRequiringQuantity = draft.ingredients.filter((i) => i.quantityText === null);
  if (ingredientsRequiringQuantity.length > 0) {
    const unknownCount = ingredientsRequiringQuantity.filter((i) => i.quantity === null).length;
    if (unknownCount / ingredientsRequiringQuantity.length > 0.25) return true;
  }

  return false;
}
