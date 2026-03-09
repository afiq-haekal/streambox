import 'package:dio/dio.dart';

/// Core API service — handles all 63 Sansekai API endpoints
class ApiService {
  static const String baseUrl = 'https://api.sansekai.my.id/api';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ============================================================
  // 1. DRAMABOX (10 endpoints)
  // ============================================================

  /// Get recommended dramas (For You)
  Future<dynamic> dramaboxForYou({int page = 1}) =>
      _get('/dramabox/foryou', params: {'page': page});

  /// Get VIP dramas
  Future<dynamic> dramaboxVip() => _get('/dramabox/vip');

  /// Get Indonesian dubbed dramas
  /// [classify] - "terpopuler" or "terbaru"
  Future<dynamic> dramaboxDubIndo({required String classify, int? page}) =>
      _get('/dramabox/dubindo', params: {
        'classify': classify,
        if (page != null) 'page': page,
      });

  /// Get random drama video
  Future<dynamic> dramaboxRandom() => _get('/dramabox/randomdrama');

  /// Get latest dramas
  Future<dynamic> dramaboxLatest() => _get('/dramabox/latest');

  /// Get trending dramas
  Future<dynamic> dramaboxTrending() => _get('/dramabox/trending');

  /// Get popular search keywords
  Future<dynamic> dramaboxPopularSearch() => _get('/dramabox/populersearch');

  /// Search dramas
  Future<dynamic> dramaboxSearch({required String query}) =>
      _get('/dramabox/search', params: {'query': query});

  /// Get drama detail
  Future<dynamic> dramaboxDetail({required String bookId}) =>
      _get('/dramabox/detail', params: {'bookId': bookId});

  /// Get all episodes with streaming links (may be slow)
  Future<dynamic> dramaboxAllEpisodes({required String bookId}) =>
      _get('/dramabox/allepisode', params: {'bookId': bookId});

  // ============================================================
  // 2. REELSHORT (5 endpoints)
  // ============================================================

  Future<dynamic> reelshortForYou({int page = 1}) =>
      _get('/reelshort/foryou', params: {'page': page});

  Future<dynamic> reelshortHomepage() => _get('/reelshort/homepage');

  Future<dynamic> reelshortSearch({required String query, int page = 1}) =>
      _get('/reelshort/search', params: {'query': query, 'page': page});

  Future<dynamic> reelshortDetail({required String bookId}) =>
      _get('/reelshort/detail', params: {'bookId': bookId});

  Future<dynamic> reelshortEpisode({
    required String bookId,
    required int episodeNumber,
  }) =>
      _get('/reelshort/episode', params: {
        'bookId': bookId,
        'episodeNumber': episodeNumber,
      });

  // ============================================================
  // 3. SHORTMAX (7 endpoints)
  // ============================================================

  Future<dynamic> shortmaxForYou({int page = 1}) =>
      _get('/shortmax/foryou', params: {'page': page});

  Future<dynamic> shortmaxLatest() => _get('/shortmax/latest');

  Future<dynamic> shortmaxRekomendasi() => _get('/shortmax/rekomendasi');

  Future<dynamic> shortmaxVip() => _get('/shortmax/vip');

  Future<dynamic> shortmaxSearch({required String query}) =>
      _get('/shortmax/search', params: {'query': query});

  Future<dynamic> shortmaxDetail({required String shortPlayId}) =>
      _get('/shortmax/detail', params: {'shortPlayId': shortPlayId});

  Future<dynamic> shortmaxAllEpisodes({required String shortPlayId}) =>
      _get('/shortmax/allepisode', params: {'shortPlayId': shortPlayId});

  // ============================================================
  // 4. NETSHORT (4 endpoints)
  // ============================================================

  Future<dynamic> netshortForYou({int? page}) =>
      _get('/netshort/foryou', params: {if (page != null) 'page': page});

  Future<dynamic> netshortTheaters() => _get('/netshort/theaters');

  Future<dynamic> netshortSearch({required String query}) =>
      _get('/netshort/search', params: {'query': query});

  Future<dynamic> netshortAllEpisodes({required String shortPlayId}) =>
      _get('/netshort/allepisode', params: {'shortPlayId': shortPlayId});

  // ============================================================
  // 5. MELOLO (6 endpoints)
  // ============================================================

  Future<dynamic> meloloForYou({int offset = 20}) =>
      _get('/melolo/foryou', params: {'offset': offset});

  Future<dynamic> meloloLatest() => _get('/melolo/latest');

  Future<dynamic> meloloTrending() => _get('/melolo/trending');

  Future<dynamic> meloloSearch({
    required String query,
    int limit = 10,
    int offset = 0,
  }) =>
      _get('/melolo/search', params: {
        'query': query,
        'limit': limit,
        'offset': offset,
      });

  Future<dynamic> meloloDetail({required String bookId}) =>
      _get('/melolo/detail', params: {'bookId': bookId});

  /// Get stream URL — videoId from /melolo/detail "vid" property
  Future<dynamic> meloloStream({required String videoId}) =>
      _get('/melolo/stream', params: {'videoId': videoId});

  // ============================================================
  // 6. FLICKREELS (5 endpoints)
  // ============================================================

  Future<dynamic> flickreelsForYou({int page = 1}) =>
      _get('/flickreels/foryou', params: {'page': page});

  Future<dynamic> flickreelsLatest() => _get('/flickreels/latest');

  Future<dynamic> flickreelsHotRank() => _get('/flickreels/hotrank');

  Future<dynamic> flickreelsSearch({required String query}) =>
      _get('/flickreels/search', params: {'query': query});

  /// Get detail + all episodes in one call
  Future<dynamic> flickreelsDetailAndEpisodes({required String id}) =>
      _get('/flickreels/detailAndAllEpisode', params: {'id': id});

  // ============================================================
  // 7. FREEREELS (5 endpoints)
  // ============================================================

  Future<dynamic> freereelsForYou({int offset = 20}) =>
      _get('/freereels/foryou', params: {'offset': offset});

  Future<dynamic> freereelsHomepage() => _get('/freereels/homepage');

  Future<dynamic> freereelsAnimePage() => _get('/freereels/animepage');

  Future<dynamic> freereelsSearch({required String query}) =>
      _get('/freereels/search', params: {'query': query});

  /// Get detail + all episodes in one call
  Future<dynamic> freereelsDetailAndEpisodes({required String key}) =>
      _get('/freereels/detailAndAllEpisode', params: {'key': key});

  // ============================================================
  // 8. ANIME (6 endpoints)
  // ============================================================

  Future<dynamic> animeLatest() => _get('/anime/latest');

  Future<dynamic> animeRecommended({int page = 1}) =>
      _get('/anime/recommended', params: {'page': page});

  Future<dynamic> animeSearch({required String query}) =>
      _get('/anime/search', params: {'query': query});

  Future<dynamic> animeDetail({required String urlId}) =>
      _get('/anime/detail', params: {'urlId': urlId});

  Future<dynamic> animeMovie() => _get('/anime/movie');

  /// Get video stream — chapterUrlId from /anime/search chapter[].url
  Future<dynamic> animeGetVideo({
    required String chapterUrlId,
    String reso = '480p',
  }) =>
      _get('/anime/getvideo', params: {
        'chapterUrlId': chapterUrlId,
        'reso': reso,
      });

  // ============================================================
  // 9. KOMIK (7 endpoints)
  // ============================================================

  /// [type] - manhwa, manhua, or manga
  Future<dynamic> komikRecommended({required String type}) =>
      _get('/komik/recommended', params: {'type': type});

  /// [type] - project or mirror
  Future<dynamic> komikLatest({required String type}) =>
      _get('/komik/latest', params: {'type': type});

  Future<dynamic> komikSearch({required String query}) =>
      _get('/komik/search', params: {'query': query});

  Future<dynamic> komikPopular({int? page}) =>
      _get('/komik/popular', params: {if (page != null) 'page': page});

  Future<dynamic> komikDetail({required String mangaId}) =>
      _get('/komik/detail', params: {'manga_id': mangaId});

  Future<dynamic> komikChapterList({required String mangaId}) =>
      _get('/komik/chapterlist', params: {'manga_id': mangaId});

  /// Get chapter images — chapter_id from /komik/chapterlist
  Future<dynamic> komikGetImages({required String chapterId}) =>
      _get('/komik/getimage', params: {'chapter_id': chapterId});

  // ============================================================
  // 10. MOVIEBOX (6 endpoints)
  // ============================================================

  Future<dynamic> movieboxHomepage() => _get('/moviebox/homepage');

  Future<dynamic> movieboxTrending({int page = 0}) =>
      _get('/moviebox/trending', params: {'page': page});

  Future<dynamic> movieboxSearch({required String query, int page = 1}) =>
      _get('/moviebox/search', params: {'query': query, 'page': page});

  Future<dynamic> movieboxDetail({required String subjectId}) =>
      _get('/moviebox/detail', params: {'subjectId': subjectId});

  /// Get download/stream sources
  Future<dynamic> movieboxSources({
    required String subjectId,
    int season = 0,
    int episode = 0,
  }) =>
      _get('/moviebox/sources', params: {
        'subjectId': subjectId,
        'season': season,
        'episode': episode,
      });

  /// Generate final stream/download URL from sources result
  Future<dynamic> movieboxGenerateLink({required String url}) =>
      _get('/moviebox/generate-link-stream-video', params: {'url': url});

  // ============================================================
  // 11. AI (1 endpoint)
  // ============================================================

  Future<dynamic> aiChatGpt({required String prompt}) =>
      _get('/ai/chatgpt', params: {'prompt': prompt});

  // ============================================================
  // 12. UPLOADER (1 endpoint)
  // ============================================================

  Future<dynamic> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    try {
      final response = await _dio.post('/uploader', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Upload failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
