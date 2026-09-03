import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Only use for messages owned by this app, never provider error text.
class RecipeImportException implements Exception {
  const RecipeImportException(this.message);

  final String message;
}

/// Firebase exception.toString() can include a complete native/Dart stack.
/// Map stable codes to actionable copy instead of rendering those diagnostics.
String recipeImportErrorMessage(Object error) {
  if (error is RecipeImportException) return error.message;
  if (error is FormatException) {
    return 'Paste a valid HTTPS link to a recipe video or post.';
  }
  if (error is SocketException) {
    return 'Check your internet connection and try again.';
  }
  if (error is FileSystemException) {
    return 'We could not read that video. Please choose or share it again.';
  }
  if (error is TimeoutException) {
    return 'The import service took too long to respond. Please try again shortly.';
  }
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    if (details is Map) {
      final message = _domainMessages[details['code']];
      if (message != null) return message;

      final fields = details['fieldErrors'];
      if (error.code == 'invalid-argument' && fields is Map) {
        if (fields.containsKey('sourceType')) {
          return 'The import service does not support this source yet. '
              'Please contact support to update the service.';
        }
        if (fields.containsKey('sourceUrl')) {
          return 'Paste a valid HTTPS link to a recipe video or post.';
        }
      }
    }
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unauthenticated' => 'Please sign in again to import recipes.',
      'permission-denied' ||
      'unauthorized' => 'You do not have permission to access this import.',
      'resource-exhausted' =>
        'Your import limit has been reached. Please try again later.',
      'unavailable' || 'network-request-failed' =>
        'The import service is unavailable. Check your connection and try again shortly.',
      'deadline-exceeded' || 'retry-limit-exceeded' =>
        'The import service took too long to respond. Please try again shortly.',
      'invalid-argument' =>
        'The import service could not accept this request. '
            'Please try again or contact support if it continues.',
      'not-found' || 'object-not-found' =>
        'This import or video is no longer available. Please import it again.',
      'cancelled' ||
      'canceled' => 'The import was cancelled. You can try again.',
      _ => 'We could not complete the import. Please try again shortly.',
    };
  }
  return 'We could not complete the import. Please try again shortly.';
}

const _domainMessages = {
  'SOURCE_URL_INVALID': 'Paste a valid HTTPS link to a recipe video or post.',
  'SOURCE_NOT_ACCESSIBLE':
      'This post is private or does not expose enough recipe detail. '
      'Share or choose the video file to continue.',
  'UPLOAD_REQUIRED': 'Please choose or share the video file to continue.',
  'FILE_TOO_LARGE': 'Choose a video smaller than 150 MB.',
  'VIDEO_TOO_LONG': 'This video exceeds the import duration limit.',
  'MEDIA_UNSUPPORTED': 'Choose an MP4, MOV, M4V or WebM video.',
  'NOT_A_RECIPE': 'This video does not appear to contain a recipe.',
  'RATE_LIMITED': 'Please wait a moment before importing again.',
  'QUOTA_EXCEEDED':
      'Your import limit has been reached. Please try again later.',
  'UNAUTHENTICATED': 'Please sign in again to import recipes.',
  'NOT_FOUND': 'This import is no longer available. Please import it again.',
  'IMPORT_CANCELLED': 'The import was cancelled. You can try again.',
};
