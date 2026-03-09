import '../models/content_model.dart';

/// Parses raw API responses from each platform into unified ContentItem models.
/// Each platform returns different JSON structures — this normalizes them all.
class ContentParser {
  // ============================================================
  // DRAMA PLATFORMS (DramaBox, ReelShort, ShortMax, NetShort, Melolo, FlickReels, FreeReels)
  // ============================================================

  static List<ContentItem> parseDramaboxList(dynamic data, {String source = 'dramabox'}) {
    final list = _extractList(data);
    return list.map((item) => ContentItem(
      id: _str(item['bookId'] ?? item['id'] ?? ''),
      title: _str(item['bookName'] ?? item['name'] ?? item['title'] ?? ''),
      cover: _str(item['cover'] ?? item['coverUrl'] ?? item['image'] ?? ''),
      description: _str(item['description'] ?? item['desc'] ?? ''),
      genre: _str(item['tag'] ?? item['genre'] ?? ''),
      rating: _str(item['score'] ?? ''),
      platform: source,
      type: ContentType.drama,
      raw: item is Map<String, dynamic> ? item : {},
    )).toList();
  }

  static List<ContentItem> parseReelshortList(dynamic data) =>
      parseDramaboxList(data, source: 'reelshort');

  static List<ContentItem> parseShortmaxList(dynamic data) =>
      parseDramaboxList(data, source: 'shortmax');

  static List<ContentItem> parseNetshortList(dynamic data) =>
      parseDramaboxList(data, source: 'netshort');

  static List<ContentItem> parseMeloloList(dynamic data) =>
      parseDramaboxList(data, source: 'melolo');

  static List<ContentItem> parseFlickreelsList(dynamic data) =>
      parseDramaboxList(data, source: 'flickreels');

  static List<ContentItem> parseFreereelsList(dynamic data) =>
      parseDramaboxList(data, source: 'freereels');

  // ============================================================
  // ANIME
  // ============================================================

  static List<ContentItem> parseAnimeList(dynamic data) {
    final list = _extractList(data);
    return list.map((item) => ContentItem(
      id: _str(item['urlId'] ?? item['slug'] ?? item['id'] ?? ''),
      title: _str(item['title'] ?? item['name'] ?? ''),
      cover: _str(item['cover'] ?? item['image'] ?? item['thumbnail'] ?? ''),
      description: _str(item['synopsis'] ?? item['description'] ?? ''),
      genre: _str(item['genre'] ?? item['type'] ?? ''),
      rating: _str(item['score'] ?? item['rating'] ?? ''),
      platform: 'anime',
      type: ContentType.anime,
      raw: item is Map<String, dynamic> ? item : {},
    )).toList();
  }

  // ============================================================
  // KOMIK
  // ============================================================

  static List<ContentItem> parseKomikList(dynamic data) {
    final list = _extractList(data);
    return list.map((item) => ContentItem(
      id: _str(item['manga_id'] ?? item['id'] ?? ''),
      title: _str(item['title'] ?? item['name'] ?? ''),
      cover: _str(item['cover'] ?? item['image'] ?? item['thumbnail'] ?? ''),
      description: _str(item['synopsis'] ?? item['description'] ?? ''),
      genre: _str(item['genre'] ?? item['type'] ?? ''),
      rating: _str(item['score'] ?? item['rating'] ?? ''),
      platform: 'komik',
      type: ContentType.komik,
      raw: item is Map<String, dynamic> ? item : {},
    )).toList();
  }

  // ============================================================
  // MOVIEBOX
  // ============================================================

  static List<ContentItem> parseMovieboxList(dynamic data) {
    final list = _extractList(data);
    return list.map((item) => ContentItem(
      id: _str(item['subjectId'] ?? item['id'] ?? ''),
      title: _str(item['title'] ?? item['name'] ?? ''),
      cover: _str(item['cover'] ?? item['poster'] ?? item['image'] ?? ''),
      description: _str(item['description'] ?? item['overview'] ?? ''),
      genre: _str(item['genre'] ?? item['category'] ?? ''),
      rating: _str(item['score'] ?? item['rating'] ?? ''),
      platform: 'moviebox',
      type: ContentType.movie,
      raw: item is Map<String, dynamic> ? item : {},
    )).toList();
  }

  // ============================================================
  // DETAIL PARSERS
  // ============================================================

  static ContentDetail parseDetail(dynamic data, String platform, ContentType type) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final result = map['result'] ?? map['data'] ?? map;

    final item = ContentItem(
      id: _str(result['bookId'] ?? result['subjectId'] ?? result['manga_id'] ??
          result['urlId'] ?? result['id'] ?? ''),
      title: _str(result['bookName'] ?? result['title'] ?? result['name'] ?? ''),
      cover: _str(result['cover'] ?? result['coverUrl'] ?? result['poster'] ??
          result['image'] ?? ''),
      description: _str(result['description'] ?? result['synopsis'] ??
          result['desc'] ?? ''),
      genre: _str(result['tag'] ?? result['genre'] ?? ''),
      rating: _str(result['score'] ?? result['rating'] ?? ''),
      platform: platform,
      type: type,
      raw: result is Map<String, dynamic> ? result : {},
    );

    // Parse episodes if present
    List<Episode>? episodes;
    final rawEpisodes = result['episodes'] ?? result['episodeList'] ?? result['chapter'];
    if (rawEpisodes is List) {
      episodes = rawEpisodes.asMap().entries.map((entry) {
        final ep = entry.value;
        return Episode(
          number: ep['episodeNumber'] ?? ep['number'] ?? entry.key + 1,
          title: _str(ep['title'] ?? ep['name'] ?? 'Episode ${entry.key + 1}'),
          streamUrl: _str(ep['streamUrl'] ?? ep['url'] ?? ep['videoUrl'] ?? ''),
          thumbnail: _str(ep['cover'] ?? ep['thumbnail'] ?? ''),
          raw: ep is Map<String, dynamic> ? ep : {},
        );
      }).toList();
    }

    // Parse chapters for komik
    List<Chapter>? chapters;
    final rawChapters = result['chapters'] ?? result['chapterList'];
    if (rawChapters is List) {
      chapters = rawChapters.asMap().entries.map((entry) {
        final ch = entry.value;
        return Chapter(
          id: _str(ch['chapter_id'] ?? ch['id'] ?? ''),
          title: _str(ch['title'] ?? ch['name'] ?? 'Chapter ${entry.key + 1}'),
          number: ch['number'] ?? entry.key + 1,
          date: _str(ch['date'] ?? ch['created_at'] ?? ''),
        );
      }).toList();
    }

    return ContentDetail(
      item: item,
      synopsis: _str(result['description'] ?? result['synopsis'] ?? result['desc'] ?? ''),
      tags: _extractTags(result),
      episodes: episodes,
      chapters: chapters,
      totalEpisodes: result['totalEpisode'] ?? result['episodeCount'] ?? episodes?.length,
      raw: result is Map<String, dynamic> ? result : {},
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Extract list from various API response shapes
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      // Try common wrapper keys
      for (final key in ['result', 'data', 'list', 'items', 'results', 'dramas', 'books']) {
        if (data[key] is List) return data[key];
      }
      // Check nested result.data
      if (data['result'] is Map && data['result']['data'] is List) {
        return data['result']['data'];
      }
    }
    return [];
  }

  static String _str(dynamic value) => value?.toString() ?? '';

  static List<String>? _extractTags(Map<String, dynamic> data) {
    final tags = data['tags'] ?? data['genres'] ?? data['tag'];
    if (tags is List) return tags.map((t) => t.toString()).toList();
    if (tags is String && tags.isNotEmpty) return tags.split(',').map((t) => t.trim()).toList();
    return null;
  }
}
