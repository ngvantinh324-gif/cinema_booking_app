// Người phụ trách: Triết
import '../data/mock/mock_movies.dart';
import '../models/movie.dart';
import 'api_config.dart';

class MovieService {
  MovieService._();
  static final MovieService instance = MovieService._();

  /// GET /api/movies?status=now_showing|coming_soon
  Future<List<Movie>> getMovies({MovieStatus? status}) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(ApiConfig.mockDelay);
      if (status == null) return List<Movie>.of(mockMovies);
      return mockMovies.where((m) => m.status == status).toList();
    }
    // Giai đoạn 2: gọi http.get('${ApiConfig.baseUrl}/movies') rồi Movie.fromJson
    throw UnimplementedError('Chưa kết nối API phim');
  }

  /// GET /api/movies/:id
  Future<Movie?> getMovieById(String id) async {
    final movies = await getMovies();
    for (final m in movies) {
      if (m.id == id) return m;
    }
    return null;
  }
}
