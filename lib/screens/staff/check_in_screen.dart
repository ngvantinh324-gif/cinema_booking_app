// Người phụ trách: Khôi - màn hình Nhân viên soát vé
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _codeCtrl = TextEditingController();
  StaffTicket? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Nhập mã vé in dưới mã QR');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final t = await AdminService.instance.findTicket(code);
      if (!mounted) return;
      setState(() {
        _result = t;
        _error = t == null ? 'Không tìm thấy vé $code' : null;
      });
    } on AdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    final current = _result;
    if (current == null) return;
    setState(() => _loading = true);
    try {
      final t = await AdminService.instance.checkIn(current.ticket.id);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _result = t);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận khách vào rạp')),
      );
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Soát vé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Nhập mã vé in bên dưới mã QR trên vé điện tử của khách.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _find(),
                  decoration: InputDecoration(
                    hintText: 'Mã vé, ví dụ CGABC123',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _loading ? null : _find,
                  child: const Text('Tìm'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (r != null && !_loading) ...[
            const SizedBox(height: 20),
            _TicketResultCard(item: r),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: r.isCheckedIn ? null : _checkIn,
              icon: Icon(r.isCheckedIn ? Icons.verified : Icons.login),
              label: Text(
                r.isCheckedIn ? 'VÉ ĐÃ ĐƯỢC SOÁT' : 'XÁC NHẬN VÀO RẠP',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketResultCard extends StatelessWidget {
  const _TicketResultCard({required this.item});

  final StaffTicket item;

  @override
  Widget build(BuildContext context) {
    final t = item.ticket;
    final s = t.showtime;
    final checked = item.checkedInAt;
    final statusColor = checked != null ? AppColors.success : AppColors.primary;

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.movie.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  checked != null ? 'Đã soát' : 'Chưa soát',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          line('Mã vé', t.id),
          line('Rạp', '${s.cinema.name} • ${s.room}'),
          line(
            'Suất chiếu',
            '${formatTime(s.startTime)} • ${weekdayLabel(s.startTime)}, ${formatDate(s.startTime)}',
          ),
          line('Ghế', t.seatLabel),
          if (t.combos.isNotEmpty) line('Bắp nước', t.comboLabel),
          line('Tổng tiền', formatVnd(t.totalPaid)),
          if (checked != null)
            line('Soát lúc', '${formatTime(checked)} • ${formatDate(checked)}'),
        ],
      ),
    );
  }
}
