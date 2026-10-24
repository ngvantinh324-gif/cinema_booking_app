// Người phụ trách: Khôi
import 'booking_data.dart';
import 'combo.dart';
import 'movie.dart';
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

  String get seatLabel => seats.map((s) => s.id).join(', ');

  String get comboLabel =>
      combos.map((c) => '${c.quantity}x ${c.combo.name}').join(', ');

  /// Nội dung mã QR để nhân viên soát vé quét
  String get qrData =>
      'CINEGO|$id|${showtime.id}|${seats.map((s) => s.id).join('-')}';
}
