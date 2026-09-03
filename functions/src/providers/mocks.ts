import type {
  AnalysisInput,
  AnalysisResult,
  ExtractedAudio,
  ExtractedFrame,
  MediaPreprocessor,
  MediaProbeResult,
  MediaSourceResolver,
  RecipeAnalysisProvider,
  ResolvedSource,
  TranscriptionProvider,
  TranscriptionResult,
} from './types';
import type { RecipeImportJob } from '../domain/importJob';
import type { RecipeDraft } from '../domain/recipeSchema';

/** In-memory/fixture-backed provider mocks used by contract tests. No network calls. */

export class MockMediaSourceResolver implements MediaSourceResolver {
  constructor(private readonly result: ResolvedSource) {}
  async resolve(_job: RecipeImportJob): Promise<ResolvedSource> {
    return this.result;
  }
}

export class MockMediaPreprocessor implements MediaPreprocessor {
  constructor(
    private readonly probeResult: MediaProbeResult,
    private readonly audio: ExtractedAudio | null,
    private readonly frames: ExtractedFrame[],
  ) {}
  async probe(_localVideoPath: string): Promise<MediaProbeResult> {
    return this.probeResult;
  }
  async extractAudio(_localVideoPath: string): Promise<ExtractedAudio | null> {
    return this.audio;
  }
  async extractFrames(_localVideoPath: string): Promise<ExtractedFrame[]> {
    return this.frames;
  }
}

export class MockTranscriptionProvider implements TranscriptionProvider {
  constructor(private readonly result: TranscriptionResult) {}
  async transcribe(): Promise<TranscriptionResult> {
    return this.result;
  }
}

export class MockRecipeAnalysisProvider implements RecipeAnalysisProvider {
  constructor(private readonly draft: RecipeDraft) {}
  async analyze(_input: AnalysisInput): Promise<AnalysisResult> {
    return { draft: this.draft, model: 'mock-model', requestId: null, usage: null };
  }
}

export function fixtureCompleteDraft(overrides: Partial<RecipeDraft> = {}): RecipeDraft {
  return {
    schemaVersion: '1.0.0',
    status: 'complete',
    title: 'Garlic Butter Shrimp',
    description: 'Quick pan-seared shrimp in garlic butter.',
    originalLanguageCodes: ['en'],
    outputLanguageCode: 'en',
    cuisines: ['American'],
    courses: ['dinner'],
    dietaryTags: [],
    servings: { quantity: 2, label: null, confidence: 0.9, evidence: [] },
    times: { prepMinutes: 10, cookMinutes: 8, totalMinutes: 18, confidence: 0.85, evidence: [] },
    ingredients: [
      {
        id: 'ing_1',
        group: null,
        name: 'shrimp',
        quantity: 450,
        quantityText: null,
        unit: 'g',
        originalText: '1 lb shrimp',
        preparation: 'peeled and deveined',
        optional: false,
        confidence: 0.9,
        evidence: [],
      },
      {
        id: 'ing_2',
        group: null,
        name: 'butter',
        quantity: null,
        quantityText: 'a knob',
        unit: null,
        originalText: 'a knob of butter',
        preparation: null,
        optional: false,
        confidence: 0.6,
        evidence: [],
      },
    ],
    steps: [
      {
        order: 1,
        instruction: 'Melt butter in a pan over medium-high heat.',
        durationSeconds: null,
        temperature: null,
        ingredientIds: ['ing_2'],
        equipment: ['pan'],
        confidence: 0.8,
        evidence: [],
      },
      {
        order: 2,
        instruction: 'Add shrimp and cook until pink, about 3 minutes per side.',
        durationSeconds: 360,
        temperature: null,
        ingredientIds: ['ing_1'],
        equipment: ['pan'],
        confidence: 0.85,
        evidence: [],
      },
    ],
    equipment: ['pan'],
    allergenFlags: ['shellfish'],
    missingInformation: [],
    warnings: [],
    overallConfidence: 0.85,
    ...overrides,
  };
}
