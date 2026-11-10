// Người phụ trách: Khôi - trạng thái đăng nhập dùng chung toàn app
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Khôi phục phiên đăng nhập đã lưu trên máy
    _user = _service.currentUser();
  }

  final AuthService _service = AuthService.instance;

  AppUser? _user;
  bool _loading = false;

  AppUser? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;

  /// Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _service.login(email, password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Không kết nối được máy chủ, kiểm tra lại mạng';
    } finally {
      _setLoading(false);
    }
  }

  /// error: thông báo lỗi (nếu có)
  /// needsConfirm: true nếu phải mở email xác nhận rồi mới đăng nhập được
  Future<({String? error, bool needsConfirm})> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final user = await _service.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      if (user != null) _user = user;
      return (error: null, needsConfirm: user == null);
    } on AuthException catch (e) {
      return (error: e.message, needsConfirm: false);
    } catch (_) {
      return (error: 'Không kết nối được máy chủ', needsConfirm: false);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> changePassword(String current, String newPassword) async {
    if (_user == null) return 'Bạn chưa đăng nhập';
    try {
      await _service.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Cập nhật họ tên & SĐT. Các màn đang watch AuthProvider tự vẽ lại.
  Future<String?> updateProfile(String name, String phone) async {
    if (_user == null) return 'Bạn chưa đăng nhập';
    try {
      _user = await _service.updateProfile(name: name, phone: phone);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  void logout() {
    _service.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
