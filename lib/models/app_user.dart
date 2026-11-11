// Người phụ trách: Khôi

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  /// customer | staff | admin (lưu trong app_metadata, người dùng không tự sửa được)
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
  });

  bool get isAdmin => role == 'admin';

  /// Nhân viên hoặc quản trị viên đều được soát vé
  bool get isStaff => role == 'staff' || role == 'admin';

  String get roleLabel => switch (role) {
        'admin' => 'Quản trị viên',
        'staff' => 'Nhân viên',
        _ => 'Khách hàng',
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
      );

  /// Tạo bản sao với họ tên / SĐT mới (id, email, vai trò giữ nguyên)
  AppUser copyWith({String? name, String? phone}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
      );
}
