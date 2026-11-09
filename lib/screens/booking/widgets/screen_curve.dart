// Người phụ trách: Tính - thanh cong mô phỏng màn hình chiếu
import 'package:flutter/material.dart';

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
            color: Color(0xFF8ECFFF),
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

    // Lớp glow ngoài (mờ, lan rộng) - mô phỏng ánh sáng màn chiếu
    final outerGlow = Paint()
      ..color = const Color(0x338ECFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(path, outerGlow);

    // Lớp glow trong (đậm hơn)
    final innerGlow = Paint()
      ..color = const Color(0x778ECFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, innerGlow);

    // Đường viền chính sắc nét màu trắng xanh
    final line = Paint()
      ..color = const Color(0xFFCCE8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
