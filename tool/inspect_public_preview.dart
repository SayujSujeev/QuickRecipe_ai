import 'dart:convert';
import 'dart:io';

import 'package:cooksense/core/services/public_social_preview.dart';
import 'package:cooksense/core/services/recipe_import_request.dart';

/// Read-only diagnostic using the same unauthenticated preview code as the app.
/// Does not create an import or call an AI provider.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/inspect_public_preview.dart <social-url>',
    );
    exitCode = 64;
    return;
  }
  final request = buildUrlImportRequest(
    args.first,
    idempotencyKey: 'diagnostic-only',
  );
  final preview = await PublicSocialPreview.fetch(
    request['sourceUrl'] as String,
  );
  stdout.writeln(
    jsonEncode({
      'previewAvailable': preview != null,
      'captionChars': preview?.caption.length ?? 0,
      'thumbnailCandidates': preview?.thumbnailUrls.length ?? 0,
      'captionPrefix': preview?.caption.substring(
        0,
        preview.caption.length < 100 ? preview.caption.length : 100,
      ),
    }),
  );
}
