import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import OpenAI from 'openai';
import { z } from 'zod';
import { db } from '../firebase';
import { requireUid, toHttpsError } from './httpsCallableHelpers';
import { ImportError } from '../domain/errors';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

const inputSchema = z.object({
  recipeId: z.string().min(1),
  title: z.string(),
  ingredients: z.array(z.object({ name: z.string(), measure: z.string() })),
  instructions: z.string(),
});

let client: OpenAI | null = null;
function getClient(): OpenAI {
  if (!client) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new ImportError('INTERNAL', true, 'OPENAI_API_KEY is not configured');
    client = new OpenAI({ apiKey });
  }
  return client;
}

/**
 * Server-side replacement for the client's former direct-to-OpenAI
 * MacroEstimatorService call (that call embedded OPENAI_API_KEY in the
 * shipped app bundle via a Flutter asset — a real key-leak vulnerability).
 * Same behavior, but the key never leaves this trusted environment.
 */
export const estimateRecipeMacros = onCall(
  { region: 'us-central1', secrets: [openaiApiKey] },
  async (request) => {
  requireUid(request);
  const parsed = inputSchema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError('invalid-argument', 'Invalid recipe payload.');
  const { recipeId, title, ingredients, instructions } = parsed.data;

  try {
    const ingredientLines = ingredients.map((i) => `- ${i.measure} ${i.name}`.trim()).join('\n');

    const completion = await getClient().chat.completions.create({
      model: 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      temperature: 0.2,
      messages: [
        {
          role: 'system',
          content:
            "You are a nutrition estimation assistant. Given a recipe's title, ingredients, and " +
            'instructions, estimate its total nutrition (for the whole recipe, not per serving) and a ' +
            'reasonable serving count. Respond with ONLY a JSON object with integer fields: servings, ' +
            'kcal, proteinG, carbsG, fatsG. No explanations, no markdown.',
        },
        {
          role: 'user',
          content: `Recipe: ${title}\n\nIngredients:\n${ingredientLines}\n\nInstructions:\n${instructions}`,
        },
      ],
    });

    const content = completion.choices[0]?.message?.content ?? '{}';
    const macros = JSON.parse(content) as Record<string, number>;
    const nutrition = {
      servings: Math.round(macros.servings ?? 1),
      kcal: Math.round(macros.kcal ?? 0),
      proteinG: Math.round(macros.proteinG ?? 0),
      carbsG: Math.round(macros.carbsG ?? 0),
      fatsG: Math.round(macros.fatsG ?? 0),
    };

    await db.collection('recipes').doc(recipeId).set({ nutrition }, { merge: true });
    return { nutrition };
  } catch (error) {
    throw toHttpsError(error instanceof ImportError ? error : new ImportError('INTERNAL', true, String(error)));
  }
  },
);
