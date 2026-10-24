// Người phụ trách: Tính (Nhóm trưởng) - các hàm định dạng dùng chung

/// 95000 -> "95.000đ"
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign${buffer.toString()}đ';
}

String pad2(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${pad2(d.day)}/${pad2(d.month)}/${d.year}';

String formatTime(DateTime d) => '${pad2(d.hour)}:${pad2(d.minute)}';

const _weekdays = [
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
  'Chủ nhật',
];
const _shortWeekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String weekdayLabel(DateTime d) => _weekdays[d.weekday - 1];

String shortWeekdayLabel(DateTime d) => _shortWeekdays[d.weekday - 1];

/// "Nguyễn Văn An" -> "VA"
String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
}
