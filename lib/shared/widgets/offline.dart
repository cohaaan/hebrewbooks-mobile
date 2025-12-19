import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:provider/provider.dart';

/// The widget to show when no internet connection is detected.
/// This can be displayed as a modal dialog by screens when needed.
class Offline extends StatefulWidget {
  const Offline({super.key, this.onRetry, this.onClose});

  /// Optional callback when the retry button is pressed
  final VoidCallback? onRetry;

  /// Optional callback when the dialog is closed
  final VoidCallback? onClose;

  /// Shows the offline dialog
  static Future<void> showAsDialog(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) async {
    // Show the dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Offline(
        onRetry: onRetry,
        onClose: onClose,
      ),
    );
  }

  @override
  State<Offline> createState() => _OfflineState();
}

class _OfflineState extends State<Offline> {
  Timer? _autoRetryTimer;
  int _autoRetryCount = 0;
  static const int _maxAutoRetries = 2;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    if (_autoRetryCount >= _maxAutoRetries) return;

    _autoRetryTimer = Timer(Duration(seconds: (_autoRetryCount + 1) * 3), () {
      if (mounted) {
        _autoRetryCount++;
        _checkConnectionAndClose();
      }
    });
  }

  Future<void> _checkConnectionAndClose() async {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);

    final result = await connectionProvider.checkConnection();

    if (result && mounted) {
      Navigator.of(context).pop();
      widget.onRetry?.call();
    } else if (_autoRetryCount < _maxAutoRetries) {
      _startAutoRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                CustomText.left('No Internet Connection'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText.left(
                  'Please check your network settings and try again.',
                ),
                const SizedBox(height: 16),
                if (connectionProvider.isCheckingConnection) ...[
                  Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomText.left('Checking connection...'),
                    ],
                  ),
                ] else if (_autoRetryCount < _maxAutoRetries) ...[
                  Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomText.left('Retrying automatically...'),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: connectionProvider.isCheckingConnection
                    ? null
                    : () async {
                        _autoRetryTimer
                            ?.cancel(); // Cancel auto retry when user manually retries
                        final result =
                            await connectionProvider.checkConnection();

                        if (result && mounted) {
                          Navigator.of(context).pop();
                          widget.onRetry?.call();
                        }
                      },
                child: CustomText(connectionProvider.isCheckingConnection
                    ? 'Checking...'
                    : 'Try Again'),
              ),
            ],
          ),
        );
      },
    );
  }
}
