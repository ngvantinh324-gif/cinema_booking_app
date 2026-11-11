// Người phụ trách: Khôi - nghiệp vụ Nhân viên (soát vé) & Quản trị viên
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ticket.dart';
import '../models/voucher.dart';

class AdminStats {
  final int tickets;
  final int revenue;
  final int today;
  final int checkedIn;
  final int customers;

  const AdminStats({
    required this.tickets,
    required this.revenue,
    required this.today,
    required this.checkedIn,
    required this.customers,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        tickets: (j['tickets'] as num? ?? 0).toInt(),
        revenue: (j['revenue'] as num? ?? 0).toInt(),
        today: (j['today'] as num? ?? 0).toInt(),
        checkedIn: (j['checked_in'] as num? ?? 0).toInt(),
        customers: (j['customers'] as num? ?? 0).toInt(),
      );
}

/// Vé kèm thông tin soát vé (dành cho nhân viên / quản trị viên)
class StaffTicket {
  final Ticket ticket;
  final DateTime? checkedInAt;
  final DateTime createdAt;

  const StaffTicket({
    required this.ticket,
    required this.checkedInAt,
    required this.createdAt,
  });

  bool get isCheckedIn => checkedInAt != null;
}

/// Mã giảm giá kèm trạng thái bật/tắt
class AdminVoucher {
  final Voucher voucher;
  final bool active;

  const AdminVoucher(this.voucher, this.active);
}

class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  StaffTicket _toStaffTicket(Map<String, dynamic> row) => StaffTicket(
        ticket: Ticket.fromJson(
          row['data'] as Map<String, dynamic>,
          userId: row['user_id'] as String,
        ),
        checkedInAt: DateTime.tryParse(row['checked_in_at']?.toString() ?? '')
            ?.toLocal(),
        createdAt:
            DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
      );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const AdminException('Mã này đã tồn tại');
      if (e.code == '42501') {
        throw const AdminException('Tài khoản không có quyền thực hiện');
      }
      throw AdminException(e.message);
    }
  }

  // ---------------- Thống kê: POST /rest/v1/rpc/admin_stats ----------------
  Future<AdminStats> getStats() => _guard(() async {
        final res = await _db.rpc('admin_stats');
        return AdminStats.fromJson(Map<String, dynamic>.from(res as Map));
      });

  // ---------------- Vé (RLS: chỉ staff/admin xem được toàn bộ) ----------------
  Future<List<StaffTicket>> recentTickets({int limit = 30}) => _guard(() async {
        final rows = await _db
            .from('tickets')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(_toStaffTicket).toList();
      });

  Future<StaffTicket?> findTicket(String code) => _guard(() async {
        final row = await _db
            .from('tickets')
            .select()
            .eq('id', code.trim().toUpperCase())
            .maybeSingle();
        return row == null ? null : _toStaffTicket(row);
      });

  /// Soát vé: POST /rest/v1/rpc/staff_check_in (server kiểm tra quyền và
  /// đảm bảo mỗi vé chỉ được soát 1 lần)
  Future<StaffTicket> checkIn(String code) => _guard(() async {
        final res = await _db.rpc('staff_check_in', params: {'p_code': code});
        return _toStaffTicket(Map<String, dynamic>.from(res as Map));
      });

  // ---------------- Mã giảm giá (RLS: chỉ admin được ghi) ----------------
  Future<List<AdminVoucher>> listVouchers() => _guard(() async {
        final rows = await _db.from('vouchers').select().order('code');
        return rows
            .map((r) => AdminVoucher(
                  Voucher.fromJson(r),
                  r['active'] as bool? ?? true,
                ))
            .toList();
      });

  Future<void> addVoucher({
    required String code,
    required String description,
    required int percent,
    required int maxDiscount,
    required int minOrder,
    DateTime? expiresAt,
  }) =>
      _guard(() async {
        await _db.from('vouchers').insert({
          'code': code.trim().toUpperCase(),
          'description': description.trim(),
          'percent': percent,
          'max_discount': maxDiscount,
          'min_order': minOrder,
          'expires_at': expiresAt?.toUtc().toIso8601String(),
        });
      });

  Future<void> setVoucherActive(String code, bool active) => _guard(() async {
        await _db.from('vouchers').update({'active': active}).eq('code', code);
      });

  Future<void> deleteVoucher(String code) => _guard(() async {
        await _db.from('vouchers').delete().eq('code', code);
      });
}
