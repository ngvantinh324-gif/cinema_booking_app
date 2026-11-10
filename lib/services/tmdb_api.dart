// Người phụ trách: Triết - gọi API The Movie Database (TMDB)
import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbException implements Exception {
  const TmdbException(this.message);

  final String message;

  @override
  String toString() => 'TmdbException: $message';
}

/// Client tối giản cho TMDB API v3.
///
/// Key KHÔNG nằm trong code. Truyền lúc chạy app:
///   flutter run --dart-define-from-file=tmdb.json
/// (tmdb.json đã có trong .gitignore, xem mẫu ở tmdb.example.json)
class TmdbApi {
  TmdbApi({http.Client? client}) : _client = client ?? http.Client();

  static const String apiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Chưa truyền key thì MovieService tự dùng dữ liệu mock.
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Dùng api.tmdb.org vì api.themoviedb.org bị nhà mạng ở Việt Nam chặn.
  static const String _host = 'api.tmdb.org';
  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String> query = const {},
    String language = 'vi-VN',
  }) async {
    final uri = Uri.https(_host, '/3$path', {
      'api_key': apiKey,
      'language': language,
      ...query,
    });
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw TmdbException('HTTP ${res.statusCode} khi gọi $path');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Danh sách phim (đang chiếu / sắp chiếu) tại rạp Việt Nam.
  Future<List<Map<String, dynamic>>> movieList(String type) async {
    final json = await get('/movie/$type', query: {'region': 'VN', 'page': '1'});
    return List<Map<String, dynamic>>.from(json['results'] as List? ?? const []);
  }

  /// Chi tiết 1 phim kèm đạo diễn/diễn viên, trailer và phân loại độ tuổi.
  Future<Map<String, dynamic>> movieDetails(int id) async {
    final details = await get('/movie/$id', query: {
      'append_to_response': 'credits,videos,release_dates',
      'include_video_language': 'vi,en',
    });
    // Nhiều phim chưa có mô tả tiếng Việt -> lấy bản tiếng Anh thay thế
    if ((details['overview'] as String? ?? '').trim().isEmpty) {
      try {
        final en = await get('/movie/$id', language: 'en-US');
        details['overview'] = en['overview'];
      } catch (_) {
        // Không có mô tả thì thôi, màn hình tự hiện chữ thay thế
      }
    }
    return details;
  }
}
