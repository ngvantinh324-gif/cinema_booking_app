// Người phụ trách: Khôi
import 'booking_data.dart';
import 'combo.dart';
import 'movie.dart';
import 'seat.dart';
import 'showtime.dart';

class Ticket {
  final String id;
  final String userId;
  final Movie movie;
  final Showtime showtime;
  final List<BookedSeat> seats;
  final List<SelectedCombo> combos;
  final int totalPaid;
  final String paymentMethod;
  final DateTime bookedAt;

  const Ticket({
    required this.id,
    required this.userId,
    required this.movie,
    required this.showtime,
    required this.seats,
    required this.combos,
    required this.totalPaid,
    required this.paymentMethod,
    required this.bookedAt,
  });

  bool get isUpcoming => showtime.startTime.isAfter(DateTime.now());

  /// Nhãn đếm ngược tới giờ chiếu, tính theo giờ thực của máy
  String get countdownLabel {
    final diff = showtime.startTime.difference(DateTime.now());
    if (diff.isNegative) return 'Đã chiếu';
    if (diff.inDays >= 1) {
      return 'Còn ${diff.inDays} ngày ${diff.inHours % 24} giờ';
    }
    if (diff.inHours >= 1) {
      return 'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút';
    }
    return 'Còn ${diff.inMinutes} phút';
  }

  String get seatLabel => seats.map((s) => s.id).join(', ');

  String get comboLabel =>
      combos.map((c) => '${c.quantity}x ${c.combo.name}').join(', ');

  /// Nội dung mã QR để nhân viên soát vé quét
  String get qrData =>
      'CINEGO|$id|${showtime.id}|${seats.map((s) => s.id).join('-')}';

  // ------------------------------------------------------------------
  // Chuyển đổi JSON để lưu vé vào cột `data` (jsonb) của bảng tickets
  // ------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_method': paymentMethod,
        'booked_at': bookedAt.toIso8601String(),
        'total': totalPaid,
        'movie': _movieToJson(movie),
        'showtime': {
          'id': showtime.id,
          'movie_id': showtime.movieId,
          'room': showtime.room,
          'start_time': showtime.startTime.toIso8601String(),
          'format': showtime.format,
          'base_price': showtime.basePrice,
          'cinema': {
            'id': showtime.cinema.id,
            'name': showtime.cinema.name,
            'address': showtime.cinema.address,
          },
        },
        'seats': [
          for (final s in seats)
            {'id': s.id, 'type': s.type.name, 'price': s.price},
        ],
        'combos': [
          for (final c in combos)
            {
              'id': c.combo.id,
              'name': c.combo.name,
              'description': c.combo.description,
              'price': c.combo.price,
              'emoji': c.combo.emoji,
              'quantity': c.quantity,
            },
        ],
      };

  factory Ticket.fromJson(Map<String, dynamic> json, {required String userId}) {
    final st = json['showtime'] as Map<String, dynamic>;
    final cinema = st['cinema'] as Map<String, dynamic>;
    return Ticket(
      id: json['id'] as String,
      userId: userId,
      movie: Movie.fromJson(json['movie'] as Map<String, dynamic>),
      showtime: Showtime(
        id: st['id'] as String,
        movieId: st['movie_id'] as String,
        cinema: Cinema(
          id: cinema['id'] as String,
          name: cinema['name'] as String,
          address: cinema['address'] as String,
        ),
        room: st['room'] as String,
        startTime: DateTime.parse(st['start_time'] as String),
        format: st['format'] as String,
        basePrice: (st['base_price'] as num).toInt(),
      ),
      seats: [
        for (final s in json['seats'] as List)
          BookedSeat(
            id: s['id'] as String,
            type: SeatType.values.byName(s['type'] as String),
            price: (s['price'] as num).toInt(),
          ),
      ],
      combos: [
        for (final c in json['combos'] as List)
          SelectedCombo(
            Combo(
              id: c['id'] as String,
              name: c['name'] as String,
              description: c['description'] as String? ?? '',
              price: (c['price'] as num).toInt(),
              emoji: c['emoji'] as String? ?? '🍿',
            ),
            (c['quantity'] as num).toInt(),
          ),
      ],
      totalPaid: (json['total'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? '',
      bookedAt: DateTime.parse(json['booked_at'] as String),
    );
  }
}

/// Lưu kèm thông tin phim vào vé (cùng định dạng với bảng movies)
Map<String, dynamic> _movieToJson(Movie m) => {
      'id': m.id,
      'title': m.title,
      'genres': m.genres,
      'duration': m.durationMinutes,
      'age_rating': m.ageRating,
      'rating': m.rating,
      'status': m.isNowShowing ? 'now_showing' : 'coming_soon',
      'release_date': m.releaseDate.toIso8601String(),
      'director': m.director,
      'actors': m.cast,
      'description': m.description,
      'trailer': m.trailerUrl,
      'poster': m.posterUrl,
      'poster_colors': [
        for (final c in m.posterColors)
          '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      ],
      'emoji': m.emoji,
    };
