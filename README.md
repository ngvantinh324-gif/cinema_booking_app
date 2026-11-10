# CineGo – Ứng dụng đặt vé xem phim

Đồ án cuối kỳ học phần **Lập trình trên thiết bị di động (CMP177)** – Trường Đại học Công nghệ TP.HCM (HUTECH).
Giảng viên phụ trách: ThS. Bùi Phú Khuyên.

CineGo cho phép người dùng xem phim đang chiếu / sắp chiếu, chọn suất chiếu, chọn ghế, mua bắp nước, áp dụng mã giảm giá và nhận vé điện tử có mã QR.

## Thành viên nhóm

| Họ và tên | MSSV | Phụ trách |
| --- | --- | --- |
| Nguyễn Văn Tính (nhóm trưởng) | 2380614852 | Khung ứng dụng, chọn suất chiếu, sơ đồ ghế, cấu hình Supabase |
| Phạm Minh Triết | 2380605829 | Trang chủ, tìm kiếm, chi tiết phim, TMDB API, trailer |
| Nguyễn Hoàng Minh | 2380601355 | Bắp nước, thanh toán, mã giảm giá |
| Phạm Thái Khôi | 2380601102 | Đăng ký / đăng nhập (xác thực email), vé điện tử, lịch sử vé, hồ sơ |

## Công nghệ sử dụng

| Thành phần | Công nghệ |
| --- | --- |
| Ứng dụng di động | Flutter / Dart |
| Quản lý trạng thái | Provider |
| Backend / API | Supabase (REST API tự sinh) |
| Cơ sở dữ liệu | PostgreSQL (Supabase), bảo mật bằng Row Level Security |
| Xác thực | Supabase Auth (đăng ký có xác thực email) |
| Dữ liệu phim | TMDB API |
| Thư viện khác | supabase_flutter, qr_flutter, youtube_player_iframe |

Thanh toán trong ứng dụng là **thanh toán giả lập**, không trừ tiền thật. Lịch chiếu được sinh tự động theo ngày.

## Chức năng chính

- Đăng ký tài khoản có gửi email xác nhận, đăng nhập, ghi nhớ phiên đăng nhập
- Cập nhật họ tên, số điện thoại; đổi mật khẩu; đăng xuất
- Danh sách phim thật đang chiếu / sắp chiếu từ TMDB; tìm kiếm phim không dấu
- Chi tiết phim: đạo diễn, diễn viên, nội dung, xem trailer ngay trong ứng dụng
- Chọn ngày, rạp, suất chiếu (7 ngày tới, theo giờ thực)
- Sơ đồ ghế 3 loại (thường, VIP, đôi), tính tiền tức thì, chống bán trùng ghế giữa nhiều thiết bị
- Chọn combo bắp nước, áp dụng mã giảm giá kiểm tra trên máy chủ
- Vé điện tử có mã QR, lưu trên cơ sở dữ liệu
- Lịch sử vé: đếm ngược tới giờ chiếu, tự chuyển sang "Đã xem"

## Cách chạy

Yêu cầu: Flutter 3.27 trở lên, máy ảo Android hoặc điện thoại Android.

```bash
git clone https://github.com/ngvantinh324-gif/cinema_booking_app.git
cd cinema_booking_app
flutter pub get
```

**Có key TMDB (phim thật):**

1. Đăng ký key miễn phí tại https://www.themoviedb.org/settings/api
2. Copy `tmdb.example.json` thành `tmdb.json` (cùng thư mục với README), dán key vào. File `tmdb.json` đã nằm trong `.gitignore`, **không commit file này**.
3. Chạy:

```bash
flutter run --dart-define-from-file=tmdb.json
```

**Không có key TMDB:** chạy `flutter run` bình thường, ứng dụng tự dùng danh sách phim lưu trên Supabase.

**Tài khoản demo:** ở màn hình đăng nhập, **nhấn giữ chữ "CineGo"** để điền nhanh tài khoản demo rồi bấm Đăng nhập.

## Cấu trúc thư mục

```
lib/
├── main.dart            Khởi tạo Supabase, Provider, cổng đăng nhập
├── models/              Movie, Showtime, Seat, BookingData, Combo, Voucher, Ticket, AppUser
├── services/            Gọi API: Supabase (auth, ghế, vé, combo, mã giảm giá), TMDB (phim)
├── providers/           AuthProvider, TicketProvider
├── screens/
│   ├── home/            Trang chủ, tìm kiếm, chi tiết phim, trailer
│   ├── booking/         Chọn suất chiếu, sơ đồ ghế
│   ├── checkout/        Bắp nước, thanh toán, mã giảm giá
│   └── profile/         Đăng nhập, đăng ký, vé của tôi, vé QR, hồ sơ
├── widgets/             Widget dùng chung
└── theme/               Màu sắc, giao diện
test/                    Unit test và widget test
```

## Cơ sở dữ liệu (Supabase)

| Bảng | Nội dung |
| --- | --- |
| `movies` | Danh sách phim dự phòng khi không dùng TMDB |
| `combos` | Menu bắp nước |
| `vouchers` | Mã giảm giá (phần trăm, mức giảm tối đa, đơn tối thiểu, hạn dùng) |
| `booked_seats` | Ghế đã bán; khóa chính (suất chiếu, ghế) chống bán trùng |
| `tickets` | Vé đã đặt; Row Level Security chỉ cho người dùng xem vé của chính mình |

Ứng dụng chỉ dùng **publishable key** của Supabase (được phép công khai); dữ liệu được bảo vệ bằng Row Level Security.

## Kiểm thử

```bash
flutter analyze
flutter test
```
