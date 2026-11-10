// Người phụ trách: Tính (Nhóm trưởng)

class ApiConfig {
  ApiConfig._();

  /// Backend: Supabase (PostgreSQL + REST API tự sinh + Authentication).
  /// Lấy ở Supabase Dashboard -> Project Settings -> API Keys.
  static const String supabaseUrl = 'https://tnsebitpvzkfcxcsljku.supabase.co';

  /// CHỈ dán Publishable key (sb_publishable_...). Key này được phép nằm
  /// trong app vì dữ liệu đã được bảo vệ bằng Row Level Security.
  /// TUYỆT ĐỐI không dán Secret key / service_role key.
  static const String supabaseKey = 'sb_publishable_0cvsdV3ScVznebLSjlSAvw_q7eEBtYM';

  /// Cờ cũ của giai đoạn 1. Các service đã chuyển sang Supabase không dùng
  /// cờ này nữa; giữ lại để code cũ chưa cập nhật vẫn biên dịch được.
  static const bool useMockData = true;

  static const Duration mockDelay = Duration(milliseconds: 500);
}