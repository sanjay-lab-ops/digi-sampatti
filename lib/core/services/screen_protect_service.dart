import 'package:flutter/services.dart';

/// Prevents screenshots and screen recording on Android.
/// Called when showing reports, legal documents, or escrow screens.
class ScreenProtectService {
  static const _channel = MethodChannel('com.digisampatti/screen_protect');

  /// Enable screenshot protection (FLAG_SECURE on Android).
  static Future<void> protect() async {
    try {
      await _channel.invokeMethod('enableProtection');
    } catch (_) {
      // Silently fail on unsupported platforms (iOS, web)
    }
  }

  /// Disable screenshot protection when leaving protected screens.
  static Future<void> unprotect() async {
    try {
      await _channel.invokeMethod('disableProtection');
    } catch (_) {}
  }
}
