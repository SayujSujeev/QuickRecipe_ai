import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cooksense/core/services/public_social_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixtures =
      (jsonDecode(
                File(
                  'test/fixtures/public_social_previews.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  const url = 'https://www.instagram.com/reel/DTQOpCMAM4U/';
  final loginHtml = fixtures[0]['html'] as String;
  final recipeHtml = fixtures[1]['html'] as String;
  http.Response page(String html) =>
      http.Response(html, 200, headers: {'content-type': 'text/html'});

  for (final fixture in fixtures) {
    test(fixture['description'] as String, () {
      final preview = PublicSocialPreview.parse(
        fixture['html'] as String,
        Uri.parse(fixture['url'] as String),
      );
      expect(preview?.caption, fixture['caption']);
      if (fixture['thumbnailUrl'] != null) {
        expect(preview!.thumbnailUrls, contains(fixture['thumbnailUrl']));
      }
    });
  }

  test('retries a different public preview after a login page', () async {
    var calls = 0;
    final result = await PublicSocialPreview.fetch(
      url,
      client: MockClient((request) async {
        expect(request.followRedirects, isFalse);
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.headers.containsKey('cookie'), isFalse);
        return page(++calls == 1 ? loginHtml : recipeHtml);
      }),
    );
    expect(calls, 2);
    expect(result!.caption, fixtures[1]['caption']);
    expect(result.toMap()['thumbnailUrls'], [fixtures[1]['thumbnailUrl']]);
  });

  test('does not follow redirects to local or unrecognized hosts', () async {
    for (final destination in [
      'https://127.0.0.1/private',
      'https://instagram.com.evil.example/post',
    ]) {
      final requested = <String>[];
      final result = await PublicSocialPreview.fetch(
        url,
        client: MockClient((request) async {
          requested.add(request.url.toString());
          return http.Response('', 302, headers: {'location': destination});
        }),
      );
      expect(result, isNull);
      expect(requested, [url, url]);
    }
  });

  test('does not follow login or challenge redirects', () async {
    var calls = 0;
    final result = await PublicSocialPreview.fetch(
      url,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '',
          302,
          headers: {'location': '/accounts/login/'},
        );
      }),
    );
    expect(result, isNull);
    expect(calls, 2);
  });

  test(
    'bounds total waiting time and returns control to the normal import flow',
    () async {
      final stalled = Completer<http.Response>();
      final result = await PublicSocialPreview.fetch(
        url,
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => stalled.future),
      );
      expect(result, isNull);
      stalled.complete(http.Response('', 503));
    },
  );

  test(
    'uses only a bounded HTML prefix even when the declared page size is huge',
    () async {
      final result = await PublicSocialPreview.fetch(
        url,
        client: MockClient(
          (_) async => page('$recipeHtml<script>${'x' * 700000}</script>'),
        ),
      );
      expect(result!.caption, fixtures[1]['caption']);
    },
  );

  test(
    'skips arbitrary links and never requests credentials or alternate ports',
    () async {
      for (final source in [
        'https://example.com/post',
        'https://user:pass@www.instagram.com/reel/x/',
        'https://www.instagram.com:8443/reel/x/',
      ]) {
        expect(
          await PublicSocialPreview.fetch(
            source,
            client: MockClient((_) async {
              fail('Must not fetch $source');
            }),
          ),
          isNull,
        );
      }
    },
  );

  test('limits caption and image candidates and rejects unsafe image URLs', () {
    final images = [
      'http://cdn.example.com/dish.jpg',
      'https://a:b@cdn.example.com/dish.jpg',
      ...List.generate(8, (i) => 'https://cdn.example.com/$i.jpg'),
    ].map((url) => '<meta property="og:image" content="$url">').join();
    final html =
        '<meta name="description" content="${'Roast potatoes. ' * 400}">$images';
    final preview = PublicSocialPreview.parse(html, Uri.parse(url))!;
    expect(preview.caption.length, 5000);
    expect(preview.thumbnailUrls.length, 4);
    expect(preview.thumbnailUrls.first, 'https://cdn.example.com/0.jpg');
  });
}
