// HỢP ĐỒNG DỮ LIỆU CHUNG - Người giữ: Tính (Nhóm trưởng)
// Muốn sửa file này phải báo cả nhóm vì 3 luồng cùng dùng:
// Chọn ghế (Tính) -> Bắp nước & Thanh toán (Minh) -> Vé (Khôi)
import 'combo.dart';
import 'movie.dart';
import 'seat.dart';
import 'showtime.dart';

class BookedSeat {
  final String id;
  final SeatType type;
  final int price;

  const BookedSeat({required this.id, required this.type, required this.price});
}

class BookingData {
  final Movie movie;
  final Showtime showtime;
  final List<BookedSeat> seats;
  final List<SelectedCombo> combos;

  const BookingData({
    required this.movie,
    required this.showtime,
    required this.seats,
    this.combos = const [],
  });

  int get ticketTotal => seats.fold<int>(0, (sum, s) => sum + s.price);

  int get comboTotal => combos.fold<int>(0, (sum, c) => sum + c.subtotal);

  int get grandTotal => ticketTotal + comboTotal;

  List<String> get seatIds => seats.map((s) => s.id).toList();

  String get seatLabel => seatIds.join(', ');

  BookingData copyWith({List<SelectedCombo>? combos}) => BookingData(
        movie: movie,
        showtime: showtime,
        seats: seats,
        combos: combos ?? this.combos,
      );

  /// Body gửi lên POST /api/tickets/book.
  /// KHÔNG gửi tổng tiền: server tự tính để tránh bị sửa giá từ phía app.
  Map<String, dynamic> toJson() => {
        'showtime_id': showtime.id,
        'seats': seatIds,
        'combos': combos
            .map((c) => {'combo_id': c.combo.id, 'quantity': c.quantity})
            .toList(),
      };
}
