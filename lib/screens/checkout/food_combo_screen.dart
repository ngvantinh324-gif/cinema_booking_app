// Người phụ trách: Minh - chọn bắp nước
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking_data.dart';
import '../../models/combo.dart';
import '../../services/checkout_service.dart';
import '../../theme/app_theme.dart';
import 'checkout_screen.dart';
import 'widgets/quantity_stepper.dart';

class FoodComboScreen extends StatefulWidget {
  const FoodComboScreen({super.key, required this.booking});

  final BookingData booking;

  @override
  State<FoodComboScreen> createState() => _FoodComboScreenState();
}

class _FoodComboScreenState extends State<FoodComboScreen> {
  static const int _maxPerItem = 10;

  late final Future<List<Combo>> _future;
  List<Combo> _combos = const [];

  /// Giỏ hàng: comboId -> số lượng
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _future = CheckoutService.instance.getCombos();
  }

  int _qty(Combo c) => _cart[c.id] ?? 0;

  int get _comboTotal =>
      _combos.fold<int>(0, (sum, c) => sum + c.price * _qty(c));

  void _change(Combo combo, int delta) {
    final next = _qty(combo) + delta;
    if (next < 0 || next > _maxPerItem) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (next == 0) {
        _cart.remove(combo.id);
      } else {
        _cart[combo.id] = next;
      }
    });
  }

  void _goNext({bool skip = false}) {
    final selected = skip
        ? const <SelectedCombo>[]
        : _combos
            .where((c) => _qty(c) > 0)
            .map((c) => SelectedCombo(c, _qty(c)))
            .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          booking: widget.booking.copyWith(combos: selected),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bắp nước'),
        actions: [
          TextButton(
            onPressed: () => _goNext(skip: true),
            child: const Text('Bỏ qua'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_activity, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${booking.movie.title} • Ghế ${booking.seatLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Combo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Không tải được menu'));
                }
                _combos = snapshot.data ?? const [];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _combos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final combo = _combos[i];
                    return _ComboCard(
                      combo: combo,
                      quantity: _qty(combo),
                      onMinus: () => _change(combo, -1),
                      onPlus: () => _change(combo, 1),
                    );
                  },
                );
              },
            ),
          ),
          _SummaryBar(
            ticketTotal: booking.ticketTotal,
            comboTotal: _comboTotal,
            onNext: () => _goNext(),
          ),
        ],
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({
    required this.combo,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final Combo combo;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final active = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(combo.emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (combo.tag != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.couple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      combo.tag!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  combo.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  combo.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatVnd(combo.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityStepper(
            quantity: quantity,
            onMinus: onMinus,
            onPlus: onPlus,
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.ticketTotal,
    required this.comboTotal,
    required this.onNext,
  });

  final int ticketTotal;
  final int comboTotal;
  final VoidCallback onNext;

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
                    comboTotal > 0
                        ? 'Vé ${formatVnd(ticketTotal)} + Bắp nước ${formatVnd(comboTotal)}'
                        : 'Tạm tính',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVnd(ticketTotal + comboTotal),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('TIẾP TỤC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
