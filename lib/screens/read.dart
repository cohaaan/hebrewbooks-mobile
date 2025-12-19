import 'package:flutter/material.dart';
import 'package:hebrewbooks/shared/api_urls.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// The screen for reading a book with the built-in PDF viewer.
class Read extends StatefulWidget {
  const Read({required this.bookId, required this.bookName, super.key});

  /// The ID of the book to read.
  final int bookId;

  /// The name of the book to read.
  final String bookName;

  @override
  State<Read> createState() => _ReadState();
}

class _ReadState extends State<Read> {
  var _isHorizontalMode = false;
  late PdfViewerController _pdfViewerController;
  double? _offsetX;
  double? _offsetY;
  double? _zoomLevel;
  bool _isSettingsOpen = false;
  final GlobalKey _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    super.initState();
  }

  void _saveCurrentPosition() {
    _offsetX = _pdfViewerController.scrollOffset.dx;
    _offsetY = _pdfViewerController.scrollOffset.dy;
    _zoomLevel = _pdfViewerController.zoomLevel;
  }

  void _restorePosition() {
    if (_zoomLevel != null) {
      _pdfViewerController.zoomLevel = _zoomLevel!;
    }

    if (_offsetX != null && _offsetY != null) {
      _pdfViewerController.jumpTo(xOffset: _offsetX!, yOffset: _offsetY!);
    }
  }

  void _updateViewMode(bool isHorizontal) {
    if (_isHorizontalMode != isHorizontal) {
      _saveCurrentPosition();
      setState(() {
        _isHorizontalMode = isHorizontal;
      });
      _restorePosition();
    }
  }

  Widget _buildSettingsMenu() {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingOption(
                title: 'Vertical Scrolling',
                isSelected: !_isHorizontalMode,
                onTap: () => _updateViewMode(false),
              ),
              _buildSettingOption(
                title: 'Horizontal Scrolling',
                isSelected: _isHorizontalMode,
                onTap: () => _updateViewMode(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  size: 20),
          ],
        ),
      ),
    );
  }

  void _closeSettingsMenu() {
    if (_isSettingsOpen) {
      setState(() {
        _isSettingsOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeSettingsMenu,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: _closeSettingsMenu,
            child: CustomText(widget.bookName),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                setState(() {
                  _isSettingsOpen = !_isSettingsOpen;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: SfPdfViewer.network(
                ApiUrls.downloadBookUrl(widget.bookId),
                key: _pdfViewerKey,
                controller: _pdfViewerController,
                pageLayoutMode: _isHorizontalMode
                    ? PdfPageLayoutMode.single
                    : PdfPageLayoutMode.continuous,
                scrollDirection: _isHorizontalMode
                    ? PdfScrollDirection.horizontal
                    : PdfScrollDirection.vertical,
                onDocumentLoaded: (_) {
                  // Initialize position values once document is loaded
                  if (_offsetX == null) {
                    _saveCurrentPosition();
                  } else {
                    // Also try to restore position after document loads
                    // in case a rebuild happened during loading
                    _restorePosition();
                  }
                },
                onTap: (PdfGestureDetails details) {
                  _closeSettingsMenu();
                },
              ),
            ),
            if (_isSettingsOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSettingsMenu,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
            if (_isSettingsOpen) _buildSettingsMenu(),
          ],
        ),
      ),
    );
  }
}
