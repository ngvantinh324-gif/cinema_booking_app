// Người phụ trách: Tính (Nhóm trưởng)

class ApiConfig {
  ApiConfig._();

  /// true  = Giai đoạn 1: dùng dữ liệu giả lập trong lib/data/mock
  /// false = Giai đoạn 2: gọi REST API thật bằng package http
  static const bool useMockData = true;

  /// 10.0.2.2 là địa chỉ máy tính khi chạy trên Android Emulator.
  /// Chạy trên điện thoại thật thì đổi thành IP LAN của máy chạy server.
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  /// Giả lập độ trễ mạng để thấy loading indicator
  static const Duration mockDelay = Duration(milliseconds: 500);
}
