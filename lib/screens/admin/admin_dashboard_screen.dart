// Người phụ trách: Khôi - trang Quản trị viên
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../staff/check_in_screen.dart';
import 'voucher_manage_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<(AdminStats, List<StaffTicket>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(AdminStats, List<StaffTicket>)> _load() async {
    final stats = await AdminService.instance.getStats();
    final tickets = await AdminService.instance.recentTickets();
    return (stats, tickets);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  void _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang quản trị')),
      body: FutureBuilder<(AdminStats, List<StaffTicket>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    TextButton(
                        onPressed: _refresh, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }
          final (stats, tickets) = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Vé đã bán',
                        value: '${stats.tickets}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: 'Doanh thu',
                        value: formatVnd(stats.revenue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.today_outlined,
                        label: 'Vé bán hôm nay',
                        value: '${stats.today}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.verified_outlined,
                        label: 'Đã soát vé',
                        value: '${stats.checkedIn}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ActionTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Quản lý mã giảm giá',
                  onTap: () => _open(const VoucherManageScreen()),
                ),
                _ActionTile(
                  icon: Icons.qr_code_scanner,
                  title: 'Soát vé',
                  onTap: () => _open(const CheckInScreen()),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vé bán gần đây (${stats.customers} khách hàng)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Chưa có vé nào',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                for (final item in tickets) _TicketRow(item: item),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.item});

  final StaffTicket item;

  @override
  Widget build(BuildContext context) {
    final t = item.ticket;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.id} • Ghế ${t.seatLabel} • ${formatTime(item.createdAt)} ${formatDate(item.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVnd(t.totalPaid),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.isCheckedIn ? 'Đã soát' : 'Chưa soát',
                style: TextStyle(
                  fontSize: 11,
                  color: item.isCheckedIn
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
