// Người phụ trách: Khôi - vé điện tử & mã QR
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/formatters.dart';
import '../../models/ticket.dart';
import '../../theme/app_theme.dart';
import '../../widgets/age_badge.dart';
import '../../widgets/movie_poster.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.justBooked = false,
  });

  final Ticket ticket;
  final bool justBooked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(justBooked ? 'Đặt vé thành công' : 'Chi tiết vé'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            if (justBooked) const _SuccessHeader(),
            _TicketCard(ticket: ticket),
            const SizedBox(height: 16),
            const Text(
              'Đưa mã QR cho nhân viên soát vé tại rạp.\n'
              'Vui lòng có mặt trước giờ chiếu 15 phút.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      bottomNavigationBar: justBooked
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('VỀ TRANG CHỦ'),
                ),
              ),
            )
          : null,
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 46),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Đặt vé thành công!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vé đã được lưu trong mục "Vé của tôi"',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final s = ticket.showtime;
    const radius = Radius.circular(20);

    return Column(
      children: [
        // ----- Phần trên: thông tin phim -----
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 102,
                      child: MoviePoster(movie: ticket.movie, emojiSize: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.movie.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AgeBadge(
                              rating: ticket.movie.ageRating,
                              small: true,
                            ),
                            const SizedBox(width: 6),
                            Text(s.format, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TicketStatusChip(upcoming: ticket.isUpcoming),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _Info('Rạp', s.cinema.name)),
                  Expanded(child: _Info('Phòng', s.room)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Info(
                      'Ngày',
                      '${weekdayLabel(s.startTime)}, ${formatDate(s.startTime)}',
                    ),
                  ),
                  Expanded(child: _Info('Suất chiếu', formatTime(s.startTime))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Info('Ghế', ticket.seatLabel, highlight: true)),
                  Expanded(child: _Info('Thanh toán', ticket.paymentMethod)),
                ],
              ),
              if (ticket.combos.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Info('Bắp nước', ticket.comboLabel),
              ],
              const SizedBox(height: 12),
              _Info('Tổng tiền', formatVnd(ticket.totalPaid), highlight: true),
            ],
          ),
        ),
        // ----- Đường cắt răng cưa giữa vé -----
        Container(
          color: AppColors.surface,
          height: 28,
          child: Row(
            children: [
              const _Notch(isLeft: true),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: _DashPainter(),
                ),
              ),
              const _Notch(isLeft: false),
            ],
          ),
        ),
        // ----- Phần dưới: mã QR -----
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.only(bottomLeft: radius, bottomRight: radius),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                  data: ticket.qrData,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ticket.id,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'Mã vé',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.primary : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(14);
    return Container(
      width: 14,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: isLeft
            ? const BorderRadius.only(topRight: r, bottomRight: r)
            : const BorderRadius.only(topLeft: r, bottomLeft: r),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;
    const dash = 8.0;
    const space = 6.0;
    final y = size.height / 2;
    var x = 8.0;
    while (x < size.width - 8) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Nhãn trạng thái vé - dùng ở cả danh sách vé và chi tiết vé
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final color = upcoming ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        upcoming ? 'Sắp chiếu' : 'Đã xem',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
