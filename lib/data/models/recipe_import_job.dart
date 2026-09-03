import 'recipe_draft.dart';

/// Mirrors the subset of the server's RecipeImportJob (functions/src/domain/importJob.ts)
/// the client needs for progress display and recovery decisions.
class RecipeImportJob {
  const RecipeImportJob({
    required this.jobId,
    required this.userId,
    required this.sourceType,
    required this.sourceUrl,
    required this.uploadStoragePath,
    required this.state,
    required this.progressPercent,
    required this.errorCode,
    required this.errorMessage,
    required this.draftId,
    required this.finalRecipeId,
    required this.thumbnailUrl,
  });

  final String jobId;
  final String userId;
  final String
  sourceType; // social_url | instagram_url | uploaded_video | caption_only
  final String? sourceUrl;
  final String? uploadStoragePath;
  final String state; // ImportJobState
  final int progressPercent;
  final String? errorCode;
  final String? errorMessage;
  final String? draftId;
  final String? finalRecipeId;
  final String? thumbnailUrl;

  bool get isRecoverable => state == 'awaiting_user_upload';
  bool get isTerminalFailure => state == 'failed_terminal';
  bool get isRetryable => state == 'failed_retryable';
  bool get isReadyForReview => state == 'needs_review' || state == 'completed';
  bool get isCancelled => state == 'cancelled';

  factory RecipeImportJob.fromMap(Map<String, dynamic> map) => RecipeImportJob(
    jobId: map['jobId'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    sourceType: map['sourceType'] as String? ?? 'uploaded_video',
    sourceUrl: map['sourceUrl'] as String?,
    uploadStoragePath: map['uploadStoragePath'] as String?,
    state: map['state'] as String? ?? 'queued',
    progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
    errorCode: map['errorCode'] as String?,
    errorMessage: map['errorMessage'] as String?,
    draftId: map['draftId'] as String?,
    finalRecipeId: map['finalRecipeId'] as String?,
    thumbnailUrl: map['thumbnailUrl'] as String?,
  );
}

/// The `recipeDrafts/{draftId}` document, as returned by getImportStatus.
class RecipeDraftDocument {
  const RecipeDraftDocument({
    required this.draftId,
    required this.draft,
    required this.thumbnailUrl,
  });

  final String draftId;
  final RecipeDraft draft;
  final String? thumbnailUrl;

  factory RecipeDraftDocument.fromMap(Map<String, dynamic> map) =>
      RecipeDraftDocument(
        draftId: map['draftId'] as String? ?? '',
        draft: RecipeDraft.fromMap(
          Map<String, dynamic>.from(map['draft'] as Map? ?? {}),
        ),
        thumbnailUrl: map['thumbnailUrl'] as String?,
      );
}
