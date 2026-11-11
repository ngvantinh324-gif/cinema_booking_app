// Người phụ trách: Minh - xác nhận đơn & thanh toán giả lập
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking_data.dart';
import '../../models/seat.dart';
import '../../models/voucher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/booking_service.dart';
import '../../services/checkout_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/age_badge.dart';
import '../../widgets/movie_poster.dart';
import '../profile/ticket_detail_screen.dart';

class _PayMethod {
  const _PayMethod(
    this.id,
    this.label,
    this.subtitle,
    this.icon,
    this.color, {
    this.badge,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
}

const List<_PayMethod> _methods = [
  _PayMethod(
    'momo',
    'Ví MoMo',
    'Liên kết nhanh • Xác nhận tức thì',
    Icons.account_balance_wallet_rounded,
    Color(0xFFD82D8B),
    badge: 'Phổ biến',
  ),
  _PayMethod(
    'zalopay',
    'ZaloPay',
    'Quét mã QR hoặc chuyển khoản ví',
    Icons.qr_code_2_rounded,
    Color(0xFF0068FF),
  ),
  _PayMethod(
    'card',
    'Thẻ ATM / Visa / Master',
    'Hỗ trợ thẻ ngân hàng nội địa & quốc tế',
    Icons.credit_card_rounded,
    Color(0xFF7B61FF),
  ),
  _PayMethod(
    'cash',
    'Tiền mặt tại quầy',
    'Giữ vé trước • Thanh toán tại quầy CineGo',
    Icons.payments_rounded,
    Color(0xFF2ECC71),
  ),
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

  // Mã giảm giá
  final _voucherCtrl = TextEditingController();
  Voucher? _voucher;
  bool _checkingVoucher = false;
  String? _voucherError;

  // Đồng hồ đếm ngược thời gian giữ ghế (10 phút)
  Timer? _holdTimer;
  int _remainingSeconds = 600;

  _PayMethod get _selectedMethod =>
      _methods.firstWhere((m) => m.id == _methodId);

  String get _methodLabel => _selectedMethod.label;

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _onHoldExpired();
      }
    });
  }

  /// Hết 10 phút giữ ghế: báo cho khách và quay về sơ đồ ghế để chọn lại
  Future<void> _onHoldExpired() async {
    if (_processing || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Hết thời gian giữ ghế'),
        content: const Text('Bạn đã quá 10 phút. Vui lòng chọn lại ghế.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Chọn lại ghế'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _voucherCtrl.dispose();
    super.dispose();
  }

  /// Số tiền được giảm và số tiền phải trả sau giảm
  int get _discount => _voucher?.discountFor(widget.booking.grandTotal) ?? 0;
  int get _payable => widget.booking.grandTotal - _discount;

  Future<void> _applyVoucher() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _checkingVoucher = true;
      _voucherError = null;
    });
    try {
      final voucher = await CheckoutService.instance
          .checkVoucher(_voucherCtrl.text, widget.booking.grandTotal);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _voucher = voucher);
    } on VoucherException catch (e) {
      if (!mounted) return;
      setState(() {
        _voucher = null;
        _voucherError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _voucherError = 'Không kiểm tra được mã, thử lại sau');
    } finally {
      if (mounted) setState(() => _checkingVoucher = false);
    }
  }

  void _removeVoucher() {
    setState(() {
      _voucher = null;
      _voucherError = null;
      _voucherCtrl.clear();
    });
  }

  String get _formattedHoldTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirm() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _processing = true);
    try {
      final ticket = await CheckoutService.instance.bookTicket(
        booking: widget.booking,
        paymentMethod: _methodLabel,
        userId: user.id,
        voucherCode: _voucher?.code,
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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ghế đã có người đặt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Ghế ${e.seatIds.join(', ')} vừa được người khác đặt. '
            'Vui lòng chọn ghế khác.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chọn lại ghế'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Đóng Checkout + Bắp nước để quay về sơ đồ ghế (màn đó tự tải lại)
      Navigator.of(context)
        ..pop()
        ..pop();
    } on VoucherException catch (e) {
      // Mã giảm giá hết hiệu lực ngay lúc thanh toán
      if (!mounted) return;
      setState(() {
        _processing = false;
        _voucher = null;
        _voucherError = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}. Vui lòng kiểm tra lại.')),
      );
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
        appBar: AppBar(
          centerTitle: true,
          title: const Column(
            children: [
              Text(
                'Thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Bước 3/3 • Kiểm tra thông tin vé',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formattedHoldTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            // Thẻ thông tin vé phong cách cuống vé điện tử
            _MovieSummary(booking: b),
            const SizedBox(height: 18),

            // Chi tiết hóa đơn thanh toán
            _OrderBreakdownCard(
              booking: b,
              voucher: _voucher,
              discount: _discount,
            ),
            const SizedBox(height: 14),

            // Mã giảm giá
            _VoucherCard(
              controller: _voucherCtrl,
              voucher: _voucher,
              discount: _discount,
              checking: _checkingVoucher,
              error: _voucherError,
              enabled: !_processing,
              onApply: _applyVoucher,
              onRemove: _removeVoucher,
            ),
            const SizedBox(height: 22),

            // Tiêu đề phương thức thanh toán
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Phương thức thanh toán',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Text(
                  'Chọn 1 phương thức',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Danh sách phương thức thanh toán
            ..._methods.map(
              (m) => _PayTile(
                method: m,
                selected: m.id == _methodId,
                onTap: _processing
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _methodId = m.id);
                      },
              ),
            ),
            const SizedBox(height: 6),

            // Ghi chú bảo mật & thanh toán giả lập
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thanh toán giả lập an toàn cho đồ án, không trừ tiền thật.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomCheckoutBar(
          grandTotal: _payable,
          selectedMethod: _selectedMethod,
          processing: _processing,
          onConfirm: _confirm,
        ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phần trên: Poster + thông tin suất chiếu
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 82,
                      height: 116,
                      child: MoviePoster(movie: booking.movie, emojiSize: 34),
                    ),
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
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AgeBadge(
                              rating: booking.movie.ageRating, small: true),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              s.format,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${s.cinema.name} • ${s.room}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${formatTime(s.startTime)} • ${weekdayLabel(s.startTime)}, ${formatDate(s.startTime)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Đường cắt cuống vé (Ticket Perforation)
          const _TicketPerforationDivider(),

          // Phần dưới: Tóm tắt ghế ngồi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_seat_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vị trí ghế đã chọn',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Ghế: ${booking.seatLabel}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${booking.seats.length} vé',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _TicketPerforationDivider extends StatelessWidget {
  const _TicketPerforationDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => Container(
                      width: 5,
                      height: 1.2,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 9,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderBreakdownCard extends StatelessWidget {
  const _OrderBreakdownCard({
    required this.booking,
    this.voucher,
    this.discount = 0,
  });

  final BookingData booking;
  final Voucher? voucher;
  final int discount;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Chi tiết Vé xem phim
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Vé xem phim (${b.seats.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  formatVnd(b.ticketTotal),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: b.seats
                          .map(
                            (s) => _LineItem(
                              label: 'Ghế ${s.id}',
                              badge: seatTypeLabel(s.type),
                              value: formatVnd(s.price),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Chi tiết Bắp nước (nếu có chọn)
            if (b.combos.isNotEmpty) ...[
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB75E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fastfood_outlined,
                      color: Color(0xFFFFB75E),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Bắp nước (${b.combos.fold<int>(0, (sum, c) => sum + c.quantity)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    formatVnd(b.comboTotal),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: b.combos
                            .map(
                              (c) => _LineItem(
                                leadingEmoji: c.combo.emoji,
                                label: c.combo.name,
                                badge: 'x${c.quantity}',
                                value: formatVnd(c.subtotal),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Dòng giảm giá (nếu đã áp dụng mã)
            if (voucher != null && discount > 0) ...[
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Giảm giá (${voucher!.code})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(
                    '-${formatVnd(discount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            // Tổng cộng
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Đã bao gồm thuế VAT',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatVnd(b.grandTotal - discount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.label,
    required this.value,
    this.badge,
    this.leadingEmoji,
  });

  final String label;
  final String value;
  final String? badge;
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (leadingEmoji != null) ...[
            Text(leadingEmoji!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: selected ? 1.0 : 0.78,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.surface,
                        AppColors.primary.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: selected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.08),
                width: selected ? 1.6 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: method.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: method.color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(method.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              method.label,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (method.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                method.badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        method.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar({
    required this.grandTotal,
    required this.selectedMethod,
    required this.processing,
    required this.onConfirm,
  });

  final int grandTotal;
  final _PayMethod selectedMethod;
  final bool processing;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  selectedMethod.icon,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Thanh toán qua ${selectedMethod.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  formatVnd(grandTotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: processing ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: processing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'ĐANG XỬ LÝ GIAO DỊCH...',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'XÁC NHẬN ĐẶT VÉ • ${formatVnd(grandTotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô nhập mã giảm giá
class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.controller,
    required this.voucher,
    required this.discount,
    required this.checking,
    required this.error,
    required this.enabled,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final Voucher? voucher;
  final int discount;
  final bool checking;
  final String? error;
  final bool enabled;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final applied = voucher;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: applied != null
              ? AppColors.success.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: applied != null
          ? Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã áp dụng ${applied.code} • -${formatVnd(discount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applied.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bỏ mã',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mã giảm giá',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: enabled && !checking,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onApply(),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          errorText: error,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 96,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: enabled && !checking ? onApply : null,
                        child: checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
