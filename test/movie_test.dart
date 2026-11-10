import 'package:cinema_booking_app/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _tmdbDetails({
  List<Map<String, dynamic>> videos = const [],
  List<Map<String, dynamic>> releaseDates = const [],
  String overview = 'Mô tả phim',
}) =>
    {
      'id': 1381071,
      'title': 'Godzilla Trừ Không',
      'runtime': 135,
      'vote_average': 7.96,
      'release_date': '2026-11-06',
      'overview': overview,
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'genres': [
        {'id': 878, 'name': 'Phim Khoa Học Viễn Tưởng'},
        {'id': 27, 'name': 'Phim Kinh Dị'},
      ],
      'credits': {
        'cast': [
          {'name': 'Kamiki Ryunosuke'},
          {'name': 'Hamabe Minami'},
        ],
        'crew': [
          {'name': 'Takashi Yamazaki', 'job': 'Director'},
          {'name': 'Someone Else', 'job': 'Writer'},
        ],
      },
      'videos': {'results': videos},
      'release_dates': {'results': releaseDates},
    };

void main() {
  group('Movie.fromTmdb', () {
    test('đọc đúng thông tin cơ bản', () {
      final m = Movie.fromTmdb(_tmdbDetails(), status: MovieStatus.nowShowing);

      expect(m.id, 'tmdb_1381071');
      expect(m.title, 'Godzilla Trừ Không');
      expect(m.durationText, '2h 15m');
      expect(m.rating, 8.0);
      expect(m.releaseDate, DateTime(2026, 11, 6));
      expect(m.genres, ['Khoa Học Viễn Tưởng', 'Kinh Dị']);
      expect(m.director, 'Takashi Yamazaki');
      expect(m.cast, ['Kamiki Ryunosuke', 'Hamabe Minami']);
      expect(m.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
      expect(m.backdropUrl, 'https://image.tmdb.org/t/p/w780/backdrop.jpg');
      expect(m.isNowShowing, isTrue);
    });

    test('ưu tiên trailer YouTube, bỏ qua featurette', () {
      final m = Movie.fromTmdb(
        _tmdbDetails(videos: [
          {'site': 'YouTube', 'type': 'Featurette', 'key': 'feat', 'iso_639_1': 'en'},
          {'site': 'Vimeo', 'type': 'Trailer', 'key': 'vimeo', 'iso_639_1': 'vi'},
          {'site': 'YouTube', 'type': 'Trailer', 'key': 'enTrailer', 'iso_639_1': 'en'},
          {'site': 'YouTube', 'type': 'Trailer', 'key': 'viTrailer', 'iso_639_1': 'vi'},
        ]),
        status: MovieStatus.nowShowing,
      );

      expect(m.trailerUrl, 'https://www.youtube.com/watch?v=viTrailer');
      expect(m.youtubeKey, 'viTrailer');
    });

    test('không có trailer thì trailerUrl = null', () {
      final m = Movie.fromTmdb(_tmdbDetails(), status: MovieStatus.comingSoon);
      expect(m.trailerUrl, isNull);
      expect(m.youtubeKey, isNull);
    });

    test('phân loại tuổi: ưu tiên Việt Nam, không có thì đổi từ Mỹ', () {
      Movie withDates(List<Map<String, dynamic>> dates) => Movie.fromTmdb(
            _tmdbDetails(releaseDates: dates),
            status: MovieStatus.nowShowing,
          );
      Map<String, dynamic> country(String code, String cert) => {
            'iso_3166_1': code,
            'release_dates': [
              {'certification': ''},
              {'certification': cert},
            ],
          };

      expect(withDates([country('US', 'R'), country('VN', 'T18')]).ageRating, 'T18');
      expect(withDates([country('US', 'PG-13'), country('VN', '')]).ageRating, 'T13');
      expect(withDates([country('US', 'R')]).ageRating, 'T16');
      expect(withDates([]).ageRating, 'P');
    });

    test('thiếu mô tả và đạo diễn thì hiện chữ thay thế', () {
      final json = _tmdbDetails(overview: '  ')..remove('credits');
      final m = Movie.fromTmdb(json, status: MovieStatus.comingSoon);

      expect(m.description, 'Nội dung phim đang được cập nhật.');
      expect(m.director, 'Đang cập nhật');
      expect(m.cast, isEmpty);
    });
  });

  test('youtubeKey đọc được link youtu.be', () {
    final m = Movie(
      id: 'x',
      title: 'x',
      genres: const [],
      durationMinutes: 90,
      ageRating: 'P',
      rating: 0,
      status: MovieStatus.nowShowing,
      releaseDate: DateTime(2026),
      director: '',
      cast: const [],
      description: '',
      trailerUrl: 'https://youtu.be/abc123',
    );
    expect(m.youtubeKey, 'abc123');
    expect(m.durationText, '1h 30m');
  });
}
