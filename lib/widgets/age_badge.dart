// Widget dùng chung - Người giữ: Triết
import 'package:flutter/material.dart';

class AgeBadge extends StatelessWidget {
  const AgeBadge({super.key, required this.rating, this.small = false});

  final String rating;
  final bool small;

  Color get _color => switch (rating) {
        'P' => const Color(0xFF2ECC71),
        'T13' => const Color(0xFFF1C40F),
        'T16' => const Color(0xFFFF8C00),
        'T18' => const Color(0xFFE74C3C),
        _ => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rating,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: small ? 10 : 12,
        ),
      ),
    );
  }
}
