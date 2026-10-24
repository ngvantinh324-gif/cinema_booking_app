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
    this.posterColors = const [Color(0xFF2C3E50), Color(0xFF000000)],
    this.emoji = '🎬',
  });

  bool get isNowShowing => status == MovieStatus.nowShowing;

  String get durationText =>
      '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m';

  String get genreText => genres.join(', ');

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
