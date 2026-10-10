enum SeatType { standard, vip, couple }

class Seat {
  final String seatCode; // Ví dụ: A1, B3, D5
  final int row;
  final int col;
  final int price;
  final SeatType type;
  final bool isBooked;

  Seat({
    required this.seatCode,
    required this.row,
    required this.col,
    required this.price,
    this.type = SeatType.standard,
    this.isBooked = false,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatCode: json['seat_code'],
      row: json['row'],
      col: json['col'],
      price: json['price'] ?? 85000,
      type: SeatType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => SeatType.standard,
      ),
      isBooked: json['is_booked'] ?? false,
    );
  }
}