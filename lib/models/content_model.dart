/// Universal content model that represents drama, anime, movie, or komik
/// across all platforms (DramaBox, ReelShort, ShortMax, etc.)
class ContentItem {
  final String id;
  final String title;
  final String? cover;
  final String? description;
  final String? genre;
  final String? rating;
  final String platform; // dramabox, reelshort, shortmax, etc.
  final ContentType type; // drama, anime, komik, movie
  final Map<String, dynamic> raw; // raw API response for platform-specific fields

  ContentItem({
    required this.id,
    required this.title,
    this.cover,
    this.description,
    this.genre,
    this.rating,
    required this.platform,
    required this.type,
    this.raw = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cover': cover,
    'description': description,
    'genre': genre,
    'rating': rating,
    'platform': platform,
    'type': type.name,
    'raw': raw,
  };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    cover: json['cover'],
    description: json['description'],
    genre: json['genre'],
    rating: json['rating'],
    platform: json['platform'] ?? '',
    type: ContentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ContentType.drama,
    ),
    raw: json['raw'] ?? {},
  );
}

enum ContentType { drama, anime, komik, movie }

/// Episode model for drama/anime/movie
class Episode {
  final int number;
  final String? title;
  final String? streamUrl;
  final String? thumbnail;
  final Map<String, dynamic> raw;

  Episode({
    required this.number,
    this.title,
    this.streamUrl,
    this.thumbnail,
    this.raw = const {},
  });
}

/// Chapter model for komik
class Chapter {
  final String id;
  final String title;
  final int? number;
  final String? date;

  Chapter({
    required this.id,
    required this.title,
    this.number,
    this.date,
  });
}

/// Detail model — extended info for a content item
class ContentDetail {
  final ContentItem item;
  final String? synopsis;
  final List<String>? tags;
  final List<Episode>? episodes;
  final List<Chapter>? chapters;
  final int? totalEpisodes;
  final Map<String, dynamic> raw;

  ContentDetail({
    required this.item,
    this.synopsis,
    this.tags,
    this.episodes,
    this.chapters,
    this.totalEpisodes,
    this.raw = const {},
  });
}

/// Download item model
class DownloadItem {
  final String id;
  final String contentId;
  final String title;
  final String? cover;
  final String platform;
  final ContentType type;
  final int? episodeNumber;
  final String? chapterId;
  final String localPath;
  final double progress; // 0.0 - 1.0
  final DownloadStatus status;
  final DateTime createdAt;

  DownloadItem({
    required this.id,
    required this.contentId,
    required this.title,
    this.cover,
    required this.platform,
    required this.type,
    this.episodeNumber,
    this.chapterId,
    required this.localPath,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'contentId': contentId,
    'title': title,
    'cover': cover,
    'platform': platform,
    'type': type.name,
    'episodeNumber': episodeNumber,
    'chapterId': chapterId,
    'localPath': localPath,
    'progress': progress,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    id: json['id'] ?? '',
    contentId: json['contentId'] ?? '',
    title: json['title'] ?? '',
    cover: json['cover'],
    platform: json['platform'] ?? '',
    type: ContentType.values.firstWhere(
      (e) => e.name == json['type'], orElse: () => ContentType.drama),
    episodeNumber: json['episodeNumber'],
    chapterId: json['chapterId'],
    localPath: json['localPath'] ?? '',
    progress: (json['progress'] ?? 0.0).toDouble(),
    status: DownloadStatus.values.firstWhere(
      (e) => e.name == json['status'], orElse: () => DownloadStatus.pending),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );
}

enum DownloadStatus { pending, downloading, completed, failed, paused }

/// Bookmark model
class Bookmark {
  final String contentId;
  final String title;
  final String? cover;
  final String platform;
  final ContentType type;
  final DateTime createdAt;

  Bookmark({
    required this.contentId,
    required this.title,
    this.cover,
    required this.platform,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'title': title,
    'cover': cover,
    'platform': platform,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    contentId: json['contentId'],
    title: json['title'],
    cover: json['cover'],
    platform: json['platform'],
    type: ContentType.values.firstWhere((e) => e.name == json['type']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Watch/Read history
class HistoryItem {
  final String contentId;
  final String title;
  final String? cover;
  final String platform;
  final ContentType type;
  final int? lastEpisode;
  final String? lastChapterId;
  final double progress; // 0.0 - 1.0 for video position
  final DateTime updatedAt;

  HistoryItem({
    required this.contentId,
    required this.title,
    this.cover,
    required this.platform,
    required this.type,
    this.lastEpisode,
    this.lastChapterId,
    this.progress = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'title': title,
    'cover': cover,
    'platform': platform,
    'type': type.name,
    'lastEpisode': lastEpisode,
    'lastChapterId': lastChapterId,
    'progress': progress,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    contentId: json['contentId'],
    title: json['title'],
    cover: json['cover'],
    platform: json['platform'],
    type: ContentType.values.firstWhere((e) => e.name == json['type']),
    lastEpisode: json['lastEpisode'],
    lastChapterId: json['lastChapterId'],
    progress: (json['progress'] ?? 0.0).toDouble(),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
