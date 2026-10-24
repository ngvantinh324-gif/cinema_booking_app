// Người phụ trách: Khôi - trạng thái đăng nhập dùng chung toàn app
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
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
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user = await _service.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> changePassword(String current, String newPassword) async {
    final user = _user;
    if (user == null) return 'Bạn chưa đăng nhập';
    try {
      await _service.changePassword(
        userId: user.id,
        currentPassword: current,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
