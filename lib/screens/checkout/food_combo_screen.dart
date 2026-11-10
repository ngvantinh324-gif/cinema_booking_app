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

enum _ComboFilter { all, comboOnly, singleOnly }

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
  _ComboFilter _selectedFilter = _ComboFilter.all;

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

  int get _totalItemsCount =>
      _cart.values.fold<int>(0, (sum, count) => sum + count);

  List<Combo> get _filteredCombos {
    switch (_selectedFilter) {
      case _ComboFilter.comboOnly:
        return _combos
            .where((c) => c.name.toLowerCase().contains('combo'))
            .toList();
      case _ComboFilter.singleOnly:
        return _combos
            .where((c) => !c.name.toLowerCase().contains('combo'))
            .toList();
      case _ComboFilter.all:
        return _combos;
    }
  }

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

  void _clearCart() {
    if (_cart.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(_cart.clear);
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
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Chọn Bắp & Nước',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'Bước 2/3 • Thêm combo thưởng thức phim',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _goNext(skip: true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bỏ qua',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thẻ tóm tắt thông tin vé đã chọn
          _TicketInfoBanner(
            movieTitle: booking.movie.title,
            seatLabel: booking.seatLabel,
            ticketTotal: booking.ticketTotal,
          ),

          // Bộ lọc danh mục bắp nước
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (filter) {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter);
            },
          ),

          // Danh sách combo
          Expanded(
            child: FutureBuilder<List<Combo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tải được menu bắp nước',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                _combos = snapshot.data ?? const [];
                final displayList = _filteredCombos;

                if (displayList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có sản phẩm trong mục này',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: displayList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final combo = displayList[i];
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

          // Thanh tổng kết & nút tiếp tục dưới đáy
          _SummaryBar(
            ticketTotal: booking.ticketTotal,
            comboTotal: _comboTotal,
            totalItemsCount: _totalItemsCount,
            onClear: _clearCart,
            onNext: () => _goNext(),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoBanner extends StatelessWidget {
  const _TicketInfoBanner({
    required this.movieTitle,
    required this.seatLabel,
    required this.ticketTotal,
  });

  final String movieTitle;
  final String seatLabel;
  final int ticketTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primary.withValues(alpha: 0.10),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.event_seat_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ghế: $seatLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formatVnd(ticketTotal),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
  });

  final _ComboFilter selected;
  final ValueChanged<_ComboFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _buildChip(
            label: 'Tất cả',
            icon: Icons.grid_view_rounded,
            filter: _ComboFilter.all,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Combo ưu đãi',
            icon: Icons.local_fire_department_rounded,
            filter: _ComboFilter.comboOnly,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Món lẻ',
            icon: Icons.fastfood_rounded,
            filter: _ComboFilter.singleOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required _ComboFilter filter,
  }) {
    final isSelected = selected == filter;
    return GestureDetector(
      onTap: () => onChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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

  bool get _isHotTag =>
      combo.tag != null && combo.tag!.toLowerCase().contains('bán chạy');

  @override
  Widget build(BuildContext context) {
    final active = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              active ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
          width: active ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: active ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Khung hình / Emoji sản phẩm có hiệu ứng phóng to khi chọn
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: active
                        ? [const Color(0xFFFFC371), const Color(0xFFFF5F6D)]
                        : [
                            const Color(0xFFFFB75E).withValues(alpha: 0.85),
                            const Color(0xFFED8F03).withValues(alpha: 0.85),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFED8F03).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn trang trí nền nhẹ
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    AnimatedScale(
                      scale: active ? 1.14 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        combo.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Text(
                      'x$quantity',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Thông tin chi tiết Combo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (combo.tag != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isHotTag
                            ? [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]
                            : [
                                AppColors.couple,
                                AppColors.couple.withValues(alpha: 0.75)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isHotTag
                              ? Icons.local_fire_department_rounded
                              : Icons.discount_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          combo.tag!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  combo.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  combo.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatVnd(combo.price),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (quantity > 1) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• ${formatVnd(combo.price * quantity)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primary.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bộ tăng giảm số lượng
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
    required this.totalItemsCount,
    required this.onClear,
    required this.onNext,
  });

  final int ticketTotal;
  final int comboTotal;
  final int totalItemsCount;
  final VoidCallback onClear;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final grandTotal = ticketTotal + comboTotal;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh phụ hiển thị khi đã chọn bắp nước
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: totalItemsCount > 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã chọn $totalItemsCount phần bắp nước (+${formatVnd(comboTotal)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: onClear,
                              child: const Text(
                                'Xoá chọn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Hàng chính: Tổng tiền + Nút Tiếp tục
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        comboTotal > 0
                            ? 'Vé ${formatVnd(ticketTotal)} + Combo ${formatVnd(comboTotal)}'
                            : 'Tạm tính (chưa gồm bắp nước)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          formatVnd(grandTotal),
                          key: ValueKey<int>(grandTotal),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  height: 48,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TIẾP TỤC',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
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
