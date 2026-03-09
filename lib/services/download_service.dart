import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/content_model.dart';

/// Download manager — handles video/image downloads with progress,
/// pause/resume, cancel, and Hive persistence.
class DownloadService {
  static final DownloadService _instance = DownloadService._();
  factory DownloadService() => _instance;
  DownloadService._();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<double>> _progressStreams = {};
  Box get _box => Hive.box('downloads');

  /// Get all download items from Hive
  List<DownloadItem> getAll() {
    final items = <DownloadItem>[];
    for (final key in _box.keys) {
      final json = _box.get(key);
      if (json is Map) {
        items.add(DownloadItem.fromJson(Map<String, dynamic>.from(json)));
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Get progress stream for a download
  Stream<double>? progressStream(String id) => _progressStreams[id]?.stream;

  /// Get the local downloads directory
  Future<String> get _downloadDir async {
    final dir = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${dir.path}/StreamBox/downloads');
    if (!await dlDir.exists()) await dlDir.create(recursive: true);
    return dlDir.path;
  }

  /// Start downloading a video episode
  Future<void> downloadVideo({
    required ContentItem content,
    required Episode episode,
    required String streamUrl,
  }) async {
    final id = '${content.platform}_${content.id}_ep${episode.number}';
    if (_cancelTokens.containsKey(id)) return; // already downloading

    final dir = await _downloadDir;
    final ext = streamUrl.contains('.m3u8') ? '.mp4' : '.mp4';
    final localPath = '$dir/${content.platform}_${content.id}_ep${episode.number}$ext';

    final item = DownloadItem(
      id: id,
      contentId: content.id,
      title: '${content.title} - Ep ${episode.number}',
      cover: content.cover,
      platform: content.platform,
      type: content.type,
      episodeNumber: episode.number,
      localPath: localPath,
      status: DownloadStatus.downloading,
    );

    _saveItem(item);
    _cancelTokens[id] = CancelToken();
    _progressStreams[id] = StreamController<double>.broadcast();

    try {
      await _dio.download(
        streamUrl,
        localPath,
        cancelToken: _cancelTokens[id],
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final progress = received / total;
          _progressStreams[id]?.add(progress);
          _saveItem(DownloadItem(
            id: id, contentId: item.contentId, title: item.title,
            cover: item.cover, platform: item.platform, type: item.type,
            episodeNumber: item.episodeNumber, localPath: localPath,
            progress: progress, status: DownloadStatus.downloading,
            createdAt: item.createdAt,
          ));
        },
      );

      // Completed
      _saveItem(DownloadItem(
        id: id, contentId: item.contentId, title: item.title,
        cover: item.cover, platform: item.platform, type: item.type,
        episodeNumber: item.episodeNumber, localPath: localPath,
        progress: 1.0, status: DownloadStatus.completed,
        createdAt: item.createdAt,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // User cancelled — keep as paused
        _saveItem(DownloadItem(
          id: id, contentId: item.contentId, title: item.title,
          cover: item.cover, platform: item.platform, type: item.type,
          episodeNumber: item.episodeNumber, localPath: localPath,
          progress: item.progress, status: DownloadStatus.paused,
          createdAt: item.createdAt,
        ));
      } else {
        _saveItem(DownloadItem(
          id: id, contentId: item.contentId, title: item.title,
          cover: item.cover, platform: item.platform, type: item.type,
          episodeNumber: item.episodeNumber, localPath: localPath,
          progress: item.progress, status: DownloadStatus.failed,
          createdAt: item.createdAt,
        ));
      }
    } catch (_) {
      _saveItem(DownloadItem(
        id: id, contentId: item.contentId, title: item.title,
        cover: item.cover, platform: item.platform, type: item.type,
        episodeNumber: item.episodeNumber, localPath: localPath,
        progress: item.progress, status: DownloadStatus.failed,
        createdAt: item.createdAt,
      ));
    } finally {
      _cancelTokens.remove(id);
      _progressStreams[id]?.close();
      _progressStreams.remove(id);
    }
  }

  /// Download komik chapter images as a batch
  Future<void> downloadKomikChapter({
    required ContentItem content,
    required Chapter chapter,
    required List<String> imageUrls,
  }) async {
    final id = '${content.platform}_${content.id}_ch${chapter.id}';
    if (_cancelTokens.containsKey(id)) return;

    final dir = await _downloadDir;
    final chapterDir = Directory('$dir/${content.platform}_${content.id}_ch${chapter.id}');
    if (!await chapterDir.exists()) await chapterDir.create(recursive: true);

    final item = DownloadItem(
      id: id,
      contentId: content.id,
      title: '${content.title} - ${chapter.title}',
      cover: content.cover,
      platform: content.platform,
      type: content.type,
      chapterId: chapter.id,
      localPath: chapterDir.path,
      status: DownloadStatus.downloading,
    );

    _saveItem(item);
    _cancelTokens[id] = CancelToken();
    _progressStreams[id] = StreamController<double>.broadcast();

    try {
      for (int i = 0; i < imageUrls.length; i++) {
        if (_cancelTokens[id]?.isCancelled ?? true) break;

        final imgPath = '${chapterDir.path}/page_${i.toString().padLeft(3, '0')}.jpg';
        await _dio.download(
          imageUrls[i],
          imgPath,
          cancelToken: _cancelTokens[id],
        );

        final progress = (i + 1) / imageUrls.length;
        _progressStreams[id]?.add(progress);
        _saveItem(DownloadItem(
          id: id, contentId: item.contentId, title: item.title,
          cover: item.cover, platform: item.platform, type: item.type,
          chapterId: item.chapterId, localPath: chapterDir.path,
          progress: progress, status: DownloadStatus.downloading,
          createdAt: item.createdAt,
        ));
      }

      if (!(_cancelTokens[id]?.isCancelled ?? true)) {
        _saveItem(DownloadItem(
          id: id, contentId: item.contentId, title: item.title,
          cover: item.cover, platform: item.platform, type: item.type,
          chapterId: item.chapterId, localPath: chapterDir.path,
          progress: 1.0, status: DownloadStatus.completed,
          createdAt: item.createdAt,
        ));
      }
    } on DioException catch (e) {
      final status = e.type == DioExceptionType.cancel
          ? DownloadStatus.paused
          : DownloadStatus.failed;
      _updateStatus(id, status);
    } catch (_) {
      _updateStatus(id, DownloadStatus.failed);
    } finally {
      _cancelTokens.remove(id);
      _progressStreams[id]?.close();
      _progressStreams.remove(id);
    }
  }

  /// Pause a download (cancels the token, marks paused)
  void pause(String id) {
    _cancelTokens[id]?.cancel('paused');
  }

  /// Resume a failed/paused download (re-fetches from scratch for simplicity)
  Future<void> resume(String id) async {
    final json = _box.get(id);
    if (json == null) return;
    final item = DownloadItem.fromJson(Map<String, dynamic>.from(json));
    // Delete partial file and restart
    await deleteFile(item.localPath);
    _box.delete(id);
    // Caller should re-trigger downloadVideo/downloadKomikChapter
  }

  /// Cancel and remove a download
  Future<void> cancel(String id) async {
    _cancelTokens[id]?.cancel('cancelled');
    _cancelTokens.remove(id);
    _progressStreams[id]?.close();
    _progressStreams.remove(id);

    final json = _box.get(id);
    if (json != null) {
      final item = DownloadItem.fromJson(Map<String, dynamic>.from(json));
      await deleteFile(item.localPath);
    }
    _box.delete(id);
  }

  /// Delete a completed download
  Future<void> deleteDownload(String id) async {
    final json = _box.get(id);
    if (json != null) {
      final item = DownloadItem.fromJson(Map<String, dynamic>.from(json));
      await deleteFile(item.localPath);
    }
    _box.delete(id);
  }

  /// Delete all completed downloads
  Future<void> deleteAllCompleted() async {
    final items = getAll().where((i) => i.status == DownloadStatus.completed);
    for (final item in items) {
      await deleteFile(item.localPath);
      _box.delete(item.id);
    }
  }

  /// Check if content episode/chapter is downloaded
  bool isDownloaded(String id) {
    final json = _box.get(id);
    if (json == null) return false;
    final item = DownloadItem.fromJson(Map<String, dynamic>.from(json));
    return item.status == DownloadStatus.completed;
  }

  // ── Private helpers ──

  void _saveItem(DownloadItem item) {
    _box.put(item.id, item.toJson());
  }

  void _updateStatus(String id, DownloadStatus status) {
    final json = _box.get(id);
    if (json == null) return;
    final item = DownloadItem.fromJson(Map<String, dynamic>.from(json));
    _saveItem(DownloadItem(
      id: item.id, contentId: item.contentId, title: item.title,
      cover: item.cover, platform: item.platform, type: item.type,
      episodeNumber: item.episodeNumber, chapterId: item.chapterId,
      localPath: item.localPath, progress: item.progress, status: status,
      createdAt: item.createdAt,
    ));
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete(recursive: true);
    } else {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }
}
