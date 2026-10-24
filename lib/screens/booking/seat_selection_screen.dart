// Người phụ trách: Tính (Nhóm trưởng) - sơ đồ chọn ghế (Core Feature)
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking_data.dart';
import '../../models/movie.dart';
import '../../models/seat.dart';
import '../../models/showtime.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../checkout/food_combo_screen.dart';
import 'widgets/screen_curve.dart';
import 'widgets/seat_tile.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({
    super.key,
    required this.movie,
    required this.showtime,
  });

  final Movie movie;
  final Showtime showtime;

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  static const int _maxSeats = 8;
  static const double _labelWidth = 22;
  static const double _aisleWidth = 14;

  SeatLayout? _layout;
  bool _loading = true;
  String? _error;

  /// Set giúp mỗi ghế chỉ có 1 lần và contains() chạy O(1)
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadSeats(showLoading: false);
  }

  Future<void> _loadSeats({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final layout =
          await BookingService.instance.getSeatLayout(widget.showtime.id);
      if (!mounted) return;
      setState(() {
        _layout = layout;
        // Bỏ những ghế vừa bị người khác mua khỏi danh sách đang chọn
        _selected.removeWhere(layout.bookedSeatIds.contains);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được sơ đồ ghế';
      });
    }
  }

  void _toggleSeat(Seat seat) {
    final layout = _layout;
    if (layout == null || layout.bookedSeatIds.contains(seat.id)) return;

    if (!_selected.contains(seat.id) && _selected.length >= _maxSeats) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Mỗi lần đặt tối đa $_maxSeats ghế')),
        );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(seat.id)) _selected.add(seat.id);
    });
  }

  List<Seat> get _selectedSeats {
    final layout = _layout;
    if (layout == null) return const [];
    final seats = _selected
        .map(layout.findSeat)
        .whereType<Seat>()
        .toList()
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.number.compareTo(b.number);
      });
    return seats;
  }

  int get _total => _selectedSeats.fold<int>(
        0,
        (sum, s) => sum + seatPrice(s.type, widget.showtime.basePrice),
      );

  Future<void> _continue() async {
    final booking = BookingData(
      movie: widget.movie,
      showtime: widget.showtime,
      seats: _selectedSeats
          .map((s) => BookedSeat(
                id: s.id,
                type: s.type,
                price: seatPrice(s.type, widget.showtime.basePrice),
              ))
          .toList(),
    );
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FoodComboScreen(booking: booking)),
    );
    // Quay lại màn này (ví dụ do ghế bị trùng) -> tải lại sơ đồ mới nhất
    if (mounted) _loadSeats();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.showtime;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(s.cinema.name, style: const TextStyle(fontSize: 16)),
            Text(
              '${s.room} • ${formatTime(s.startTime)} • ${weekdayLabel(s.startTime)}, ${formatDate(s.startTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _layout == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _layout == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Đã có lỗi xảy ra'),
            TextButton(onPressed: _loadSeats, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final layout = _layout!;

    return Column(
      children: [
        const SizedBox(height: 8),
        const ScreenCurve(),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final seatSize = _seatSize(constraints, layout.rows.length);
              return InteractiveViewer(
                maxScale: 3,
                child: Center(child: _buildSeatMap(layout, seatSize)),
              );
            },
          ),
        ),
        const _Legend(),
        _BottomBar(
          seatLabel: _selectedSeats.map((e) => e.id).join(', '),
          total: _total,
          onContinue: _selected.isEmpty ? null : _continue,
        ),
      ],
    );
  }

  /// Tự tính kích thước ghế để vừa cả chiều ngang lẫn chiều dọc màn hình
  double _seatSize(BoxConstraints c, int rowCount) {
    const cell = SeatTile.gap * 2;
    final byWidth = (c.maxWidth - 2 * _labelWidth - _aisleWidth - 16) /
            BookingService.seatsPerRow -
        cell;
    final byHeight = (c.maxHeight - 16) / rowCount - cell;
    return max(14.0, min(34.0, min(byWidth, byHeight)));
  }

  Widget _buildSeatMap(SeatLayout layout, double seatSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: layout.rows.map((row) {
        final isCoupleRow = row.first.type == SeatType.couple;
        final half = row.length ~/ 2;
        final tiles = row
            .map((seat) => SeatTile(
                  seat: seat,
                  size: seatSize,
                  booked: layout.bookedSeatIds.contains(seat.id),
                  selected: _selected.contains(seat.id),
                  onTap: () => _toggleSeat(seat),
                ))
            .toList();

        return Padding(
          padding: EdgeInsets.only(top: isCoupleRow ? 10 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RowLabel(row.first.row),
              if (isCoupleRow) ...[
                const SizedBox(width: _aisleWidth / 2),
                ...tiles,
                const SizedBox(width: _aisleWidth / 2),
              ] else ...[
                ...tiles.sublist(0, half),
                const SizedBox(width: _aisleWidth),
                ...tiles.sublist(half),
              ],
              _RowLabel(row.first.row),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SeatSelectionScreenState._labelWidth,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color fill, Color border, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border),
              ),
            ),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          item(AppColors.seatAvailable, Colors.white24, 'Trống'),
          item(AppColors.primary, AppColors.primary, 'Đang chọn'),
          item(AppColors.seatBooked, Colors.transparent, 'Đã bán'),
          item(AppColors.seatAvailable, AppColors.vip, 'VIP'),
          item(AppColors.seatAvailable, AppColors.couple, 'Ghế đôi'),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.seatLabel,
    required this.total,
    required this.onContinue,
  });

  final String seatLabel;
  final int total;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seatLabel.isEmpty ? 'Chưa chọn ghế' : 'Ghế: $seatLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      formatVnd(total),
                      key: ValueKey(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('TIẾP TỤC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
