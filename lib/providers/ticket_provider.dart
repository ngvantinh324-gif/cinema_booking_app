// Người phụ trách: Khôi - danh sách vé của người dùng hiện tại
import 'package:flutter/foundation.dart';

import '../models/ticket.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _loading = false;

  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<Ticket> get upcoming => _tickets.where((t) => t.isUpcoming).toList();
  List<Ticket> get watched => _tickets.where((t) => !t.isUpcoming).toList();
  bool get isLoading => _loading;
  int get totalSpent => _tickets.fold<int>(0, (sum, t) => sum + t.totalPaid);

  Future<void> loadTickets(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _tickets = await TicketService.instance.getMyTickets(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Gọi sau khi đặt vé thành công để màn "Vé của tôi" cập nhật ngay
  void addTicket(Ticket ticket) {
    _tickets = [ticket, ..._tickets];
    notifyListeners();
  }

  void clear() {
    _tickets = [];
    notifyListeners();
  }
}
