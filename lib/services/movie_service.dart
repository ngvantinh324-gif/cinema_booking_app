// Người phụ trách: Triết
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movie.dart';

class MovieService {
  MovieService._();
  static final MovieService instance = MovieService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Lấy danh sách phim từ bảng `movies`.
  /// REST: GET /rest/v1/movies?select=*&status=eq.now_showing&order=release_date.desc
  Future<List<Movie>> getMovies({MovieStatus? status}) async {
    var query = _db.from('movies').select();
    if (status != null) {
      query = query.eq(
        'status',
        status == MovieStatus.comingSoon ? 'coming_soon' : 'now_showing',
      );
    }
    final rows = await query.order('release_date', ascending: false);
    return rows.map(Movie.fromJson).toList();
  }

  /// REST: GET /rest/v1/movies?select=*&id=eq.<id>
  Future<Movie?> getMovieById(String id) async {
    final row = await _db.from('movies').select().eq('id', id).maybeSingle();
    return row == null ? null : Movie.fromJson(row);
  }
}
