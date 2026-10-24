// Người phụ trách: Khôi - đăng nhập / đăng ký / đổi mật khẩu
import '../data/mock/mock_accounts.dart';
import '../models/app_user.dart';
import 'api_config.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const Duration _delay = Duration(milliseconds: 800);

  MockAccount? _findByEmail(String email) {
    final key = email.trim().toLowerCase();
    for (final acc in mockAccounts) {
      if (acc.user.email.toLowerCase() == key) return acc;
    }
    return null;
  }

  /// POST /api/auth/login  -> {token, user}
  Future<AppUser> login(String email, String password) async {
    _ensureMock();
    await Future.delayed(_delay);
    final acc = _findByEmail(email);
    // Cùng một thông báo cho cả "sai email" và "sai mật khẩu"
    // để kẻ xấu không dò được email nào đã đăng ký.
    if (acc == null || acc.password != password) {
      throw const AuthException('Email hoặc mật khẩu không đúng');
    }
    return acc.user;
  }

  /// POST /api/auth/register
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _ensureMock();
    await Future.delayed(_delay);
    if (_findByEmail(email) != null) {
      throw const AuthException('Email này đã được sử dụng');
    }
    final user = AppUser(
      id: 'u${mockAccounts.length + 1}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );
    mockAccounts.add(MockAccount(user, password));
    return user;
  }

  /// PUT /api/auth/change-password
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    _ensureMock();
    await Future.delayed(_delay);
    for (final acc in mockAccounts) {
      if (acc.user.id == userId) {
        if (acc.password != currentPassword) {
          throw const AuthException('Mật khẩu hiện tại không đúng');
        }
        acc.password = newPassword;
        return;
      }
    }
    throw const AuthException('Không tìm thấy tài khoản');
  }

  void _ensureMock() {
    if (!ApiConfig.useMockData) {
      throw UnimplementedError('Chưa kết nối API xác thực');
    }
  }
}
