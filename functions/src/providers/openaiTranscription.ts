import { createReadStream } from 'fs';
import OpenAI from 'openai';
import { ImportError } from '../domain/errors';
import { config } from '../config';
import type { TranscriptionProvider, TranscriptionResult } from './types';

let client: OpenAI | null = null;
function getClient(): OpenAI {
  if (!client) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new ImportError('TRANSCRIPTION_TEMPORARILY_UNAVAILABLE', true, 'OPENAI_API_KEY is not configured');
    }
    client = new OpenAI({ apiKey });
  }
  return client;
}

/** gpt-transcribe integration. Never called from the client — server-only. */
export class OpenAiTranscriptionProvider implements TranscriptionProvider {
  async transcribe(audioPath: string, options: { promptContext: string }): Promise<TranscriptionResult> {
    try {
      const response = await getClient().audio.transcriptions.create({
        model: config.openai.transcriptionModel,
        file: createReadStream(audioPath),
        prompt: options.promptContext,
        response_format: 'verbose_json',
      });

      const verbose = response as unknown as {
        text: string;
        language?: string;
        duration?: number;
      };

      return {
        text: verbose.text ?? '',
        languageCodes: verbose.language ? [verbose.language] : [],
        model: config.openai.transcriptionModel,
        requestId: null,
        durationSeconds: verbose.duration ?? 0,
        usage: null,
      };
    } catch (error) {
      throw classifyOpenAiError(error);
    }
  }
}

function classifyOpenAiError(error: unknown): ImportError {
  const status = (error as { status?: number })?.status;
  if (status === 429 || (status !== undefined && status >= 500)) {
    return new ImportError('TRANSCRIPTION_TEMPORARILY_UNAVAILABLE', true, String(error));
  }
  return new ImportError('TRANSCRIPTION_TEMPORARILY_UNAVAILABLE', false, String(error));
}
