import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/shared/widgets/centered_spinner.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:provider/provider.dart';

/// A network-aware image widget that handles connection errors gracefully
class NetworkAwareImage extends StatefulWidget {
  const NetworkAwareImage({
    required this.imageUrl,
    required this.height,
    super.key,
    this.width,
    this.fit = BoxFit.fitHeight,
    this.loadingSize,
    this.errorMessage = 'Image not available',
    this.retryOnError = true,
  });

  final String imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final int? loadingSize;
  final String errorMessage;
  final bool retryOnError;

  @override
  State<NetworkAwareImage> createState() => _NetworkAwareImageState();
}

class _NetworkAwareImageState extends State<NetworkAwareImage> {
  String? _currentImageUrl;
  bool _hasError = false;
  int _retryCount = 0;
  bool _isRetrying = false; // Add flag to prevent multiple simultaneous retries
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(NetworkAwareImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl && mounted) {
      setState(() {
        _currentImageUrl = widget.imageUrl;
        _hasError = false;
        _retryCount = 0;
      });
    }
  }

  void _handleImageError(Object error, StackTrace? stackTrace) {
    debugPrint('Image loading error: $error');

    // If already retrying or max retries exceeded, mark as error
    if (_isRetrying || _retryCount >= _maxRetries) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isRetrying = false;
            });
          }
        });
      }
      return;
    }

    // Check if it's a network-related error
    final isNetworkError = error is SocketException ||
        error is HandshakeException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('HandshakeException') ||
        error.toString().contains('Can\'t assign requested address');

    if (isNetworkError) {
      // Update connection status
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final connectionProvider =
            Provider.of<ConnectionProvider>(context, listen: false);
        connectionProvider.checkConnection();
      });

      // Retry logic for network errors
      if (widget.retryOnError && _retryCount < _maxRetries && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isRetrying = true;
            });
          }
        });

        Future.delayed(Duration(seconds: _retryCount + 1), () {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _retryCount++;
                  _hasError = false;
                  _isRetrying = false;
                  // Force reload by changing the URL slightly
                  _currentImageUrl = '${widget.imageUrl}?retry=$_retryCount';
                });
              }
            });
          }
        });
        return;
      }
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isRetrying = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Image.network(
      _currentImageUrl!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        // Only handle error if not already retrying
        if (!_isRetrying) {
          _handleImageError(error, stackTrace);
        }
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CenteredSpinner(
        size: widget.loadingSize ?? (widget.height ~/ 4).clamp(16, 48),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (widget.height * 0.3).clamp(24, 48),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomText(
              widget.errorMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isRetrying) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
