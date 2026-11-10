// Người phụ trách: Triết
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';

class MovieService {
  // Singleton instance phục vụ tương thích cho home_screen
  static final MovieService instance = MovieService();

  final SupabaseClient _supabase = Supabase.instance.client;

  MovieService();

  /// Lấy danh sách phim đang chiếu từ bảng `movies`.
  Future<List<Movie>> getNowShowing({bool forceRefresh = false}) async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('status', 'now_showing')
        .order('release_date', ascending: false);
    return (response as List).map((json) => Movie.fromJson(json)).toList();
  }

  /// Lấy danh sách phim sắp chiếu từ bảng `movies`.
  Future<List<Movie>> getComingSoon({bool forceRefresh = false}) async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('status', 'coming_soon')
        .order('release_date', ascending: true);
    return (response as List).map((json) => Movie.fromJson(json)).toList();
  }

  /// Lấy tất cả phim từ bảng `movies`.
  Future<List<Movie>> getMovies({bool forceRefresh = false}) async {
    final response = await _supabase
        .from('movies')
        .select()
        .order('release_date', ascending: false);
    return (response as List).map((json) => Movie.fromJson(json)).toList();
  }

  /// Lấy thông tin chi tiết một phim theo id từ bảng `movies`.
  Future<Movie?> getMovieById(String id) async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Movie.fromJson(response);
  }
}