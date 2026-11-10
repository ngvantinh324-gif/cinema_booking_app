// Người phụ trách: Triết
import 'package:flutter/material.dart';

enum MovieStatus { nowShowing, comingSoon }

class Movie {
  final String id;
  final String title;
  final List<String> genres;
  final int durationMinutes;
  final String ageRating; // P, T13, T16, T18
  final double rating;
  final MovieStatus status;
  final DateTime releaseDate;
  final String director;
  final List<String> cast;
  final String description;
  final String? trailerUrl;
  final String? posterUrl; // Giai đoạn 2: ảnh thật từ API
  final String? backdropUrl; // Ảnh ngang dùng cho banner
  final List<Color> posterColors; // Giai đoạn 1: poster giả lập bằng gradient
  final String emoji;

  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.durationMinutes,
    required this.ageRating,
    required this.rating,
    required this.status,
    required this.releaseDate,
    required this.director,
    required this.cast,
    required this.description,
    this.trailerUrl,
    this.posterUrl,
    this.backdropUrl,
    this.posterColors = const [Color(0xFF2C3E50), Color(0xFF000000)],
    this.emoji = '🎬',
  });

  bool get isNowShowing => status == MovieStatus.nowShowing;

  String get durationText => durationMinutes <= 0
      ? 'Đang cập nhật'
      : '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m';

  String get genreText => genres.join(', ');

  /// Mã video YouTube nếu trailerUrl là link YouTube (dùng làm ảnh thu nhỏ)
  String? get youtubeKey {
    final uri = Uri.tryParse(trailerUrl ?? '');
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
    return null;
  }

  /// Dữ liệu từ TMDB: GET /movie/{id}?append_to_response=credits,videos,release_dates
  factory Movie.fromTmdb(
    Map<String, dynamic> json, {
    required MovieStatus status,
  }) {
    final tmdbId = json['id'] as int? ?? 0;

    final genres = (json['genres'] as List? ?? const [])
        .map((g) => (g as Map)['name'] as String? ?? '')
        .map((name) => name.replaceFirst(RegExp(r'^Phim\s+'), ''))
        .where((name) => name.isNotEmpty)
        .toList();

    final credits = json['credits'] as Map? ?? const {};
    final directors = (credits['crew'] as List? ?? const [])
        .cast<Map>()
        .where((c) => c['job'] == 'Director')
        .map((c) => c['name'] as String)
        .toList();
    final cast = (credits['cast'] as List? ?? const [])
        .cast<Map>()
        .take(8)
        .map((c) => c['name'] as String)
        .toList();

    final overview = (json['overview'] as String? ?? '').trim();
    final vote = (json['vote_average'] as num?)?.toDouble() ?? 0;

    return Movie(
      id: 'tmdb_$tmdbId',
      title: json['title'] as String? ?? '',
      genres: genres,
      durationMinutes: json['runtime'] as int? ?? 0,
      ageRating: _ageRatingFromTmdb(json['release_dates'] as Map?),
      rating: (vote * 10).round() / 10,
      status: status,
      releaseDate: DateTime.tryParse(json['release_date'] as String? ?? '') ??
          DateTime.now(),
      director: directors.isEmpty ? 'Đang cập nhật' : directors.join(', '),
      cast: cast,
      description:
          overview.isEmpty ? 'Nội dung phim đang được cập nhật.' : overview,
      trailerUrl: _trailerFromTmdb(json['videos'] as Map?),
      posterUrl: _imageUrl(json['poster_path'], 'w500'),
      backdropUrl: _imageUrl(json['backdrop_path'], 'w780'),
      posterColors: _fallbackColors[tmdbId % _fallbackColors.length],
    );
  }

  static String? _imageUrl(Object? path, String size) {
    if (path is! String || path.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  /// Ưu tiên trailer tiếng Việt, rồi trailer tiếng Anh, rồi teaser trên YouTube
  static String? _trailerFromTmdb(Map? videos) {
    final list = (videos?['results'] as List? ?? const [])
        .cast<Map>()
        .where((v) => v['site'] == 'YouTube' && v['key'] is String)
        .toList();
    int score(Map v) =>
        (v['type'] == 'Trailer' ? 0 : v['type'] == 'Teaser' ? 2 : 4) +
        (v['iso_639_1'] == 'vi' ? 0 : 1);
    list.sort((a, b) => score(a).compareTo(score(b)));
    if (list.isEmpty) return null;
    return 'https://www.youtube.com/watch?v=${list.first['key']}';
  }

  /// Lấy phân loại Việt Nam (P, K, T13, T16, T18) nếu có, không thì quy đổi từ Mỹ
  static String _ageRatingFromTmdb(Map? releaseDates) {
    final results = (releaseDates?['results'] as List? ?? const []).cast<Map>();
    String? certOf(String country) {
      for (final r in results) {
        if (r['iso_3166_1'] != country) continue;
        for (final d in (r['release_dates'] as List? ?? const []).cast<Map>()) {
          final c = (d['certification'] as String? ?? '').trim();
          if (c.isNotEmpty) return c;
        }
      }
      return null;
    }

    final vn = certOf('VN')?.toUpperCase();
    if (vn != null && const ['P', 'K', 'T13', 'T16', 'T18'].contains(vn)) {
      return vn;
    }
    return switch (certOf('US')) {
      'G' => 'P',
      'PG' => 'K',
      'PG-13' => 'T13',
      'R' => 'T16',
      'NC-17' => 'T18',
      _ => 'P',
    };
  }

  static const List<List<Color>> _fallbackColors = [
    [Color(0xFF2C3E50), Color(0xFF000000)],
    [Color(0xFF243B55), Color(0xFF141E30)],
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    [Color(0xFFD35400), Color(0xFF2B0F0A)],
    [Color(0xFF134E5E), Color(0xFF71B280)],
  ];

  /// Dùng ở giai đoạn 2 khi nhận JSON từ GET /api/movies
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      genres: List<String>.from(json['genres'] as List? ?? const []),
      durationMinutes: json['duration'] as int? ?? 0,
      ageRating: json['age_rating'] as String? ?? 'P',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      status: json['status'] == 'coming_soon'
          ? MovieStatus.comingSoon
          : MovieStatus.nowShowing,
      releaseDate: DateTime.tryParse(json['release_date']?.toString() ?? '') ??
          DateTime.now(),
      director: json['director'] as String? ?? '',
      cast: List<String>.from(json['cast'] as List? ?? const []),
      description: json['description'] as String? ?? '',
      trailerUrl: json['trailer'] as String?,
      posterUrl: json['poster'] as String?,
    );
  }
}
