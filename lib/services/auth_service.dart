// Người phụ trách: Khôi - xác thực bằng Supabase Auth
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/app_user.dart';

/// Lỗi đã được dịch sang tiếng Việt để hiển thị cho người dùng
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  /// Phiên đăng nhập đã lưu trên máy (mở lại app không phải đăng nhập lại)
  AppUser? currentUser() {
    final user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  /// POST /auth/v1/token?grant_type=password
  Future<AppUser> login(String email, String password) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(res.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  /// POST /auth/v1/signup. Supabase tự gửi email chứa link xác nhận.
  /// Trả về null nếu tài khoản phải xác nhận email trước khi đăng nhập.
  Future<AppUser?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim(), 'phone': phone.trim()},
      );
      final user = res.user;
      // Email đã đăng ký: Supabase trả về user không có identity nào
      if (user != null && (user.identities?.isEmpty ?? false)) {
        throw const AuthException('Email này đã được sử dụng');
      }
      if (res.session == null || user == null) return null;
      return _toAppUser(user);
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  /// PUT /auth/v1/user  (lưu họ tên, SĐT vào user_metadata)
  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _auth.updateUser(
        sb.UserAttributes(data: {'name': name.trim(), 'phone': phone.trim()}),
      );
      return _toAppUser(res.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  /// Kiểm tra mật khẩu hiện tại bằng cách đăng nhập lại, rồi mới đổi.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _auth.currentUser?.email;
    if (email == null) throw const AuthException('Bạn chưa đăng nhập');
    try {
      await _auth.signInWithPassword(email: email, password: currentPassword);
    } on sb.AuthException {
      throw const AuthException('Mật khẩu hiện tại không đúng');
    }
    try {
      await _auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  AppUser _toAppUser(sb.User u) {
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final email = u.email ?? '';
    return AppUser(
      id: u.id,
      name: meta['name'] as String? ?? email.split('@').first,
      email: email,
      phone: meta['phone'] as String? ?? '',
    );
  }

  String _translate(sb.AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      // Báo chung để kẻ xấu không dò được email nào đã đăng ký
      return 'Email hoặc mật khẩu không đúng';
    }
    if (m.contains('not confirmed')) {
      return 'Email chưa được xác nhận. Hãy mở email và bấm vào link xác nhận';
    }
    if (m.contains('already registered')) return 'Email này đã được sử dụng';
    if (m.contains('rate limit') || e.statusCode == '429') {
      return 'Gửi email quá nhiều lần, vui lòng thử lại sau';
    }
    if (m.contains('should be different')) {
      return 'Mật khẩu mới phải khác mật khẩu cũ';
    }
    return 'Lỗi xác thực: ${e.message}';
  }
}
