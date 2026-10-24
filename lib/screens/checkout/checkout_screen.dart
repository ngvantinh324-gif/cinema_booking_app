// Người phụ trách: Minh - xác nhận đơn & thanh toán giả lập
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking_data.dart';
import '../../models/seat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/booking_service.dart';
import '../../services/checkout_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/age_badge.dart';
import '../../widgets/movie_poster.dart';
import '../profile/ticket_detail_screen.dart';

class _PayMethod {
  const _PayMethod(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const List<_PayMethod> _methods = [
  _PayMethod('momo', 'Ví MoMo', Icons.account_balance_wallet, Color(0xFFD82D8B)),
  _PayMethod('zalopay', 'ZaloPay', Icons.qr_code_2, Color(0xFF0068FF)),
  _PayMethod('card', 'Thẻ ATM / Visa / Master', Icons.credit_card, Color(0xFF7B61FF)),
  _PayMethod('cash', 'Tiền mặt tại quầy', Icons.payments_outlined, Color(0xFF2ECC71)),
];

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.booking});

  final BookingData booking;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _methodId = _methods.first.id;
  bool _processing = false;

  String get _methodLabel =>
      _methods.firstWhere((m) => m.id == _methodId).label;

  Future<void> _confirm() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _processing = true);
    try {
      final ticket = await CheckoutService.instance.bookTicket(
        booking: widget.booking,
        paymentMethod: _methodLabel,
        userId: user.id,
      );
      if (!mounted) return;
      context.read<TicketProvider>().addTicket(ticket);
      HapticFeedback.heavyImpact();
      // Xóa các màn đặt vé khỏi stack, chỉ giữ lại MainShell bên dưới
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticket: ticket, justBooked: true),
        ),
        (route) => route.isFirst,
      );
    } on SeatConflictException catch (e) {
      // Tương đương server trả về HTTP 409 Conflict
      if (!mounted) return;
      setState(() => _processing = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ghế đã có người đặt'),
          content: Text(
            'Ghế ${e.seatIds.join(', ')} vừa được người khác đặt. '
            'Vui lòng chọn ghế khác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chọn lại'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Đóng Checkout + Bắp nước để quay về sơ đồ ghế (màn đó tự tải lại)
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt vé thất bại, vui lòng thử lại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _MovieSummary(booking: b),
            const SizedBox(height: 16),
            _Section(
              child: Column(
                children: [
                  ExpansionTile(
                    initiallyExpanded: true,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: EdgeInsets.zero,
                    title: Text('Vé xem phim (${b.seats.length})'),
                    subtitle: Text(
                      formatVnd(b.ticketTotal),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    children: b.seats
                        .map((s) => _LineItem(
                              label: 'Ghế ${s.id} (${seatTypeLabel(s.type)})',
                              value: formatVnd(s.price),
                            ))
                        .toList(),
                  ),
                  if (b.combos.isNotEmpty)
                    ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Bắp nước'),
                      subtitle: Text(
                        formatVnd(b.comboTotal),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      children: b.combos
                          .map((c) => _LineItem(
                                label: '${c.quantity} x ${c.combo.name}',
                                value: formatVnd(c.subtotal),
                              ))
                          .toList(),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        formatVnd(b.grandTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._methods.map((m) => _PayTile(
                  method: m,
                  selected: m.id == _methodId,
                  onTap: _processing
                      ? null
                      : () => setState(() => _methodId = m.id),
                )),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Thanh toán giả lập cho đồ án, không trừ tiền thật.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ElevatedButton(
              onPressed: _processing ? null : _confirm,
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text('XÁC NHẬN ĐẶT VÉ • ${formatVnd(b.grandTotal)}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _MovieSummary extends StatelessWidget {
  const _MovieSummary({required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    final s = booking.showtime;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 108,
              child: MoviePoster(movie: booking.movie, emojiSize: 32),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.movie.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AgeBadge(rating: booking.movie.ageRating, small: true),
                    const SizedBox(width: 6),
                    Text(
                      s.format,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.cinema.name} • ${s.room}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatTime(s.startTime)} • ${weekdayLabel(s.startTime)}, ${formatDate(s.startTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ghế: ${booking.seatLabel}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PayMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white10,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: method.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(method.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(method.label)),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
