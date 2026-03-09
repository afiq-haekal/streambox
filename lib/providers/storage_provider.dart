import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/content_model.dart';

/// Manages bookmarks and watch/read history via Hive.
class StorageProvider extends ChangeNotifier {
  Box get _bookmarksBox => Hive.box('bookmarks');
  Box get _historyBox => Hive.box('history');

  // ═══════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════

  /// Get all bookmarks sorted by newest first
  List<Bookmark> get bookmarks {
    final items = <Bookmark>[];
    for (final key in _bookmarksBox.keys) {
      final json = _bookmarksBox.get(key);
      if (json is Map) {
        items.add(Bookmark.fromJson(Map<String, dynamic>.from(json)));
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Check if content is bookmarked
  bool isBookmarked(String contentId, String platform) {
    final key = '${platform}_$contentId';
    return _bookmarksBox.containsKey(key);
  }

  /// Toggle bookmark — returns true if now bookmarked
  bool toggleBookmark(ContentItem item) {
    final key = '${item.platform}_${item.id}';
    if (_bookmarksBox.containsKey(key)) {
      _bookmarksBox.delete(key);
      notifyListeners();
      return false;
    } else {
      final bookmark = Bookmark(
        contentId: item.id,
        title: item.title,
        cover: item.cover,
        platform: item.platform,
        type: item.type,
      );
      _bookmarksBox.put(key, bookmark.toJson());
      notifyListeners();
      return true;
    }
  }

  /// Add bookmark from ContentDetail
  void addBookmark(ContentDetail detail) {
    final item = detail.item;
    final key = '${item.platform}_${item.id}';
    if (_bookmarksBox.containsKey(key)) return;
    final bookmark = Bookmark(
      contentId: item.id,
      title: item.title,
      cover: item.cover,
      platform: item.platform,
      type: item.type,
    );
    _bookmarksBox.put(key, bookmark.toJson());
    notifyListeners();
  }

  /// Remove bookmark
  void removeBookmark(String contentId, String platform) {
    final key = '${platform}_$contentId';
    _bookmarksBox.delete(key);
    notifyListeners();
  }

  /// Clear all bookmarks
  void clearBookmarks() {
    _bookmarksBox.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════

  /// Get all history sorted by most recent
  List<HistoryItem> get history {
    final items = <HistoryItem>[];
    for (final key in _historyBox.keys) {
      final json = _historyBox.get(key);
      if (json is Map) {
        items.add(HistoryItem.fromJson(Map<String, dynamic>.from(json)));
      }
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// Add or update a generic history entry from a ContentItem.
  /// Used by player_screen and komik_reader_screen to record
  /// that the user opened this content.
  void addToHistory(ContentItem content) {
    final key = '${content.platform}_${content.id}';
    final entry = HistoryItem(
      contentId: content.id,
      title: content.title,
      cover: content.cover,
      platform: content.platform,
      type: content.type,
    );
    _historyBox.put(key, entry.toJson());
    notifyListeners();
  }

  /// Update or create history entry for video playback
  void updateVideoHistory({
    required ContentItem content,
    required int episodeNumber,
    double progress = 0.0,
  }) {
    final key = '${content.platform}_${content.id}';
    final entry = HistoryItem(
      contentId: content.id,
      title: content.title,
      cover: content.cover,
      platform: content.platform,
      type: content.type,
      lastEpisode: episodeNumber,
      progress: progress,
    );
    _historyBox.put(key, entry.toJson());
    notifyListeners();
  }

  /// Update or create history entry for komik reading
  void updateKomikHistory({
    required ContentItem content,
    required String chapterId,
  }) {
    final key = '${content.platform}_${content.id}';
    final entry = HistoryItem(
      contentId: content.id,
      title: content.title,
      cover: content.cover,
      platform: content.platform,
      type: content.type,
      lastChapterId: chapterId,
    );
    _historyBox.put(key, entry.toJson());
    notifyListeners();
  }

  /// Get history item for specific content
  HistoryItem? getHistory(String contentId, String platform) {
    final key = '${platform}_$contentId';
    final json = _historyBox.get(key);
    if (json is Map) {
      return HistoryItem.fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  /// Remove a single history entry
  void removeHistory(String contentId, String platform) {
    final key = '${platform}_$contentId';
    _historyBox.delete(key);
    notifyListeners();
  }

  /// Clear all history
  void clearHistory() {
    _historyBox.clear();
    notifyListeners();
  }
}
