import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/recipe_import_job.dart';
import 'recipe_import_error.dart';
import 'recipe_import_request.dart';
import 'public_social_preview.dart';

/// Client for the recipe-reel import pipeline. The phone can contribute an
/// unauthenticated public link preview when the platform blocks cloud fetches.
/// Image validation and all AI processing remain server-side; provider secrets
/// never touch the client.
class RecipeImportService {
  RecipeImportService._();
  static final RecipeImportService instance = RecipeImportService._();

  final _functions = FirebaseFunctions.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Starts an import from a pasted/shared URL. Returns the created (or,
  /// on a duplicate/idempotent replay, the existing) job.
  Future<RecipeImportJob> createFromUrl(
    String sourceUrl, {
    String targetLanguage = 'en',
    String measurementSystem = 'metric',
  }) async {
    final request = buildUrlImportRequest(
      sourceUrl,
      idempotencyKey: _uuid.v4(),
      targetLanguage: targetLanguage,
      measurementSystem: measurementSystem,
    );
    final preview = await PublicSocialPreview.fetch(
      request['sourceUrl'] as String,
    );
    if (preview != null) request['clientPreview'] = preview.toMap();
    final result = await _functions
        .httpsCallable('createImport')
        .call<Map<String, dynamic>>(request);
    return RecipeImportJob.fromMap(
      Map<String, dynamic>.from(result.data['job'] as Map),
    );
  }

  /// Imports a video received from the native share sheet. The file is
  /// uploaded directly to private temporary Storage and then processed by the
  /// same server pipeline as every other import.
  Future<RecipeImportJob> createFromVideo(
    String localPath, {
    String? caption,
    String targetLanguage = 'en',
    String measurementSystem = 'metric',
  }) async {
    final result = await _functions
        .httpsCallable('createImport')
        .call<Map<String, dynamic>>({
          'sourceType': 'uploaded_video',
          'caption': caption,
          'targetLanguage': targetLanguage,
          'measurementSystem': measurementSystem,
          'idempotencyKey': _uuid.v4(),
        });
    final job = RecipeImportJob.fromMap(
      Map<String, dynamic>.from(result.data['job'] as Map),
    );
    await continueWithVideo(job, localPath);
    await _removeNativeShareCopy(localPath);
    return job;
  }

  /// Supplies a video when public metadata was private/incomplete.
  Future<void> continueWithVideo(RecipeImportJob job, String localPath) async {
    final file = File(localPath);
    final size = await file.length();
    if (size <= 0) {
      throw const RecipeImportException('The selected video is empty.');
    }
    if (size > 150 * 1024 * 1024) {
      throw const RecipeImportException('Choose a video smaller than 150 MB.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != job.userId) {
      throw const RecipeImportException(
        'Please sign in again before uploading the video.',
      );
    }
    final storagePath = 'recipeImports/$uid/${job.jobId}/source';
    await _storage
        .ref(storagePath)
        .putFile(
          file,
          SettableMetadata(contentType: _videoContentType(localPath)),
        );
    await _functions.httpsCallable('processImport').call<Map<String, dynamic>>({
      'jobId': job.jobId,
    });
  }

  /// Retries a job left in `failed_retryable`.
  Future<void> retry(String jobId) async {
    await _functions.httpsCallable('processImport').call<Map<String, dynamic>>({
      'jobId': jobId,
    });
  }

  Future<void> cancel(String jobId) async {
    await _functions.httpsCallable('cancelImport').call<Map<String, dynamic>>({
      'jobId': jobId,
    });
  }

  Future<Map<String, dynamic>> updateDraft(
    String jobId,
    List<MapEntry<String, dynamic>> corrections,
  ) async {
    final result = await _functions
        .httpsCallable('updateDraft')
        .call<Map<String, dynamic>>({
          'jobId': jobId,
          'corrections': corrections
              .map((c) => {'fieldPath': c.key, 'value': c.value})
              .toList(),
        });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<String> approve(String jobId) async {
    final result = await _functions
        .httpsCallable('approveImport')
        .call<Map<String, dynamic>>({'jobId': jobId});
    return result.data['recipeId'] as String;
  }

  /// Live job status, restorable at any time by job ID (e.g. after an app
  /// restart) since it just re-subscribes to the Firestore doc.
  Stream<RecipeImportJob?> watchJob(String jobId) {
    return _db
        .collection('recipeImportJobs')
        .doc(jobId)
        .snapshots()
        .map(
          (snap) => snap.exists ? RecipeImportJob.fromMap(snap.data()!) : null,
        );
  }

  Stream<RecipeDraftDocument?> watchDraft(String draftId) {
    return _db
        .collection('recipeDrafts')
        .doc(draftId)
        .snapshots()
        .map(
          (snap) =>
              snap.exists ? RecipeDraftDocument.fromMap(snap.data()!) : null,
        );
  }
}

String _videoContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.m4v')) return 'video/x-m4v';
  return 'video/mp4';
}

Future<void> _removeNativeShareCopy(String path) async {
  final normalized = path.replaceAll('\\', '/').toLowerCase();
  if (!normalized.contains('/shared-recipe-videos/') &&
      !normalized.contains('/sharedrecipevideos/')) {
    return;
  }
  try {
    await File(path).delete();
  } on FileSystemException {
    // The OS may already have reclaimed its temporary share copy.
  }
}
