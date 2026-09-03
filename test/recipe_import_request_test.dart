import 'dart:convert';
import 'dart:io';

import 'package:cooksense/core/services/recipe_import_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures =
      jsonDecode(
            File(
              'test/fixtures/recipe_import_requests.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;

  group('URL import wire contract', () {
    for (final fixture in fixtures.cast<Map<String, dynamic>>()) {
      test(fixture['description'] as String, () {
        expect(
          buildUrlImportRequest(
            fixture['sharedText'] as String,
            idempotencyKey: 'request-test-key',
          ),
          {
            'sourceType': fixture['sourceType'],
            'sourceUrl': fixture['sourceUrl'],
            'targetLanguage': 'en',
            'measurementSystem': 'metric',
            'idempotencyKey': 'request-test-key',
          },
        );
      });
    }

    test('preserves language, units and idempotency key', () {
      final request = buildUrlImportRequest(
        'https://www.instagram.com/reel/ABC123/',
        idempotencyKey: 'same-request-key',
        targetLanguage: 'hi',
        measurementSystem: 'imperial',
      );
      expect(request['targetLanguage'], 'hi');
      expect(request['measurementSystem'], 'imperial');
      expect(request['idempotencyKey'], 'same-request-key');
    });

    test('never labels a lookalike domain as Instagram', () {
      final request = buildUrlImportRequest(
        'https://instagram.com.evil.example/reel/ABC123/',
        idempotencyKey: 'request-test-key',
      );
      expect(request['sourceType'], 'social_url');
      // The server remains responsible for DNS/SSRF checks on every fetch.
    });

    for (final input in [
      '',
      'recipe with no link',
      'instagram.com/reel/ABC123/',
      'http://www.instagram.com/reel/ABC123/',
      'file:///video.mp4',
      'https://',
      'https://user:pass@www.instagram.com/reel/ABC123/',
      'https://www.instagram.com:8443/reel/ABC123/',
      'https://www.instagram.com/profile/',
      'https://www.instagram.com/reel/',
    ]) {
      test('rejects invalid input: $input', () {
        expect(
          () =>
              buildUrlImportRequest(input, idempotencyKey: 'request-test-key'),
          throwsFormatException,
        );
      });
    }

    test('rejects a URL over the backend length limit', () {
      expect(
        () => buildUrlImportRequest(
          'https://example.com/${'a' * 4096}',
          idempotencyKey: 'request-test-key',
        ),
        throwsFormatException,
      );
    });
  });
}
