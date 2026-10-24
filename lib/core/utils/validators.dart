// Người phụ trách: Khôi - kiểm tra dữ liệu form bằng regex

class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  // Số di động VN: bắt đầu 0 hoặc +84, đầu số 3/5/7/8/9, theo sau 8 chữ số
  static final RegExp _phone = RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập email';
    if (!_email.hasMatch(v)) return 'Email không đúng định dạng';
    return null;
  }

  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  /// Dùng khi đăng ký / đổi mật khẩu: tối thiểu 6 ký tự, có cả chữ và số.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    if (!_hasLetter.hasMatch(v) || !_hasDigit.hasMatch(v)) {
      return 'Mật khẩu phải có cả chữ và số';
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập họ tên';
    if (v.length < 2) return 'Họ tên quá ngắn';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phone.hasMatch(v)) return 'Số điện thoại không hợp lệ';
    return null;
  }

  /// Trả về một validator so sánh với mật khẩu gốc.
  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu';
      if (value != original()) return 'Mật khẩu nhập lại không khớp';
      return null;
    };
  }
}
