// Người phụ trách: Tính (Nhóm trưởng)

enum SeatType { normal, vip, couple }

class Seat {
  final String id; // ví dụ: "E5"
  final String row;
  final int number;
  final SeatType type;

  const Seat({
    required this.id,
    required this.row,
    required this.number,
    required this.type,
  });
}

/// Sơ đồ ghế của một suất chiếu.
class SeatLayout {
  final List<List<Seat>> rows;
  final Set<String> bookedSeatIds;

  const SeatLayout({required this.rows, required this.bookedSeatIds});

  Seat? findSeat(String id) {
    for (final row in rows) {
      for (final seat in row) {
        if (seat.id == id) return seat;
      }
    }
    return null;
  }
}

int seatPrice(SeatType type, int basePrice) => switch (type) {
      SeatType.normal => basePrice,
      SeatType.vip => basePrice + 20000,
      SeatType.couple => basePrice * 2 + 20000,
    };

String seatTypeLabel(SeatType type) => switch (type) {
      SeatType.normal => 'Thường',
      SeatType.vip => 'VIP',
      SeatType.couple => 'Đôi',
    };
