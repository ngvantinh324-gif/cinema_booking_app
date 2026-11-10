// Người phụ trách: Khôi - lịch sử vé
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ticket.dart';

class TicketService {
  TicketService._();
  static final TicketService instance = TicketService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Lấy vé của người đang đăng nhập.
  /// REST: GET /rest/v1/tickets?select=*
  /// KHÔNG gửi user_id lên server: chính sách Row Level Security
  /// (user_id = auth.uid()) tự lọc theo token đăng nhập, nên không ai
  /// xem được vé của người khác (chống lỗi IDOR).
  Future<List<Ticket>> getMyTickets(String userId) async {
    final rows = await _db
        .from('tickets')
        .select()
        .order('created_at', ascending: false);
    final list = rows
        .map((r) => Ticket.fromJson(
              r['data'] as Map<String, dynamic>,
              userId: r['user_id'] as String,
            ))
        .toList();
    list.sort((a, b) => b.showtime.startTime.compareTo(a.showtime.startTime));
    return list;
  }

  /// Lưu vé mới. REST: POST /rest/v1/tickets
  /// user_id do CSDL tự gán bằng auth.uid() nên app không giả mạo được.
  Future<void> saveTicket(Ticket ticket) async {
    await _db.from('tickets').insert({
      'id': ticket.id,
      'data': ticket.toJson(),
      'total': ticket.totalPaid,
    });
  }
}
