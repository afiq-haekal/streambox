import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../services/download_service.dart';

/// ChangeNotifier wrapping DownloadService for reactive UI updates.
class DownloadProvider extends ChangeNotifier {
  final DownloadService _service = DownloadService();
  final Map<String, StreamSubscription<double>> _subs = {};
  final Map<String, double> _liveProgress = {};

  List<DownloadItem> get items => _service.getAll();

  List<DownloadItem> get activeItems =>
      items.where((i) => i.status == DownloadStatus.downloading || i.status == DownloadStatus.pending).toList();

  List<DownloadItem> get completedItems =>
      items.where((i) => i.status == DownloadStatus.completed).toList();

  List<DownloadItem> get failedItems =>
      items.where((i) => i.status == DownloadStatus.failed || i.status == DownloadStatus.paused).toList();

  /// Get live progress for a download (falls back to stored progress)
  double getProgress(String id) => _liveProgress[id] ?? 0.0;

  /// Start a video download
  Future<void> downloadVideo({
    required ContentItem content,
    required Episode episode,
    required String streamUrl,
  }) async {
    final id = '${content.platform}_${content.id}_ep${episode.number}';
    _listenProgress(id);
    notifyListeners();

    await _service.downloadVideo(
      content: content,
      episode: episode,
      streamUrl: streamUrl,
    );

    _subs[id]?.cancel();
    _subs.remove(id);
    _liveProgress.remove(id);
    notifyListeners();
  }

  /// Start a komik chapter download
  Future<void> downloadKomikChapter({
    required ContentItem content,
    required Chapter chapter,
    required List<String> imageUrls,
  }) async {
    final id = '${content.platform}_${content.id}_ch${chapter.id}';
    _listenProgress(id);
    notifyListeners();

    await _service.downloadKomikChapter(
      content: content,
      chapter: chapter,
      imageUrls: imageUrls,
    );

    _subs[id]?.cancel();
    _subs.remove(id);
    _liveProgress.remove(id);
    notifyListeners();
  }

  /// Pause a download
  void pause(String id) {
    _service.pause(id);
    notifyListeners();
  }

  /// Cancel and remove a download
  Future<void> cancel(String id) async {
    _subs[id]?.cancel();
    _subs.remove(id);
    _liveProgress.remove(id);
    await _service.cancel(id);
    notifyListeners();
  }

  /// Delete a completed download
  Future<void> deleteDownload(String id) async {
    await _service.deleteDownload(id);
    notifyListeners();
  }

  /// Delete all completed downloads
  Future<void> deleteAllCompleted() async {
    await _service.deleteAllCompleted();
    notifyListeners();
  }

  /// Check if an episode/chapter is already downloaded
  bool isDownloaded(String id) => _service.isDownloaded(id);

  /// Generate download ID for an episode
  String videoId(ContentItem content, Episode ep) =>
      '${content.platform}_${content.id}_ep${ep.number}';

  /// Generate download ID for a chapter
  String chapterId(ContentItem content, Chapter ch) =>
      '${content.platform}_${content.id}_ch${ch.id}';

  void _listenProgress(String id) {
    final stream = _service.progressStream(id);
    if (stream == null) return;
    _subs[id]?.cancel();
    _subs[id] = stream.listen((progress) {
      _liveProgress[id] = progress;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
