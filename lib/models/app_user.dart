// Người phụ trách: Khôi

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}
