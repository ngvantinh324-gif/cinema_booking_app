// Người phụ trách: Tính (Nhóm trưởng) - lịch chiếu & sơ đồ ghế
import 'dart:math';

import '../data/mock/mock_cinemas.dart';
import '../models/seat.dart';
import '../models/showtime.dart';
import 'api_config.dart';

class SeatConflictException implements Exception {
  final List<String> seatIds;

  const SeatConflictException(this.seatIds);

  @override
  String toString() => 'Ghế ${seatIds.join(', ')} đã có người đặt';
}

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  // Ghế đã bán theo từng suất chiếu (mô phỏng bảng dữ liệu trên server)
  final Map<String, Set<String>> _bookedSeats = {};

  static const List<String> _normalRows = ['A', 'B', 'C', 'D'];
  static const List<String> _vipRows = ['E', 'F', 'G'];
  static const String _coupleRow = 'H';
  static const int seatsPerRow = 10;
  static const int coupleSeats = 5;

  /// GET /api/showtimes?movie_id=..&date=..
  Future<List<Showtime>> getShowtimes(String movieId, DateTime date) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 350));
      return generateMockShowtimes(movieId, date);
    }
    throw UnimplementedError('Chưa kết nối API lịch chiếu');
  }

  /// GET /api/seats?showtime_id=..
  Future<SeatLayout> getSeatLayout(String showtimeId) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(ApiConfig.mockDelay);
      final booked = _bookedFor(showtimeId);
      return SeatLayout(rows: _buildRows(), bookedSeatIds: Set<String>.of(booked));
    }
    throw UnimplementedError('Chưa kết nối API sơ đồ ghế');
  }

  /// Mô phỏng phía SERVER khi đặt vé: kiểm tra lại & khóa ghế.
  /// Nếu ghế vừa bị người khác mua -> ném lỗi (tương đương HTTP 409 Conflict).
  void reserveSeats(String showtimeId, List<String> seatIds) {
    final booked = _bookedFor(showtimeId);
    final conflicts = seatIds.where(booked.contains).toList();
    if (conflicts.isNotEmpty) throw SeatConflictException(conflicts);
    booked.addAll(seatIds);
  }

  Set<String> _bookedFor(String showtimeId) =>
      _bookedSeats.putIfAbsent(showtimeId, () => _randomBooked(showtimeId));

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

  Set<String> _randomBooked(String showtimeId) {
    final rnd = Random(showtimeId.hashCode);
    final all = <String>[
      for (final seatRow in _buildRows())
        for (final seat in seatRow) seat.id,
    ]..shuffle(rnd);
    return all.take(8 + rnd.nextInt(10)).toSet();
  }
}
