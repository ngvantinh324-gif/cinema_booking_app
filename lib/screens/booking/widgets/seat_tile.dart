// Người phụ trách: Tính - một ô ghế
import 'package:flutter/material.dart';

import '../../../models/seat.dart';
import '../../../theme/app_theme.dart';

class SeatTile extends StatelessWidget {
  const SeatTile({
    super.key,
    required this.seat,
    required this.size,
    required this.booked,
    required this.selected,
    required this.onTap,
  });

  static const double gap = 3; // khoảng cách mỗi bên ghế

  final Seat seat;
  final double size;
  final bool booked;
  final bool selected;
  final VoidCallback onTap;

  Color get _borderColor => switch (seat.type) {
        SeatType.normal => Colors.white24,
        SeatType.vip => AppColors.vip,
        SeatType.couple => AppColors.couple,
      };

  @override
  Widget build(BuildContext context) {
    final width = seat.type == SeatType.couple ? size * 2 + gap * 2 : size;

    final Color fill;
    if (booked) {
      fill = AppColors.seatBooked;
    } else if (selected) {
      fill = AppColors.primary;
    } else {
      fill = AppColors.seatAvailable;
    }

    return Padding(
      padding: const EdgeInsets.all(gap),
      child: GestureDetector(
        onTap: booked ? null : onTap,
        child: AnimatedScale(
          scale: selected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: width,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.35),
                bottom: Radius.circular(size * 0.15),
              ),
              border: Border.all(
                color: booked
                    ? Colors.transparent
                    : (selected ? AppColors.primary : _borderColor),
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: booked
                ? Icon(Icons.close, size: size * 0.55, color: Colors.white24)
                : Text(
                    seat.type == SeatType.couple
                        ? '♥ ${seat.number}'
                        : '${seat.number}',
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.black : Colors.white70,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
