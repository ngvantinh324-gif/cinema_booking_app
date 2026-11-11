// Người phụ trách: Khôi - Quản trị viên quản lý mã giảm giá
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class VoucherManageScreen extends StatefulWidget {
  const VoucherManageScreen({super.key});

  @override
  State<VoucherManageScreen> createState() => _VoucherManageScreenState();
}

class _VoucherManageScreenState extends State<VoucherManageScreen> {
  late Future<List<AdminVoucher>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listVouchers();
  }

  void _reload() {
    setState(() {
      _future = AdminService.instance.listVouchers();
    });
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
    );
  }

  Future<void> _toggle(AdminVoucher v, bool active) async {
    try {
      await AdminService.instance.setVoucherActive(v.voucher.code, active);
      _reload();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _delete(AdminVoucher v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mã giảm giá'),
        content: Text('Xóa mã ${v.voucher.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.instance.deleteVoucher(v.voucher.code);
      _reload();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddVoucherSheet(),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mã giảm giá')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mã'),
      ),
      body: FutureBuilder<List<AdminVoucher>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          final list = snapshot.data ?? const <AdminVoucher>[];
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có mã giảm giá'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = list[i];
              final v = item.voucher;
              final details = [
                'Giảm ${v.percent}%',
                if (v.maxDiscount > 0) 'tối đa ${formatVnd(v.maxDiscount)}',
                if (v.minOrder > 0) 'đơn từ ${formatVnd(v.minOrder)}',
                if (v.expiresAt != null)
                  '${v.isExpired ? 'đã hết hạn' : 'hạn'} ${formatDate(v.expiresAt!.toLocal())}',
              ].join(' • ');
              return Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (v.description.isNotEmpty)
                            Text(
                              v.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.active,
                      onChanged: (value) => _toggle(item, value),
                    ),
                    IconButton(
                      tooltip: 'Xóa',
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddVoucherSheet extends StatefulWidget {
  const _AddVoucherSheet();

  @override
  State<_AddVoucherSheet> createState() => _AddVoucherSheetState();
}

class _AddVoucherSheetState extends State<_AddVoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _desc = TextEditingController();
  final _percent = TextEditingController(text: '10');
  final _max = TextEditingController(text: '0');
  final _min = TextEditingController(text: '0');
  final _days = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_code, _desc, _percent, _max, _min, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _int(String? v, {int min = 0, int? max}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Nhập số';
    if (n < min) return 'Tối thiểu $min';
    if (max != null && n > max) return 'Tối đa $max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final days = int.tryParse(_days.text.trim());
    try {
      await AdminService.instance.addVoucher(
        code: _code.text,
        description: _desc.text,
        percent: int.parse(_percent.text.trim()),
        maxDiscount: int.parse(_max.text.trim()),
        minOrder: int.parse(_min.text.trim()),
        expiresAt:
            days == null ? null : DateTime.now().add(Duration(days: days)),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thêm mã giảm giá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: _dec('Mã (vd SINHVIEN20)'),
                validator: (v) =>
                    RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch((v ?? '').trim())
                        ? null
                        : '3–20 ký tự chữ hoặc số, không dấu cách',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: _dec('Mô tả'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _percent,
                      keyboardType: TextInputType.number,
                      decoration: _dec('% giảm'),
                      validator: (v) => _int(v, min: 1, max: 100),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _days,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Số ngày hiệu lực'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? null : _int(v, min: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _max,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Giảm tối đa (0 = không giới hạn)'),
                      validator: (v) => _int(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _min,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Đơn tối thiểu'),
                      validator: (v) => _int(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('LƯU MÃ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
