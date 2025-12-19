import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hebrewbooks/services/user_agent_service.dart';
import 'package:hebrewbooks/shared/api_urls.dart';
import 'package:path_provider/path_provider.dart';

/// Global downloads provider to handle file downloads and track their progress
@pragma('vm:entry-point')
class DownloadsProvider extends ChangeNotifier {
  DownloadsProvider._internal() {
    _initialize();
  }
  static DownloadsProvider? _instance;
  static DownloadsProvider get instance {
    _instance ??= DownloadsProvider._internal();
    return _instance!;
  }

  /// Port name for download callbacks
  static const String _portName = 'download_service_port';

  /// Port for communication with download worker
  ReceivePort? _port;

  /// Local path for storing downloads
  String _localPath = '';

  /// Whether the provider is initialized
  bool _isInitialized = false;

  /// Map to track download progress by book ID
  final Map<int, DownloadInfo> _downloads = {};

  /// Callback for download completion
  void Function(int bookId, String filePath)? onDownloadComplete;

  /// Callback for download failure
  void Function(int bookId)? onDownloadFailed;

  /// Get whether the provider is initialized
  bool get isInitialized => _isInitialized;

  /// Get local path for downloads
  String get localPath => _localPath;

  /// Get download info for a book
  DownloadInfo? getDownloadInfo(int bookId) => _downloads[bookId];

  /// Check if a book is being downloaded
  bool isDownloading(int bookId) {
    final info = _downloads[bookId];
    return info != null &&
        (info.status == DownloadTaskStatus.running ||
            info.status == DownloadTaskStatus.enqueued);
  }

  /// Initialize the provider
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // Register the background isolate
      _registerBackgroundIsolate();

      // Register the callback
      await FlutterDownloader.registerCallback(downloadCallback);

      // Prepare directories
      await _prepareSaveDir();

      _isInitialized = true;
      debugPrint('DownloadsProvider initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize DownloadsProvider: $e');
    }
  }

  /// Register the background isolate for communication
  void _registerBackgroundIsolate() {
    // Clean up existing port
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);

    // Create new port
    _port = ReceivePort();

    // Register port
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port!.sendPort,
      _portName,
    );

    debugPrint('DownloadsProvider port registration success: $isSuccess');

    // Listen for download updates
    _port!.listen((dynamic data) {
      if (data is! List || data.length < 3) return;

      final taskId = data[0] as String?;
      final status = DownloadTaskStatus.fromInt(data[1] as int);
      final progress = data[2] as int;

      if (taskId != null) {
        _updateTaskData(taskId, status, progress);
      }
    });
  }

  /// Update download task data and notify listeners
  void _updateTaskData(String taskId, DownloadTaskStatus status, int progress) {
    // Find which book ID this task belongs to
    int? bookId;
    for (final entry in _downloads.entries) {
      if (entry.value.taskId == taskId) {
        bookId = entry.key;
        break;
      }
    }

    if (bookId == null) return;

    final oldInfo = _downloads[bookId]!;
    _downloads[bookId] = oldInfo.copyWith(
      status: status,
      progress: progress,
    );

    // Handle completion
    if (status == DownloadTaskStatus.complete) {
      _handleDownloadComplete(bookId, oldInfo);
    } else if (status == DownloadTaskStatus.failed) {
      _handleDownloadFailed(bookId);
    }

    notifyListeners();
  }

  /// Handle download completion
  void _handleDownloadComplete(int bookId, DownloadInfo info) {
    final filePath = '${_localPath}/${info.fileName}';
    onDownloadComplete?.call(bookId, filePath);
  }

  /// Handle download failure
  void _handleDownloadFailed(int bookId) {
    onDownloadFailed?.call(bookId);
  }

  /// Prepare the save directory
  Future<void> _prepareSaveDir() async {
    _localPath = await _getSaveDir();
    final saveDir = Directory(_localPath);
    if (!saveDir.existsSync()) {
      await saveDir.create(recursive: true);
    }
  }

  /// Get the save directory
  Future<String> _getSaveDir() async {
    if (Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${appDocDir.path}/PDFs');
      await directory.create(recursive: true);
      return directory.path;
    } else {
      // Android - always use Downloads/HebrewBooks PDFs
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final directory = Directory('${downloadsDir.path}/HebrewBooks PDFs');
        await directory.create(recursive: true);
        return directory.path;
      } else {
        // Fallback for older Android versions
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final directory =
              Directory('${externalDir.path}/Download/HebrewBooks PDFs');
          await directory.create(recursive: true);
          return directory.path;
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          final directory = Directory('${appDocDir.path}/HebrewBooks PDFs');
          await directory.create(recursive: true);
          return directory.path;
        }
      }
    }
  }

  /// Sanitize filename by removing problematic characters
  String _sanitizeFilename(String title) {
    return title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'),
            '_') // Only remove file system forbidden characters
        .replaceAll(
            RegExp(r'\s+'), ' ') // Keep single spaces, collapse multiple spaces
        .trim(); // Remove leading/trailing whitespace
  }

  /// Download a book by ID
  Future<String?> downloadBook(int bookId, String title) async {
    // Check if already downloading
    if (isDownloading(bookId)) {
      debugPrint('Book $bookId is already being downloaded');
      return null;
    }

    // Ensure initialized
    if (!_isInitialized) {
      await _initialize();
    }

    // Ensure the save directory is prepared
    if (_localPath.isEmpty) {
      await _prepareSaveDir();
    }

    // Sanitize filename
    final fileName = _sanitizeFilename('HebrewBooks-$title-$bookId.pdf');

    // Get the URL from ApiUrls
    final downloadUrl = ApiUrls.downloadBookUrl(bookId);

    try {
      // Start the download
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        headers: {
          'User-Agent': await UserAgentService.getCustomUserAgent(),
        },
        savedDir: _localPath,
        fileName: fileName,
        showNotification: true, // TODO: Not working on iOS
        openFileFromNotification: true,
      );

      if (taskId != null) {
        // Store download info
        _downloads[bookId] = DownloadInfo(
          taskId: taskId,
          bookId: bookId,
          title: title,
          fileName: fileName,
          progress: 0,
          status: DownloadTaskStatus.enqueued,
        );

        notifyListeners();

        await FirebaseAnalytics.instance.logEvent(
          name: 'start_download',
          parameters: {
            'book_id': bookId,
          },
        );
      }

      return taskId;
    } catch (e) {
      debugPrint('Failed to start download for book $bookId: $e');
      return null;
    }
  }

  /// Cancel a book download
  Future<void> cancelDownload(int bookId) async {
    final info = _downloads[bookId];
    if (info != null) {
      await FlutterDownloader.cancel(taskId: info.taskId);
      _downloads.remove(bookId);
      notifyListeners();
      await FirebaseAnalytics.instance.logEvent(
        name: 'cancel_download',
        parameters: {
          'book_id': bookId,
        },
      );
    }
  }

  /// Open a downloaded file
  Future<bool> openDownload(int bookId) async {
    final info = _downloads[bookId];
    if (info?.taskId != null) {
      return FlutterDownloader.open(taskId: info!.taskId);
    }
    return false;
  }

  /// Clean up resources
  @override
  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    super.dispose();
  }

  /// Static callback that will be triggered from background isolate
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName(_portName);
    if (send != null) {
      send.send([id, status, progress]);
    } else {
      debugPrint('ERROR: DownloadsProvider port not found');
    }
  }
}

/// Download information class
class DownloadInfo {
  const DownloadInfo({
    required this.taskId,
    required this.bookId,
    required this.title,
    required this.fileName,
    required this.progress,
    required this.status,
  });
  final String taskId;
  final int bookId;
  final String title;
  final String fileName;
  final int progress;
  final DownloadTaskStatus status;

  DownloadInfo copyWith({
    String? taskId,
    int? bookId,
    String? title,
    String? fileName,
    int? progress,
    DownloadTaskStatus? status,
  }) {
    return DownloadInfo(
      taskId: taskId ?? this.taskId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
