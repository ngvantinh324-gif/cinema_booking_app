// Người phụ trách: Khôi - tài khoản giả lập
//
// LƯU Ý BẢO MẬT: mật khẩu để dạng chữ thường CHỈ dùng cho demo giai đoạn 1.
// Backend thật phải lưu mật khẩu đã hash (bcrypt) và không bao giờ trả về
// mật khẩu cho app.
import '../../models/app_user.dart';

class MockAccount {
  final AppUser user;
  String password;

  MockAccount(this.user, this.password);
}

final List<MockAccount> mockAccounts = [
  MockAccount(
    const AppUser(
      id: 'u1',
      name: 'Nguyễn Văn An',
      email: 'demo@hutech.edu.vn',
      phone: '0901234567',
    ),
    '123456',
  ),
];
