import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service to handle application permissions
class PermissionsService {
  /// Factory constructor
  factory PermissionsService() => _instance;

  /// Internal constructor
  PermissionsService._internal();

  /// Singleton instance
  static final PermissionsService _instance = PermissionsService._internal();

  /// Device info plugin instance
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check if storage permission is granted
  Future<bool> checkStoragePermission() async {
    // iOS doesn't need explicit storage permission
    if (Platform.isIOS) return true;

    // For Android, check API level
    if (Platform.isAndroid) {
      return _checkAndroidStoragePermission();
    }

    throw StateError('Unsupported platform');
  }

  /// Check Android-specific storage permission based on API level
  Future<bool> _checkAndroidStoragePermission() async {
    final info = await _deviceInfo.androidInfo;

    // Android 10+ (API 29+) doesn't need storage permission for app-specific directories
    if (info.version.sdkInt > 28) {
      return true;
    }

    // Android 9 (API 28) and below need storage permission
    return Permission.storage.isGranted;
  }

  /// Request storage permission with optional UI feedback
  Future<bool> requestStoragePermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    // iOS doesn't need explicit storage permission
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      return _requestAndroidStoragePermission(context, showRationale);
    }

    throw StateError('Unsupported platform');
  }

  /// Request Android-specific storage permission
  Future<bool> _requestAndroidStoragePermission(
    BuildContext? context,
    bool showRationale,
  ) async {
    final info = await _deviceInfo.androidInfo;

    // Android 10+ (API 29+) doesn't need storage permission for app-specific directories
    if (info.version.sdkInt > 28) {
      return true;
    }

    // For Android 9 (API 28) and below, request storage permission
    final status = await Permission.storage.request();

    // Store context and check if we need to show UI feedback
    final shouldShowFeedback =
        !status.isGranted && showRationale && context != null;
    final capturedContext = context;

    // Show UI feedback if permission denied and context is available
    if (shouldShowFeedback && capturedContext != null) {
      _showPermissionDeniedFeedback(capturedContext);
    }

    return status.isGranted;
  }

  /// Show feedback when permission is denied
  void _showPermissionDeniedFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText('Storage permission is needed to download books'),
        action: const SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  /// Check if permission rationale should be shown (Android only)
  Future<bool> shouldShowRationale() async {
    if (!Platform.isAndroid) return false;

    final info = await _deviceInfo.androidInfo;
    if (info.version.sdkInt > 28) return false;

    return Permission.storage.shouldShowRequestRationale;
  }
}
