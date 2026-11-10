// Người phụ trách: Minh - bộ nút tăng/giảm số lượng
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final active = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: active
                ? () {
                    HapticFeedback.selectionClick();
                    onMinus();
                  }
                : null,
          ),
          SizedBox(
            width: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '$quantity',
                key: ValueKey<int>(quantity),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.primary : Colors.white70,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onPlus();
            },
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted && enabled
                ? AppColors.primary
                : (enabled
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent),
            boxShadow: highlighted && enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: !enabled
                ? Colors.white24
                : (highlighted ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }
}
