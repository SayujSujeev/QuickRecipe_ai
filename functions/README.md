# CookSense recipe-import backend

Firebase Cloud Functions (2nd gen, Node 20, TypeScript) that power the
"Import Recipe" feature: turning a shared cooking Reel or uploaded video into
an editable structured recipe using OpenAI `gpt-transcribe` (audio) and
`gpt-5.6-luna` (joint transcript/caption/frame analysis via the Responses API
with strict Structured Outputs).

## Architecture

- **Firestore** — `recipeImportJobs`, `recipeDrafts`, `recipeDraftCorrections`
  hold job state, the AI-generated draft, and user corrections. Security
  rules (`../firestore.rules`) let a user only read their own docs; all
  writes happen through the Admin SDK inside these functions.
- **Cloud Storage** — `recipeImports/{uid}/{jobId}/source` receives
  client-uploaded video (governed by `../storage.rules`); short-lived
  extracted audio/frames live under `recipeImportsTemp/{jobId}/...` and are
  deleted on every terminal job transition plus a scheduled sweep. One
  optimized dish thumbnail is retained under `recipeThumbnails/{uid}/...`.
- **Firestore worker trigger** — entering `queued` (or changing `requeuedAt`)
  dispatches the media/AI pipeline without a separate task queue.
- **Callable functions** (`onCall`) — `createImport`, `processImport`,
  `getImportStatus`, `updateDraft`, `approveImport`, `cancelImport`,
  `estimateRecipeMacros`. All require Firebase Auth; none accept or return
  provider secrets.

See `src/domain/importJobState.ts` for the full state machine and
`src/domain/recipeSchema.ts` for the versioned strict Structured Outputs
schema.

## Local development

```bash
npm install
cp .env.example .env   # fill in a real OPENAI_API_KEY for emulator testing
npm run build
firebase emulators:start --only functions,firestore,auth,storage
```

`npm test` runs the full unit/contract suite (Jest) against mocked
providers — it never calls OpenAI or spawns FFmpeg, so it's safe and free to
run repeatedly. `npm run lint` and `npm run build` should both be clean
before deploying.

## Deployment

```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

Requirements:

- The Firebase project must be on the **Blaze** (pay-as-you-go) plan —
  outbound network calls and 2nd-gen Functions are required.
- `OPENAI_API_KEY` is set via Secret Manager (`functions:secrets:set`), never
  via a committed `.env`.
- FFmpeg/ffprobe binaries are bundled via `@ffmpeg-installer/ffmpeg` and
  `@ffprobe-installer/ffprobe` (no separate install step on Cloud Run).
- `processImportOnQueued` requests 2 GiB memory / 540s timeout — video
  processing plus two OpenAI round-trips can be slow; adjust it in
  `src/worker/firestoreTrigger.ts` if jobs time out.

### Mobile/backend rollout compatibility

Deploy the functions and rules before distributing a mobile build that uses
new import capabilities. Building or installing an APK does **not** update the
Firebase backend. The mobile client keeps sending the legacy `instagram_url`
tag for Instagram links; the current backend accepts both that tag and
`social_url`. Other platforms, upload recovery, and retained thumbnails require
the updated functions and Storage rules.

`test/fixtures/recipe_import_requests.json` at the repository root is shared by
the Flutter request tests and the backend contract tests. It includes the
reported Instagram link and native share-sheet text.

### Link thumbnails and planning estimates (schema 1.1)

- Link imports try multiple OpenGraph/Twitter/JSON-LD images, video posters and
  `image_src` links, then the alternate public page representation if needed.
  Large social pages use a bounded 600 KB HTML prefix so valid head metadata
  is not discarded because of megabytes of unrelated scripts later in the page.
  Image responses are decoded and normalized to JPEG; video URLs, login HTML,
  tiny tracking pixels and private-network redirects are not accepted as photos.
  A thumbnail Storage upload is retried once. The stable retained URL is copied
  to the draft and cookbook; inaccessible source images are reported in the UI.
- The analysis prompt may estimate missing **servings and recipe-level times**
  from batch quantities and the described preparation/cooking method. These
  use `servings.isEstimated`, `times.estimatedFields` and `estimateReason`, are
  marked for review, and remain labeled after saving. Known source values are
  preserved. Ingredient quantities, safety instructions and step durations are
  not invented. No reasonable basis for estimation still means null.
- The strict output schema requires provenance fields for new AI responses;
  older stored drafts remain readable without them. This follows the
  [Structured Outputs guidance](https://developers.openai.com/api/docs/guides/structured-outputs).
- Deploy the worker, approval function and related functions before testing
  these changes. Existing drafts are not silently rewritten: import the source
  again to fetch fresh metadata and generate estimates with the new prompt.

## Configuration

All tunables in `src/config.ts`, overridable via environment/secret values
(see `.env.example`): model names, reasoning effort, max output tokens,
video duration/size/frame caps, temp-media retention, per-user quotas, and
the `needs_review` confidence threshold.

## Runbook / troubleshooting

| Symptom | Likely cause | Where to look |
|---|---|---|
| `createImport` immediately returns `invalid-argument` / `Invalid import request` | Client/backend schema mismatch; this happens before fetching the video. Check `details.fieldErrors`, especially `sourceType` | Deploy the current functions to the same project used by the app; do not show the exception's stack trace in the UI |
| Jobs stuck in `queued` | The Firestore trigger did not deploy or a stale job needs re-kicking | `firebase functions:log --only processImportOnQueued` |
| A social-URL import lands in `awaiting_user_upload` | The public page did not expose enough caption data; choose/share the video to continue | `src/providers/mediaSourceResolver.ts` |
| `ANALYSIS_TEMPORARILY_UNAVAILABLE` spikes | OpenAI rate limiting or an outage | Check `usage`/retry counts on the job doc; `openaiRecipeAnalysis.ts` classifies 429/5xx as retryable |
| Draft always `needs_review` | Confidence threshold too strict for your content mix, or the model is genuinely uncertain | Tune `IMPORT_CONFIDENCE_REVIEW_THRESHOLD`; inspect `overallConfidence` and `missingInformation` on stored drafts |
| Orphaned temp files in Storage | A worker crashed mid-job before cleanup ran | `cleanupOrphanedImports` (hourly) sweeps anything older than `IMPORT_TEMP_HARD_CLEANUP_SECONDS`; check its logs |
| User reports the app "leaked" their video | It didn't — nothing is retained beyond the job's temp lifetime; only the structured draft + source URL are kept per the retention policy below | Confirm via `recipeImportsTemp/{jobId}/` is empty post-completion |

## Privacy & retention

- The structured recipe draft, original source URL, and one optimized dish
  thumbnail are retained long-term. Raw video/audio/analysis frames are
  deleted after the job reaches a terminal state, with an hourly sweep as a
  backstop for anything left behind by a crash.
- `store: false` is set on every Responses API call; OpenAI does not retain
  these requests for model training beyond its standard abuse-monitoring
  window.
- Jobs, drafts, and corrections are scoped to `userId` and only readable by
  that user (Firestore rules); deleting a user's account should also purge
  these collections (not yet automated — see Known limitations).

## Known limitations / deferred work

- **No unofficial social-video scraper.** URL imports safely follow public
  redirects and read OpenGraph/Twitter/JSON-LD link-preview data. Protected
  video is never scraped. If that evidence is incomplete, the resumable job
  asks for the actual video, which the Android/iOS native share intake or file
  picker uploads into the full audio/frame pipeline.
- **Audio > 25MB splitting** is not implemented; unusually long/loud
  extractions that exceed the transcription API's size limit fail with
  `MEDIA_UNSUPPORTED` instead of being split and merged.
- **Evaluation harness** (the 50–100 video field-accuracy suite) is not
  built; no accuracy percentage should be claimed until it exists.
- **Account-deletion cascade** for import jobs/drafts/corrections is not
  automated yet.
