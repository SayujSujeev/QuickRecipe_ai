import 'dart:convert';

import 'package:http/http.dart' as http;

/// Best-effort, unauthenticated link previews. No Instagram session, cookies,
/// video downloads or AI credentials are used. Failure leaves the server's
/// normal resolution/upload recovery path available.
class PublicSocialPreview {
  const PublicSocialPreview({
    required this.caption,
    required this.thumbnailUrls,
  });

  final String caption;
  final List<String> thumbnailUrls;

  Map<String, dynamic> toMap() => {
    'caption': caption,
    'thumbnailUrls': thumbnailUrls,
  };

  /// Owns and closes [client], including when the total deadline expires.
  static Future<PublicSocialPreview?> fetch(
    String sourceUrl, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !_allowedPage(uri)) return null;
    final connection = client ?? http.Client();
    try {
      return await _fetch(connection, uri).timeout(timeout);
    } catch (_) {
      return null;
    } finally {
      connection.close();
    }
  }

  static Future<PublicSocialPreview?> _fetch(
    http.Client connection,
    Uri source,
  ) async {
    for (final userAgent in [
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126 Mobile Safari/537.36',
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
    ]) {
      var current = source;
      for (var redirects = 0; redirects <= 3; redirects++) {
        if (!_allowedPage(current) || _isLoginPath(current)) break;
        final request = http.Request('GET', current)
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'text/html,application/xhtml+xml',
            'User-Agent': userAgent,
          });
        final response = await connection.send(request);
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          await response.stream.listen((_) {}).cancel();
          final location = response.headers['location'];
          if (location == null) break;
          current = current.resolve(location);
          continue;
        }
        if (response.statusCode != 200 ||
            !(response.headers['content-type'] ?? '').contains('text/html')) {
          await response.stream.listen((_) {}).cancel();
          break;
        }
        final bytes = <int>[];
        // Metadata is in the head; do not download megabytes of page scripts.
        await for (final chunk in response.stream) {
          final remaining = 600000 - bytes.length;
          bytes.addAll(chunk.take(remaining));
          if (bytes.length == 600000) break;
        }
        final preview = parse(
          utf8.decode(bytes, allowMalformed: true),
          current,
        );
        if (preview != null) return preview;
        break;
      }
    }
    return null;
  }

  static PublicSocialPreview? parse(String html, Uri page) {
    if (_isLoginPath(page)) return null;
    final captions = <String>[];
    final images = <String>[];
    final attributes = RegExp(
      r'''([:\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
    );
    for (final tag in RegExp(
      r'<meta\b[^>]*>',
      caseSensitive: false,
    ).allMatches(html)) {
      final attrs = <String, String>{};
      for (final attr in attributes.allMatches(tag.group(0)!)) {
        attrs[attr.group(1)!.toLowerCase()] =
            attr.group(2) ?? attr.group(3) ?? attr.group(4) ?? '';
      }
      final key = (attrs['property'] ?? attrs['name'] ?? '').toLowerCase();
      final value = _decodeEntities(attrs['content'] ?? '').trim();
      if (value.isEmpty) continue;
      if ([
        'og:description',
        'twitter:description',
        'description',
        'og:title',
        'twitter:title',
      ].contains(key)) {
        final quoted = RegExp(
          r'''on Instagram:\s*["“]([\s\S]*)["”]\s*$''',
          caseSensitive: false,
        ).firstMatch(value);
        final caption = (quoted?.group(1) ?? value).trim();
        if (caption.length >= 8 && !_isBoilerplate(caption)) {
          captions.add(caption);
        }
      }
      if ([
        'og:image',
        'og:image:secure_url',
        'twitter:image',
        'twitter:image:src',
      ].contains(key)) {
        final parsed = Uri.tryParse(value);
        if (parsed == null) continue;
        final uri = page.resolveUri(parsed);
        if (uri.scheme == 'https' &&
            uri.userInfo.isEmpty &&
            uri.port == 443 &&
            uri.toString().length <= 4096 &&
            !images.contains(uri.toString())) {
          images.add(uri.toString());
        }
      }
    }
    if (captions.isEmpty) return null; // Never send login text or a site logo.
    captions.sort((a, b) => b.length.compareTo(a.length));
    final caption = captions.first;
    return PublicSocialPreview(
      caption: caption.length > 5000 ? caption.substring(0, 5000) : caption,
      thumbnailUrls: images.take(4).toList(),
    );
  }
}

bool _allowedPage(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    uri.port == 443 &&
    const {
      'instagram.com',
      'www.instagram.com',
      'tiktok.com',
      'www.tiktok.com',
      'vm.tiktok.com',
      'vt.tiktok.com',
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'youtu.be',
      'facebook.com',
      'www.facebook.com',
      'm.facebook.com',
      'fb.watch',
    }.contains(uri.host);

bool _isLoginPath(Uri uri) => RegExp(
  r'/(?:accounts/login|login|challenge|checkpoint|consent)(?:/|$)',
  caseSensitive: false,
).hasMatch(uri.path);

bool _isBoilerplate(String text) {
  final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return const {
        'instagram',
        'tiktok',
        'youtube',
        'facebook',
        'tiktok - make your day',
        'log in or sign up to view',
        'login • instagram',
        'page not found',
        'content unavailable',
        'this page isn’t available',
        'this page is not available',
      }.contains(normalized) ||
      RegExp(
        r'^(?:welcome (?:back )?to instagram\b|(?:log|sign)\s?in (?:to|or sign\s?up)\b|'
        r'create an account or log in\b|join instagram\b|'
        r'instagram\s*[-|•]\s*(?:log|sign)\s?in\b|see instagram photos and videos from\b)',
      ).hasMatch(normalized);
}

String _decodeEntities(String text) {
  return text
      .replaceAllMapped(RegExp(r'&#(x[0-9a-f]+|\d+);', caseSensitive: false), (
        match,
      ) {
        final raw = match.group(1)!;
        final hex = raw.toLowerCase().startsWith('x');
        final value = int.tryParse(
          hex ? raw.substring(1) : raw,
          radix: hex ? 16 : 10,
        );
        return value != null &&
                value > 0 &&
                value <= 0x10ffff &&
                (value < 0xd800 || value > 0xdfff)
            ? String.fromCharCode(value)
            : '\uFFFD';
      })
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}
