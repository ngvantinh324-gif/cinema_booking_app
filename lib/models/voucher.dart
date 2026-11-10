// Người phụ trách: Minh - mã giảm giá

class VoucherException implements Exception {
  final String message;

  const VoucherException(this.message);

  @override
  String toString() => message;
}

class Voucher {
  final String code;
  final String description;
  final int percent; // % giảm
  final int maxDiscount; // giảm tối đa (0 = không giới hạn)
  final int minOrder; // đơn tối thiểu để dùng mã
  final DateTime? expiresAt;

  const Voucher({
    required this.code,
    required this.description,
    required this.percent,
    required this.maxDiscount,
    required this.minOrder,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Số tiền được giảm cho một đơn hàng
  int discountFor(int subtotal) {
    if (subtotal < minOrder) return 0;
    final discount = subtotal * percent ~/ 100;
    if (maxDiscount > 0 && discount > maxDiscount) return maxDiscount;
    return discount;
  }

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        code: json['code'] as String,
        description: json['description'] as String? ?? '',
        percent: (json['percent'] as num).toInt(),
        maxDiscount: (json['max_discount'] as num?)?.toInt() ?? 0,
        minOrder: (json['min_order'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      );
}
