import { OpenAiRecipeAnalysisProvider, RECIPE_ANALYSIS_INSTRUCTION } from '../src/providers/openaiRecipeAnalysis';
import { fixtureCompleteDraft } from '../src/providers/mocks';

const mockCreateResponse = jest.fn();
jest.mock('openai', () => ({
  __esModule: true,
  default: jest.fn().mockImplementation(() => ({ responses: { create: mockCreateResponse } })),
}));

it('requests labeled planning estimates using the strict schema and preserves returned provenance', async () => {
  const originalKey = process.env.OPENAI_API_KEY;
  process.env.OPENAI_API_KEY = 'test-only-not-a-real-key';
  try {
    const draft = fixtureCompleteDraft();
    draft.servings = { ...draft.servings!, isEstimated: true, estimateReason: 'Based on batch size.' };
    draft.times = { ...draft.times, estimatedFields: ['prepMinutes'], estimateReason: 'Estimated chopping time.' };
    mockCreateResponse.mockResolvedValue({ output_text: JSON.stringify(draft) });
    const result = await new OpenAiRecipeAnalysisProvider().analyze({
      caption: '500g chicken, sear then coat in a garlic sauce.',
      transcript: '', frames: [], targetLanguage: 'en', measurementSystem: 'metric',
    });
    expect(result.draft.servings?.isEstimated).toBe(true);
    expect(result.draft.times.estimatedFields).toEqual(['prepMinutes']);
    const request = mockCreateResponse.mock.calls[0]![0];
    expect(request.instructions).toBe(RECIPE_ANALYSIS_INSTRUCTION);
    expect(request.instructions).toContain('Video runtime is\nNOT cooking time');
    expect(request.instructions).toContain('Keep source-provided numbers unchanged');
    expect(request.text.format.strict).toBe(true);
    expect(request.text.format.schema.properties.times.required).toContain('estimatedFields');
    expect(request.text.format.schema.properties.servings.anyOf[0].required).toContain('isEstimated');
  } finally {
    if (originalKey === undefined) delete process.env.OPENAI_API_KEY;
    else process.env.OPENAI_API_KEY = originalKey;
  }
});
