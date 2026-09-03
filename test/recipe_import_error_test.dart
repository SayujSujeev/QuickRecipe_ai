import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cooksense/core/services/recipe_import_error.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recipeImportErrorMessage', () {
    test('reported invalid-argument error never displays diagnostics', () {
      final message = recipeImportErrorMessage(
        FirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'Invalid import request.\n#0 internal.dart:12',
          stackTrace: StackTrace.fromString('#0 private/path.dart:31'),
          details: {'diagnostic': 'provider secret response'},
        ),
      );
      expect(message, contains('could not accept this request'));
      expect(message, isNot(contains('firebase_functions')));
      expect(message, isNot(contains('#0')));
      expect(message, isNot(contains('internal.dart')));
      expect(message, isNot(contains('secret')));
    });

    test('identifies unsupported source types on an older backend', () {
      final message = recipeImportErrorMessage(
        FirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'Invalid import request.',
          details: {
            'fieldErrors': {
              'sourceType': ['Invalid enum value'],
            },
          },
        ),
      );
      expect(message, contains('update the service'));
      expect(message, isNot(contains('enum')));
    });

    test('invalid URLs offer a correction instead of a backend update', () {
      final message = recipeImportErrorMessage(
        FirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'Invalid import request.',
          details: {
            'fieldErrors': {
              'sourceUrl': ['Invalid url'],
            },
          },
        ),
      );
      expect(message, contains('valid HTTPS link'));
    });

    test('stable domain codes take precedence over Firebase status', () {
      expect(
        recipeImportErrorMessage(
          FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'Private provider diagnostics',
            details: {'code': 'SOURCE_NOT_ACCESSIBLE'},
          ),
        ),
        contains('video file to continue'),
      );
    });

    test('handles malformed or future error details safely', () {
      for (final details in [
        null,
        'unknown',
        [],
        {'fieldErrors': 'invalid'},
      ]) {
        expect(
          recipeImportErrorMessage(
            FirebaseFunctionsException(
              code: 'internal',
              message: '',
              details: details,
            ),
          ),
          'We could not complete the import. Please try again shortly.',
        );
      }
    });

    test('gives actionable network, authentication and quota messages', () {
      for (final entry in {
        'unauthenticated': 'sign in again',
        'resource-exhausted': 'import limit',
        'unavailable': 'Check your connection',
        'deadline-exceeded': 'too long',
        'permission-denied': 'permission',
      }.entries) {
        expect(
          recipeImportErrorMessage(
            FirebaseFunctionsException(code: entry.key, message: ''),
          ),
          contains(entry.value),
        );
      }
    });

    test('upload errors never expose storage paths', () {
      expect(
        recipeImportErrorMessage(
          FirebaseException(
            plugin: 'firebase_storage',
            code: 'unauthorized',
            message: 'recipeImports/private-user/private-job/source',
          ),
        ),
        'You do not have permission to access this import.',
      );
    });

    test('local validation and file/network failures are readable', () {
      expect(
        recipeImportErrorMessage(
          const RecipeImportException('Video is empty.'),
        ),
        'Video is empty.',
      );
      expect(
        recipeImportErrorMessage(const FormatException('private input')),
        contains('valid HTTPS link'),
      );
      expect(
        recipeImportErrorMessage(
          const FileSystemException('failure', '/private'),
        ),
        contains('choose or share it again'),
      );
      expect(
        recipeImportErrorMessage(const SocketException('private host')),
        contains('internet connection'),
      );
      expect(
        recipeImportErrorMessage(TimeoutException('private request')),
        contains('too long'),
      );
      expect(
        recipeImportErrorMessage(StateError('private implementation details')),
        'We could not complete the import. Please try again shortly.',
      );
    });
  });
}
