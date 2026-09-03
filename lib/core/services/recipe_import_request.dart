/// Builds the wire request separately from Firebase so paste/share handling
/// and backwards compatibility can be tested without a running backend.
Map<String, dynamic> buildUrlImportRequest(
  String sharedText, {
  required String idempotencyKey,
  String targetLanguage = 'en',
  String measurementSystem = 'metric',
}) {
  final match = RegExp(
    r'''https?://[^\s<>"']+''',
    caseSensitive: false,
  ).firstMatch(sharedText.trim());
  final extracted = match?.group(0)?.replaceFirst(RegExp(r'[\])},.;!?]+$'), '');
  final uri = extracted == null ? null : Uri.tryParse(extracted);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.port != 443 ||
      extracted!.length > 4096) {
    throw const FormatException('A valid HTTPS video link is required.');
  }

  var sourceUrl = uri.toString();
  final isInstagram =
      uri.host == 'instagram.com' || uri.host == 'www.instagram.com';
  if (isInstagram) {
    final path = RegExp(
      r'^/(reel|reels|p)/([A-Za-z0-9_-]+)/?$',
    ).firstMatch(uri.path);
    if (path == null) {
      throw const FormatException(
        'An Instagram reel or post link is required.',
      );
    }
    final kind = path.group(1) == 'reels' ? 'reel' : path.group(1);
    sourceUrl = 'https://www.instagram.com/$kind/${path.group(2)}/';
  }

  return {
    // Keep the original API tag for Instagram. Both old and new backends
    // accept it; sending social_url breaks clients during a staged rollout.
    'sourceType': isInstagram ? 'instagram_url' : 'social_url',
    'sourceUrl': sourceUrl,
    'targetLanguage': targetLanguage,
    'measurementSystem': measurementSystem,
    'idempotencyKey': idempotencyKey,
  };
}
