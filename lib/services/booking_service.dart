// Người phụ trách: Tính (Nhóm trưởng) - lịch chiếu & sơ đồ ghế
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock/mock_cinemas.dart';
import '../models/seat.dart';
import '../models/showtime.dart';

class SeatConflictException implements Exception {
  final List<String> seatIds;

  const SeatConflictException(this.seatIds);

  @override
  String toString() => 'Ghế ${seatIds.join(', ')} đã có người đặt';
}

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  SupabaseClient get _db => Supabase.instance.client;

  static const List<String> _normalRows = ['A', 'B', 'C', 'D'];
  static const List<String> _vipRows = ['E', 'F', 'G'];
  static const String _coupleRow = 'H';
  static const int seatsPerRow = 10;
  static const int coupleSeats = 5;

  /// Lịch chiếu được sinh tự động theo ngày (7 ngày tới, theo giờ thiết bị).
  Future<List<Showtime>> getShowtimes(String movieId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return generateMockShowtimes(movieId, date);
  }

  /// Sơ đồ ghế: ghế đã bán lấy từ bảng `booked_seats` trên Supabase.
  /// REST: `GET /rest/v1/booked_seats?select=seat_id&showtime_id=eq.<id>`
  Future<SeatLayout> getSeatLayout(String showtimeId) async {
    final rows = await _db
        .from('booked_seats')
        .select('seat_id')
        .eq('showtime_id', showtimeId);
    final booked = <String>{
      for (final row in rows) row['seat_id'] as String,
    };
    return SeatLayout(rows: _buildRows(), bookedSeatIds: booked);
  }

  /// Khóa ghế khi đặt vé.
  /// REST: `POST /rest/v1/booked_seats`. Khóa chính (showtime_id, seat_id)
  /// đảm bảo 2 người không thể mua trùng 1 ghế: ai đến sau sẽ bị lỗi 23505.
  Future<void> reserveSeats(String showtimeId, List<String> seatIds) async {
    try {
      await _db.from('booked_seats').insert([
        for (final id in seatIds) {'showtime_id': showtimeId, 'seat_id': id},
      ]);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw SeatConflictException(seatIds);
      rethrow;
    }
  }

  List<List<Seat>> _buildRows() {
    final rows = <List<Seat>>[];
    for (final r in [..._normalRows, ..._vipRows]) {
      final type = _vipRows.contains(r) ? SeatType.vip : SeatType.normal;
      rows.add(List.generate(
        seatsPerRow,
        (i) => Seat(id: '$r${i + 1}', row: r, number: i + 1, type: type),
      ));
    }
    rows.add(List.generate(
      coupleSeats,
      (i) => Seat(
        id: '$_coupleRow${i + 1}',
        row: _coupleRow,
        number: i + 1,
        type: SeatType.couple,
      ),
    ));
    return rows;
  }
}
