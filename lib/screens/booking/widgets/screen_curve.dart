// Người phụ trách: Tính - thanh cong mô phỏng màn hình chiếu
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ScreenCurve extends StatelessWidget {
  const ScreenCurve({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 34,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: CustomPaint(painter: _ScreenPainter()),
          ),
        ),
        const Text(
          'MÀN HÌNH',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height);

    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glow);

    final line = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
