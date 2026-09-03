import 'package:flutter/services.dart';

class SharedRecipePayload {
  const SharedRecipePayload({
    this.text,
    this.filePath,
    this.mimeType,
    this.error,
  });

  final String? text;
  final String? filePath;
  final String? mimeType;
  final String? error;

  bool get hasVideo =>
      filePath != null &&
      (mimeType?.toLowerCase().startsWith('video/') ?? true);

  factory SharedRecipePayload.fromMap(Map<Object?, Object?> map) =>
      SharedRecipePayload(
        text: map['text'] as String?,
        filePath: map['filePath'] as String?,
        mimeType: map['mimeType'] as String?,
        error: map['error'] as String?,
      );
}

/// Thin bridge to Android/iOS share receivers. Native code owns content-URI
/// access and copies shared videos to an app-readable cache location before
/// Dart sees them.
class ShareIntakeService {
  ShareIntakeService._();
  static final ShareIntakeService instance = ShareIntakeService._();

  static const _channel = MethodChannel('com.sayujsujeev.cooksense/share');
  Future<void> Function()? _onShareAvailable;

  void listen(Future<void> Function() onShareAvailable) {
    _onShareAvailable = onShareAvailable;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareAvailable') await _onShareAvailable?.call();
    });
  }

  Future<List<SharedRecipePayload>> drainPendingShares() async {
    try {
      final raw = await _channel.invokeMethod<List<Object?>>(
        'drainPendingShares',
      );
      return (raw ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(SharedRecipePayload.fromMap)
          .toList();
    } on MissingPluginException {
      // Desktop/web builds do not register a share receiver.
      return const [];
    }
  }
}
