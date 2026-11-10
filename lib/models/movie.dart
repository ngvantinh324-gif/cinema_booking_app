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
  final String? posterUrl;
  final List<Color> posterColors;
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
    this.posterColors = const [Color(0xFF2C3E50), Color(0xFF000000)],
    this.emoji = '🎬',
  });

  bool get isNowShowing => status == MovieStatus.nowShowing;

  String get durationText =>
      '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m';

  String get genreText => genres.join(', ');

  /// Getter tương thích ngược cho movie_poster và movie_detail_screen
  String get backdropUrl => posterUrl ?? '';
  String? get youtubeKey => trailerUrl;

  /// Chuyển một dòng của bảng `movies` (Supabase trả về JSON) thành Movie.
  factory Movie.fromJson(Map<String, dynamic> json) {
    final colors = (json['poster_colors'] as List? ?? const [])
        .map((h) => _parseHex(h.toString()))
        .toList();
    return Movie(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      genres: List<String>.from(json['genres'] as List? ?? const []),
      durationMinutes: (json['duration'] as num?)?.toInt() ?? 0,
      ageRating: json['age_rating'] as String? ?? 'P',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      status: json['status'] == 'coming_soon'
          ? MovieStatus.comingSoon
          : MovieStatus.nowShowing,
      releaseDate: DateTime.tryParse(json['release_date']?.toString() ?? '') ??
          DateTime.now(),
      director: json['director'] as String? ?? '',
      cast: List<String>.from(
        json['actors'] as List? ?? json['cast'] as List? ?? const [],
      ),
      description: json['description'] as String? ?? '',
      trailerUrl: json['trailer'] as String?,
      posterUrl: json['poster'] as String?,
      posterColors: colors.length >= 2
          ? colors
          : const [Color(0xFF2C3E50), Color(0xFF000000)],
      emoji: json['emoji'] as String? ?? '🎬',
    );
  }

  /// Hàm tương thích ngược cho unit test cũ (test/movie_test.dart)
  factory Movie.fromTmdb(
    Map<String, dynamic> json, {
    String? youtubeKey,
    MovieStatus status = MovieStatus.nowShowing,
  }) {
    final movie = Movie.fromJson(json);
    return Movie(
      id: movie.id,
      title: movie.title,
      genres: movie.genres,
      durationMinutes: movie.durationMinutes,
      ageRating: movie.ageRating,
      rating: movie.rating,
      status: status,
      releaseDate: movie.releaseDate,
      director: movie.director,
      cast: movie.cast,
      description: movie.description,
      trailerUrl: youtubeKey ?? movie.trailerUrl,
      posterUrl: movie.posterUrl,
      posterColors: movie.posterColors,
      emoji: movie.emoji,
    );
  }

  /// "#D35400" -> Color(0xFFD35400)
  static Color _parseHex(String hex) =>
      Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
}