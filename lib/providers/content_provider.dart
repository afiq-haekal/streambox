import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/api_service.dart';
import '../services/content_parser.dart';

/// Manages all content state — fetching, caching, and exposing data to UI.
/// Each category (Drama, Anime, Komik, Movie) has its own sections.
class ContentProvider extends ChangeNotifier {
  final ApiService _api;

  ContentProvider(this._api);

  // ============================================================
  // STATE
  // ============================================================

  // Drama sections (aggregated from multiple platforms)
  List<ContentItem> _dramaForYou = [];
  List<ContentItem> _dramaTrending = [];
  List<ContentItem> _dramaLatest = [];
  List<ContentItem> _dramaVip = [];

  // Anime sections
  List<ContentItem> _animeRecommended = [];
  List<ContentItem> _animeLatest = [];
  List<ContentItem> _animeMovies = [];

  // Komik sections
  List<ContentItem> _komikPopular = [];
  List<ContentItem> _komikLatestProject = [];
  List<ContentItem> _komikManhwa = [];
  List<ContentItem> _komikManhua = [];

  // Movie sections
  List<ContentItem> _movieHomepage = [];
  List<ContentItem> _movieTrending = [];

  // Search results
  List<ContentItem> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // Loading states per category
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  // ============================================================
  // GETTERS
  // ============================================================

  // Drama
  List<ContentItem> get dramaForYou => _dramaForYou;
  List<ContentItem> get dramaTrending => _dramaTrending;
  List<ContentItem> get dramaLatest => _dramaLatest;
  List<ContentItem> get dramaVip => _dramaVip;

  // Anime
  List<ContentItem> get animeRecommended => _animeRecommended;
  List<ContentItem> get animeLatest => _animeLatest;
  List<ContentItem> get animeMovies => _animeMovies;

  // Komik
  List<ContentItem> get komikPopular => _komikPopular;
  List<ContentItem> get komikLatestProject => _komikLatestProject;
  List<ContentItem> get komikManhwa => _komikManhwa;
  List<ContentItem> get komikManhua => _komikManhua;

  // Movie
  List<ContentItem> get movieHomepage => _movieHomepage;
  List<ContentItem> get movieTrending => _movieTrending;

  // Search
  List<ContentItem> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  // Loading & Error
  bool isLoading(String key) => _loading[key] ?? false;
  String? getError(String key) => _errors[key];
  bool get isDramaLoading => isLoading('drama');
  bool get isAnimeLoading => isLoading('anime');
  bool get isKomikLoading => isLoading('komik');
  bool get isMovieLoading => isLoading('movie');

  // ============================================================
  // DRAMA — Aggregated from DramaBox, ReelShort, ShortMax, etc.
  // ============================================================

  Future<void> loadDrama({bool forceRefresh = false}) async {
    if (_dramaForYou.isNotEmpty && !forceRefresh) return;
    _setLoading('drama', true);

    try {
      // Fetch from multiple platforms in parallel
      final results = await Future.wait([
        _api.dramaboxForYou().then((d) => ContentParser.parseDramaboxList(d)),
        _api.dramaboxTrending().then((d) => ContentParser.parseDramaboxList(d)),
        _api.dramaboxLatest().then((d) => ContentParser.parseDramaboxList(d)),
        _api.reelshortForYou().then((d) => ContentParser.parseReelshortList(d)),
        _api.shortmaxForYou().then((d) => ContentParser.parseShortmaxList(d)),
        _api.meloloForYou().then((d) => ContentParser.parseMeloloList(d)),
        _api.flickreelsForYou().then((d) => ContentParser.parseFlickreelsList(d)),
        _api.freereelsForYou().then((d) => ContentParser.parseFreereelsList(d)),
      ].map((f) => f.catchError((_) => <ContentItem>[])));

      // Combine "For You" from all platforms
      _dramaForYou = [
        ...results[0], // DramaBox ForYou
        ...results[3], // ReelShort ForYou
        ...results[4], // ShortMax ForYou
        ...results[5], // Melolo ForYou
        ...results[6], // FlickReels ForYou
        ...results[7], // FreeReels ForYou
      ]..shuffle();

      _dramaTrending = results[1]; // DramaBox Trending
      _dramaLatest = results[2];   // DramaBox Latest

      // Fetch VIP separately (less critical)
      _api.dramaboxVip()
          .then((d) => ContentParser.parseDramaboxList(d))
          .then((items) {
        _dramaVip = items;
        notifyListeners();
      }).catchError((_) {});

      _setError('drama', null);
    } catch (e) {
      _setError('drama', 'Failed to load dramas: $e');
    }

    _setLoading('drama', false);
  }

  // ============================================================
  // ANIME
  // ============================================================

  Future<void> loadAnime({bool forceRefresh = false}) async {
    if (_animeRecommended.isNotEmpty && !forceRefresh) return;
    _setLoading('anime', true);

    try {
      final results = await Future.wait([
        _api.animeRecommended().then((d) => ContentParser.parseAnimeList(d)),
        _api.animeLatest().then((d) => ContentParser.parseAnimeList(d)),
        _api.animeMovie().then((d) => ContentParser.parseAnimeList(d)),
      ].map((f) => f.catchError((_) => <ContentItem>[])));

      _animeRecommended = results[0];
      _animeLatest = results[1];
      _animeMovies = results[2];

      _setError('anime', null);
    } catch (e) {
      _setError('anime', 'Failed to load anime: $e');
    }

    _setLoading('anime', false);
  }

  // ============================================================
  // KOMIK
  // ============================================================

  Future<void> loadKomik({bool forceRefresh = false}) async {
    if (_komikPopular.isNotEmpty && !forceRefresh) return;
    _setLoading('komik', true);

    try {
      final results = await Future.wait([
        _api.komikPopular().then((d) => ContentParser.parseKomikList(d)),
        _api.komikLatest(type: 'project').then((d) => ContentParser.parseKomikList(d)),
        _api.komikRecommended(type: 'manhwa').then((d) => ContentParser.parseKomikList(d)),
        _api.komikRecommended(type: 'manhua').then((d) => ContentParser.parseKomikList(d)),
      ].map((f) => f.catchError((_) => <ContentItem>[])));

      _komikPopular = results[0];
      _komikLatestProject = results[1];
      _komikManhwa = results[2];
      _komikManhua = results[3];

      _setError('komik', null);
    } catch (e) {
      _setError('komik', 'Failed to load komik: $e');
    }

    _setLoading('komik', false);
  }

  // ============================================================
  // MOVIE
  // ============================================================

  Future<void> loadMovie({bool forceRefresh = false}) async {
    if (_movieHomepage.isNotEmpty && !forceRefresh) return;
    _setLoading('movie', true);

    try {
      final results = await Future.wait([
        _api.movieboxHomepage().then((d) => ContentParser.parseMovieboxList(d)),
        _api.movieboxTrending().then((d) => ContentParser.parseMovieboxList(d)),
      ].map((f) => f.catchError((_) => <ContentItem>[])));

      _movieHomepage = results[0];
      _movieTrending = results[1];

      _setError('movie', null);
    } catch (e) {
      _setError('movie', 'Failed to load movies: $e');
    }

    _setLoading('movie', false);
  }

  // ============================================================
  // SEARCH — Cross-platform search
  // ============================================================

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isSearching = true;
    _searchResults = [];
    notifyListeners();

    try {
      // Search ALL platforms in parallel
      final results = await Future.wait([
        _api.dramaboxSearch(query: query)
            .then((d) => ContentParser.parseDramaboxList(d)),
        _api.reelshortSearch(query: query)
            .then((d) => ContentParser.parseReelshortList(d)),
        _api.shortmaxSearch(query: query)
            .then((d) => ContentParser.parseShortmaxList(d)),
        _api.netshortSearch(query: query)
            .then((d) => ContentParser.parseNetshortList(d)),
        _api.meloloSearch(query: query)
            .then((d) => ContentParser.parseMeloloList(d)),
        _api.flickreelsSearch(query: query)
            .then((d) => ContentParser.parseFlickreelsList(d)),
        _api.freereelsSearch(query: query)
            .then((d) => ContentParser.parseFreereelsList(d)),
        _api.animeSearch(query: query)
            .then((d) => ContentParser.parseAnimeList(d)),
        _api.komikSearch(query: query)
            .then((d) => ContentParser.parseKomikList(d)),
        _api.movieboxSearch(query: query)
            .then((d) => ContentParser.parseMovieboxList(d)),
      ].map((f) => f.catchError((_) => <ContentItem>[])));

      // Merge all results
      _searchResults = results.expand((list) => list).toList();
      _setError('search', null);
    } catch (e) {
      _setError('search', 'Search failed: $e');
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _searchQuery = '';
    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  // ============================================================
  // DETAIL — Fetch detail for any platform
  // ============================================================

  ContentDetail? _currentDetail;
  bool _isDetailLoading = false;
  String? _detailError;

  ContentDetail? get currentDetail => _currentDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;

  Future<ContentDetail?> fetchDetail(ContentItem item) async {
    _isDetailLoading = true;
    _detailError = null;
    _currentDetail = null;
    notifyListeners();

    try {
      dynamic rawDetail;
      dynamic rawEpisodes;

      switch (item.platform) {
        case 'dramabox':
          rawDetail = await _api.dramaboxDetail(bookId: item.id);
          // Also fetch all episodes
          rawEpisodes = await _api.dramaboxAllEpisodes(bookId: item.id)
              .catchError((_) => null);
          break;
        case 'reelshort':
          rawDetail = await _api.reelshortDetail(bookId: item.id);
          break;
        case 'shortmax':
          rawDetail = await _api.shortmaxDetail(shortPlayId: item.id);
          rawEpisodes = await _api.shortmaxAllEpisodes(shortPlayId: item.id)
              .catchError((_) => null);
          break;
        case 'netshort':
          // Netshort has no detail endpoint, use episodes directly
          rawEpisodes = await _api.netshortAllEpisodes(shortPlayId: item.id);
          rawDetail = rawEpisodes;
          break;
        case 'melolo':
          rawDetail = await _api.meloloDetail(bookId: item.id);
          break;
        case 'flickreels':
          rawDetail = await _api.flickreelsDetailAndEpisodes(id: item.id);
          break;
        case 'freereels':
          rawDetail = await _api.freereelsDetailAndEpisodes(key: item.id);
          break;
        case 'anime':
          rawDetail = await _api.animeDetail(urlId: item.id);
          break;
        case 'komik':
          rawDetail = await _api.komikDetail(mangaId: item.id);
          // Also fetch chapter list
          rawEpisodes = await _api.komikChapterList(mangaId: item.id)
              .catchError((_) => null);
          break;
        case 'moviebox':
          rawDetail = await _api.movieboxDetail(subjectId: item.id);
          break;
        default:
          throw Exception('Unknown platform: ${item.platform}');
      }

      // Parse detail
      _currentDetail = ContentParser.parseDetail(
        rawDetail,
        item.platform,
        item.type,
      );

      // Merge episodes from separate call if available
      if (rawEpisodes != null && _currentDetail != null) {
        final mergedDetail = _mergeEpisodesIntoDetail(
          _currentDetail!,
          rawEpisodes,
          item,
        );
        _currentDetail = mergedDetail;
      }

      _detailError = null;
    } catch (e) {
      _detailError = 'Failed to load details: $e';
    }

    _isDetailLoading = false;
    notifyListeners();
    return _currentDetail;
  }

  /// Merge separately-fetched episodes/chapters into a ContentDetail
  ContentDetail _mergeEpisodesIntoDetail(
    ContentDetail detail,
    dynamic rawEpisodes,
    ContentItem item,
  ) {
    if (item.type == ContentType.komik) {
      // Parse chapter list for komik
      final list = _extractRawList(rawEpisodes);
      final chapters = list.asMap().entries.map((entry) {
        final ch = entry.value;
        return Chapter(
          id: (ch['chapter_id'] ?? ch['id'] ?? '').toString(),
          title: (ch['title'] ?? ch['name'] ?? 'Chapter ${entry.key + 1}').toString(),
          number: ch['number'] ?? entry.key + 1,
          date: (ch['date'] ?? ch['created_at'] ?? '').toString(),
        );
      }).toList();

      return ContentDetail(
        item: detail.item,
        synopsis: detail.synopsis,
        tags: detail.tags,
        episodes: detail.episodes,
        chapters: chapters.isNotEmpty ? chapters : detail.chapters,
        totalEpisodes: detail.totalEpisodes,
        raw: detail.raw,
      );
    } else {
      // Parse episode list for video content
      final list = _extractRawList(rawEpisodes);
      final episodes = list.asMap().entries.map((entry) {
        final ep = entry.value;
        return Episode(
          number: ep['episodeNumber'] ?? ep['number'] ?? entry.key + 1,
          title: (ep['title'] ?? ep['name'] ?? 'Episode ${entry.key + 1}').toString(),
          streamUrl: (ep['streamUrl'] ?? ep['url'] ?? ep['videoUrl'] ?? '').toString(),
          thumbnail: (ep['cover'] ?? ep['thumbnail'] ?? '').toString(),
          raw: ep is Map<String, dynamic> ? ep : {},
        );
      }).toList();

      return ContentDetail(
        item: detail.item,
        synopsis: detail.synopsis,
        tags: detail.tags,
        episodes: episodes.isNotEmpty ? episodes : detail.episodes,
        chapters: detail.chapters,
        totalEpisodes: episodes.isNotEmpty ? episodes.length : detail.totalEpisodes,
        raw: detail.raw,
      );
    }
  }

  // ============================================================
  // STREAM URL — Resolve video stream for an episode
  // ============================================================

  Future<String?> fetchStreamUrl({
    required ContentItem item,
    required Episode episode,
  }) async {
    try {
      // If episode already has a direct stream URL, use it
      if (episode.streamUrl != null && episode.streamUrl!.isNotEmpty &&
          (episode.streamUrl!.startsWith('http') ||
           episode.streamUrl!.startsWith('//'))) {
        return episode.streamUrl;
      }

      switch (item.platform) {
        case 'dramabox':
        case 'shortmax':
        case 'netshort':
        case 'flickreels':
        case 'freereels':
          // These platforms return stream URLs in the episode list
          return episode.streamUrl;

        case 'reelshort':
          final data = await _api.reelshortEpisode(
            bookId: item.id,
            episodeNumber: episode.number,
          );
          return _extractStreamUrl(data);

        case 'melolo':
          // Melolo uses videoId from episode raw data
          final videoId = episode.raw['vid']?.toString() ??
              episode.raw['videoId']?.toString() ?? '';
          if (videoId.isNotEmpty) {
            final data = await _api.meloloStream(videoId: videoId);
            return _extractStreamUrl(data);
          }
          return null;

        case 'anime':
          // Anime uses chapterUrlId from episode raw data
          final chapterUrlId = episode.raw['url']?.toString() ??
              episode.raw['chapterUrlId']?.toString() ?? '';
          if (chapterUrlId.isNotEmpty) {
            final data = await _api.animeGetVideo(
              chapterUrlId: chapterUrlId,
              reso: '720p',
            );
            return _extractStreamUrl(data);
          }
          return null;

        case 'moviebox':
          // MovieBox: first get sources, then generate link
          final sourcesData = await _api.movieboxSources(
            subjectId: item.id,
            episode: episode.number,
          );
          final sourceUrl = _extractFirstSourceUrl(sourcesData);
          if (sourceUrl != null) {
            final linkData = await _api.movieboxGenerateLink(url: sourceUrl);
            return _extractStreamUrl(linkData);
          }
          return null;

        default:
          return episode.streamUrl;
      }
    } catch (e) {
      debugPrint('Error fetching stream URL: $e');
      return null;
    }
  }

  // ============================================================
  // KOMIK IMAGES — Fetch chapter images for reader
  // ============================================================

  Future<List<String>> fetchChapterImages(String chapterId) async {
    try {
      final data = await _api.komikGetImages(chapterId: chapterId);
      final list = _extractRawList(data);

      // Images could be list of strings or list of objects with url field
      return list.map((item) {
        if (item is String) return item;
        if (item is Map) {
          return (item['url'] ?? item['image'] ?? item['src'] ?? '').toString();
        }
        return item.toString();
      }).where((url) => url.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error fetching chapter images: $e');
      return [];
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _extractStreamUrl(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      // Try common URL keys
      for (final key in ['url', 'streamUrl', 'videoUrl', 'stream', 'link',
                          'result', 'data', 'src', 'source']) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;
        if (val is Map) {
          for (final k2 in ['url', 'streamUrl', 'videoUrl', 'link']) {
            if (val[k2] is String && val[k2].isNotEmpty) return val[k2];
          }
        }
      }
    }
    return null;
  }

  String? _extractFirstSourceUrl(dynamic data) {
    if (data is Map) {
      final result = data['result'] ?? data['data'] ?? data;
      if (result is Map) {
        final sources = result['sources'] ?? result['list'] ?? result['items'];
        if (sources is List && sources.isNotEmpty) {
          final first = sources.first;
          if (first is Map) {
            return (first['url'] ?? first['link'] ?? first['source'] ?? '').toString();
          }
          if (first is String) return first;
        }
      }
    }
    return null;
  }

  List<dynamic> _extractRawList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['result', 'data', 'list', 'items', 'results',
                          'chapters', 'chapterList', 'episodes', 'episodeList',
                          'images', 'imageList']) {
        if (data[key] is List) return data[key];
      }
      if (data['result'] is Map && data['result']['data'] is List) {
        return data['result']['data'];
      }
    }
    return [];
  }

  void clearDetail() {
    _currentDetail = null;
    _isDetailLoading = false;
    _detailError = null;
    notifyListeners();
  }

  void _setLoading(String key, bool value) {
    _loading[key] = value;
    notifyListeners();
  }

  void _setError(String key, String? value) {
    _errors[key] = value;
  }
}
