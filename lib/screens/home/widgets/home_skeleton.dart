// Người phụ trách: Triết - khung xương nhấp nháy trong lúc tải danh sách phim
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        children: [
          // Lời chào + avatar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 120, height: 14),
                    const SizedBox(height: 8),
                    _box(width: 200, height: 22),
                  ],
                ),
              ),
              _box(width: 44, height: 44, radius: 22),
            ],
          ),
          const SizedBox(height: 18),
          // Banner
          _box(height: 190, radius: 20),
          const SizedBox(height: 22),
          // Tab
          Row(
            children: [
              _box(width: 96, height: 18),
              const SizedBox(width: 20),
              _box(width: 80, height: 18),
            ],
          ),
          const SizedBox(height: 18),
          // Lưới phim
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.52,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
            ),
            itemBuilder: (context, i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _box(radius: 16)),
                const SizedBox(height: 10),
                _box(width: 110, height: 14),
                const SizedBox(height: 6),
                _box(width: 70, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({double? width, double? height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
