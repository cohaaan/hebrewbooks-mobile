import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:hebrewbooks/main.dart';

/// This service provides a custom User-Agent string for the app, which can be used in HTTP requests or web views.
class UserAgentService {
  static String? _userAgent;

  /// Creates a custom User-Agent string for the app.
  static Future<String> getCustomUserAgent() async {
    // Return the cached user agent if it's already been created.
    if (_userAgent != null) {
      return _userAgent!;
    }

    // Get app and device info
    const appName = 'HebrewBooks';
    final deviceInfo = DeviceInfoPlugin();
    String platformInfo;

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      platformInfo =
          'iOS; ${iosInfo.systemVersion}; ${iosInfo.utsname.machine}';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      platformInfo =
          'Android; ${androidInfo.version.release}; ${androidInfo.model}';
    } else {
      platformInfo = 'Unknown Platform';
    }

    _userAgent = '$appName/${MyApp.appVersion} ($platformInfo)';
    return _userAgent!;
  }
}
