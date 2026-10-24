// Người phụ trách: Tính (Nhóm trưởng) - rạp & lịch chiếu giả lập
import 'dart:math';

import '../../core/utils/formatters.dart';
import '../../models/showtime.dart';

const List<Cinema> mockCinemas = [
  Cinema(id: 'c1', name: 'CineGo Hùng Vương', address: 'Quận 5, TP.HCM'),
  Cinema(id: 'c2', name: 'CineGo Landmark', address: 'Bình Thạnh, TP.HCM'),
  Cinema(id: 'c3', name: 'CineGo Thủ Đức', address: 'TP. Thủ Đức, TP.HCM'),
];

const List<String> _timeSlots = [
  '09:30', '11:45', '13:15', '15:40', '17:20',
  '18:30', '19:45', '20:15', '21:30', '22:40',
];

/// Sinh lịch chiếu cố định (cùng phim + rạp + ngày luôn ra cùng kết quả).
List<Showtime> generateMockShowtimes(String movieId, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final isWeekend = day.weekday >= DateTime.saturday;
  final result = <Showtime>[];

  for (var c = 0; c < mockCinemas.length; c++) {
    final cinema = mockCinemas[c];
    final rnd = Random('${movieId}_${cinema.id}_${day.month}_${day.day}'.hashCode);
    final format = c == 1 ? 'IMAX' : (rnd.nextBool() ? '2D' : '3D');
    final int formatPrice = switch (format) {
      'IMAX' => 135000,
      '3D' => 105000,
      _ => 85000,
    };
    final basePrice = formatPrice + (isWeekend ? 10000 : 0);

    final slots = List<String>.of(_timeSlots)..shuffle(rnd);
    final picked = slots.take(4 + rnd.nextInt(3)).toList()..sort();

    for (final slot in picked) {
      final parts = slot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      result.add(Showtime(
        id: '${movieId}_${cinema.id}_${day.year}${pad2(day.month)}${pad2(day.day)}_${parts[0]}${parts[1]}',
        movieId: movieId,
        cinema: cinema,
        room: 'Phòng ${1 + rnd.nextInt(8)}',
        startTime: DateTime(day.year, day.month, day.day, hour, minute),
        format: format,
        basePrice: basePrice,
      ));
    }
  }
  return result;
}
