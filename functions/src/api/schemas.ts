import { z } from 'zod';

export const createImportInputSchema = z.object({
  sourceType: z.enum(['social_url', 'instagram_url', 'uploaded_video', 'caption_only']),
  // A native share sheet often supplies prose around the URL, so URL parsing
  // and validation intentionally happen in canonicalizeSourceUrl.
  sourceUrl: z.string().min(1).max(6000).nullable().optional(),
  caption: z.string().max(5000).nullable().optional(),
  targetLanguage: z.string().min(2).max(10).default('en'),
  measurementSystem: z.enum(['metric', 'imperial']).default('metric'),
  idempotencyKey: z.string().min(8).max(128),
});
export type CreateImportInput = z.infer<typeof createImportInputSchema>;

export const jobIdInputSchema = z.object({
  jobId: z.string().min(1),
});

export const processImportInputSchema = z.object({
  jobId: z.string().min(1),
});

export const correctionSchema = z.object({
  fieldPath: z.string().min(1),
  value: z.unknown(),
});

export const updateDraftInputSchema = z.object({
  jobId: z.string().min(1),
  corrections: z.array(correctionSchema).min(1).max(100),
});

export const approveImportInputSchema = z.object({
  jobId: z.string().min(1),
});

export const cancelImportInputSchema = z.object({
  jobId: z.string().min(1),
});
