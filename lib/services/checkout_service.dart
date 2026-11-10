// Người phụ trách: Minh - bắp nước & đặt vé
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_data.dart';
import '../models/combo.dart';
import '../models/seat.dart';
import '../models/ticket.dart';
import 'booking_service.dart';
import 'ticket_service.dart';

class CheckoutService {
  CheckoutService._();
  static final CheckoutService instance = CheckoutService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Bảng giá bắp nước lấy từ CSDL, dùng lại khi tính tiền
  List<Combo> _menu = const [];

  /// Lấy menu bắp nước từ bảng `combos`.
  /// REST: GET /rest/v1/combos?select=*&order=sort_order.asc
  Future<List<Combo>> getCombos() async {
    final rows = await _db.from('combos').select().order('sort_order');
    _menu = rows
        .map((r) => Combo(
              id: r['id'] as String,
              name: r['name'] as String,
              description: r['description'] as String? ?? '',
              price: (r['price'] as num).toInt(),
              emoji: r['emoji'] as String? ?? '🍿',
              tag: r['tag'] as String?,
            ))
        .toList();
    return _menu;
  }

  /// Đặt vé: khóa ghế -> tính tiền -> lưu vé.
  Future<Ticket> bookTicket({
    required BookingData booking,
    required String paymentMethod,
    required String userId,
  }) async {
    // 1. Khóa ghế trên CSDL. Ghế vừa bị người khác mua -> SeatConflictException
    await BookingService.instance
        .reserveSeats(booking.showtime.id, booking.seatIds);

    // 2. Tính lại tiền theo bảng giá, không dùng số tiền màn hình gửi sang
    final total = _calculateTotal(booking);

    // 3. Lưu vé vào bảng tickets
    final ticket = Ticket(
      id: _newTicketCode(),
      userId: userId,
      movie: booking.movie,
      showtime: booking.showtime,
      seats: booking.seats,
      combos: booking.combos,
      totalPaid: total,
      paymentMethod: paymentMethod,
      bookedAt: DateTime.now(),
    );
    await TicketService.instance.saveTicket(ticket);
    return ticket;
  }

  int _calculateTotal(BookingData booking) {
    var total = 0;
    for (final seat in booking.seats) {
      total += seatPrice(seat.type, booking.showtime.basePrice);
    }
    for (final item in booking.combos) {
      var price = item.combo.price;
      for (final c in _menu) {
        if (c.id == item.combo.id) price = c.price;
      }
      total += price * item.quantity;
    }
    return total;
  }

  String _newTicketCode() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'CG${stamp.substring(stamp.length - 6).toUpperCase()}';
  }
}
