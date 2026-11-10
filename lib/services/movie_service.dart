// Người phụ trách: Triết
import 'package:flutter/foundation.dart';

import '../data/mock/mock_movies.dart';
import '../models/movie.dart';
import 'api_config.dart';
import 'tmdb_api.dart';

class MovieService {
  MovieService._();
  static final MovieService instance = MovieService._();

  /// Số phim lấy về mỗi tab (mỗi phim tốn 1 request chi tiết)
  static const int _maxNowShowing = 12;
  static const int _maxComingSoon = 10;
  static const Duration _cacheTtl = Duration(minutes: 10);

  final TmdbApi _tmdb = TmdbApi();
  List<Movie>? _cache;
  DateTime? _cachedAt;

  /// Có key TMDB -> phim thật đang chiếu / sắp chiếu tại Việt Nam.
  /// Không có key hoặc lỗi mạng -> dùng dữ liệu mock để app vẫn chạy được.
  Future<List<Movie>> getMovies({
    MovieStatus? status,
    bool forceRefresh = false,
  }) async {
    final all = await _loadAll(forceRefresh: forceRefresh);
    if (status == null) return List<Movie>.of(all);
    return all.where((m) => m.status == status).toList();
  }

  /// Tìm phim theo id (dùng cache, không gọi lại API)
  Future<Movie?> getMovieById(String id) async {
    final movies = await getMovies();
    for (final m in movies) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<List<Movie>> _loadAll({required bool forceRefresh}) async {
    final cache = _cache;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cache;
    }

    if (TmdbApi.isConfigured) {
      try {
        final movies = await _loadFromTmdb();
        if (movies.isNotEmpty) {
          _cache = movies;
          _cachedAt = DateTime.now();
          return movies;
        }
      } catch (e) {
        debugPrint('Không tải được phim từ TMDB, dùng dữ liệu mock: $e');
      }
    }

    if (ApiConfig.useMockData || TmdbApi.isConfigured) {
      await Future.delayed(ApiConfig.mockDelay);
      return List<Movie>.of(mockMovies);
    }
    throw UnimplementedError('Chưa kết nối API phim');
  }

  Future<List<Movie>> _loadFromTmdb() async {
    final lists = await Future.wait([
      _tmdb.movieList('now_playing'),
      _tmdb.movieList('upcoming'),
    ]);

    final nowIds =
        lists[0].map((m) => m['id'] as int).take(_maxNowShowing).toList();
    final soonIds = lists[1]
        .map((m) => m['id'] as int)
        .where((id) => !nowIds.contains(id))
        .take(_maxComingSoon)
        .toList();

    final results = await Future.wait([
      for (final id in nowIds) _detailsOrNull(id, MovieStatus.nowShowing),
      for (final id in soonIds) _detailsOrNull(id, MovieStatus.comingSoon),
    ]);
    final movies = results.whereType<Movie>().toList();

    // Sắp chiếu: phim ra rạp sớm nhất lên trước
    final comingSoon = movies.where((m) => !m.isNowShowing).toList()
      ..sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    return [...movies.where((m) => m.isNowShowing), ...comingSoon];
  }

  /// Lỗi 1 phim thì bỏ qua phim đó, không làm hỏng cả danh sách
  Future<Movie?> _detailsOrNull(int id, MovieStatus status) async {
    try {
      final json = await _tmdb.movieDetails(id);
      return Movie.fromTmdb(json, status: status);
    } catch (e) {
      debugPrint('Bỏ qua phim TMDB $id: $e');
      return null;
    }
  }
}
