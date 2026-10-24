// Người phụ trách: Minh - bắp nước & đặt vé
import '../data/mock/mock_combos.dart';
import '../models/booking_data.dart';
import '../models/combo.dart';
import '../models/seat.dart';
import '../models/ticket.dart';
import 'api_config.dart';
import 'booking_service.dart';
import 'ticket_service.dart';

class CheckoutService {
  CheckoutService._();
  static final CheckoutService instance = CheckoutService._();

  /// GET /api/combos
  Future<List<Combo>> getCombos() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(ApiConfig.mockDelay);
      return List<Combo>.of(mockCombos);
    }
    throw UnimplementedError('Chưa kết nối API bắp nước');
  }

  /// POST /api/tickets/book  (body = booking.toJson())
  Future<Ticket> bookTicket({
    required BookingData booking,
    required String paymentMethod,
    required String userId,
  }) async {
    if (!ApiConfig.useMockData) {
      throw UnimplementedError('Chưa kết nối API đặt vé');
    }
    await Future.delayed(const Duration(milliseconds: 1200));

    // --- Những việc dưới đây là việc của SERVER, mock lại để demo ---
    // 1. Kiểm tra & khóa ghế (ném SeatConflictException nếu trùng)
    BookingService.instance.reserveSeats(booking.showtime.id, booking.seatIds);
    // 2. Tự tính tiền từ bảng giá, không tin tổng tiền app gửi lên
    final total = _serverSideTotal(booking);
    // 3. Lưu vé vào lịch sử của người dùng
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
    TicketService.instance.saveTicket(ticket);
    return ticket;
  }

  int _serverSideTotal(BookingData booking) {
    var total = 0;
    for (final seat in booking.seats) {
      total += seatPrice(seat.type, booking.showtime.basePrice);
    }
    for (final item in booking.combos) {
      final combo = mockCombos.firstWhere((c) => c.id == item.combo.id);
      total += combo.price * item.quantity;
    }
    return total;
  }

  String _newTicketCode() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'CG${stamp.substring(stamp.length - 6).toUpperCase()}';
  }
}
