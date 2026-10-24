// Người phụ trách: Khôi - lịch sử vé
import '../data/mock/mock_cinemas.dart';
import '../data/mock/mock_combos.dart';
import '../data/mock/mock_movies.dart';
import '../models/booking_data.dart';
import '../models/combo.dart';
import '../models/seat.dart';
import '../models/showtime.dart';
import '../models/ticket.dart';
import 'api_config.dart';

class TicketService {
  TicketService._();
  static final TicketService instance = TicketService._();

  final Map<String, List<Ticket>> _ticketsByUser = {};
  bool _seeded = false;

  /// GET /api/tickets/my-tickets
  /// Server xác định người dùng từ token (Authorization: Bearer ...),
  /// KHÔNG nhận user_id từ query để tránh xem trộm vé người khác (lỗi IDOR).
  Future<List<Ticket>> getMyTickets(String userId) async {
    if (!ApiConfig.useMockData) {
      throw UnimplementedError('Chưa kết nối API lịch sử vé');
    }
    await Future.delayed(ApiConfig.mockDelay);
    _seedIfNeeded();
    final list = List<Ticket>.of(_ticketsByUser[userId] ?? const []);
    list.sort((a, b) => b.showtime.startTime.compareTo(a.showtime.startTime));
    return list;
  }

  void saveTicket(Ticket ticket) {
    _seedIfNeeded();
    _ticketsByUser.putIfAbsent(ticket.userId, () => []).add(ticket);
  }

  /// Tạo sẵn 2 vé mẫu cho tài khoản demo để màn "Vé của tôi" không trống
  void _seedIfNeeded() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();

    final upcomingStart =
        DateTime(now.year, now.month, now.day + 2, 19, 45);
    final upcoming = Showtime(
      id: 'seed_upcoming',
      movieId: mockMovies[0].id,
      cinema: mockCinemas[1],
      room: 'Phòng 5',
      startTime: upcomingStart,
      format: 'IMAX',
      basePrice: 135000,
    );

    final pastStart = DateTime(now.year, now.month, now.day - 10, 20, 15);
    final past = Showtime(
      id: 'seed_past',
      movieId: mockMovies[2].id,
      cinema: mockCinemas[0],
      room: 'Phòng 2',
      startTime: pastStart,
      format: '2D',
      basePrice: 85000,
    );

    _ticketsByUser['u1'] = [
      Ticket(
        id: 'CGDEMO1',
        userId: 'u1',
        movie: mockMovies[0],
        showtime: upcoming,
        seats: [
          BookedSeat(id: 'F6', type: SeatType.vip, price: seatPrice(SeatType.vip, 135000)),
          BookedSeat(id: 'F7', type: SeatType.vip, price: seatPrice(SeatType.vip, 135000)),
        ],
        combos: [SelectedCombo(mockCombos[1], 1)],
        totalPaid: seatPrice(SeatType.vip, 135000) * 2 + mockCombos[1].price,
        paymentMethod: 'Ví MoMo',
        bookedAt: now.subtract(const Duration(hours: 5)),
      ),
      Ticket(
        id: 'CGDEMO0',
        userId: 'u1',
        movie: mockMovies[2],
        showtime: past,
        seats: [
          BookedSeat(id: 'H3', type: SeatType.couple, price: seatPrice(SeatType.couple, 85000)),
        ],
        combos: const [],
        totalPaid: seatPrice(SeatType.couple, 85000),
        paymentMethod: 'Tiền mặt tại quầy',
        bookedAt: pastStart.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
