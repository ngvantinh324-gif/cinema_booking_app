# CineGo – Ứng dụng đặt vé xem phim (Flutter)

Đồ án môn **Lập trình trên thiết bị di động** – HUTECH. Nhóm 4 người: Tính (nhóm trưởng), Triết, Minh, Khôi.

Bản này là **Giai đoạn 1**: toàn bộ giao diện chạy được với dữ liệu giả lập (mock), chưa cần backend.

## Chạy demo

Yêu cầu: Flutter 3.27 trở lên (kiểm tra bằng `flutter --version`).

```bash
cd cinema_booking_app

# Chỉ chạy 1 lần: sinh thư mục android/ ios/ (không ghi đè code trong lib/)
flutter create . --org com.hutech --project-name cinema_booking_app --platforms android,ios

flutter pub get
flutter run
```

Tài khoản demo: **demo@hutech.edu.vn / 123456** (màn đăng nhập có nút điền nhanh).

Trước khi push code: chạy `flutter analyze` và `flutter test`.

## Kịch bản demo trước thầy (khoảng 3 phút)

1. Đăng nhập sai mật khẩu → báo lỗi; nhập email sai định dạng → form báo đỏ ngay.
2. Đăng nhập bằng tài khoản demo → Trang chủ: banner tự trượt, tab Đang chiếu / Sắp chiếu.
3. Bấm một phim → hiệu ứng Hero mở trang chi tiết, bấm **ĐẶT VÉ NGAY**.
4. Chọn ngày, rạp, giờ → sơ đồ ghế: chọn vài ghế thường + VIP + ghế đôi, tổng tiền nhảy theo thời gian thực, có thể zoom sơ đồ.
5. Chọn combo bắp nước → Thanh toán → **XÁC NHẬN ĐẶT VÉ** → vé điện tử có mã QR.
6. Quay lại đặt **đúng suất chiếu đó** lần nữa → các ghế vừa mua đã chuyển sang "Đã bán".
7. Tab **Vé của tôi** → vé mới nằm đầu danh sách. Tab **Tài khoản** → đổi mật khẩu, đăng xuất.

## Phân chia thư mục (mỗi người chỉ sửa file của mình)

| Người | File / thư mục |
| --- | --- |
| Tính | `main.dart`, `screens/main_shell.dart`, `screens/booking/`, `theme/`, `core/utils/formatters.dart`, `models/showtime.dart`, `models/seat.dart`, `models/booking_data.dart`, `services/api_config.dart`, `services/booking_service.dart`, `data/mock/mock_cinemas.dart` |
| Triết | `screens/home/`, `models/movie.dart`, `services/movie_service.dart`, `data/mock/mock_movies.dart`, `widgets/movie_poster.dart`, `widgets/age_badge.dart` |
| Minh | `screens/checkout/`, `models/combo.dart`, `services/checkout_service.dart`, `data/mock/mock_combos.dart` |
| Khôi | `screens/profile/`, `models/ticket.dart`, `models/app_user.dart`, `providers/`, `services/auth_service.dart`, `services/ticket_service.dart`, `core/utils/validators.dart`, `data/mock/mock_accounts.dart` |

`models/booking_data.dart` là **hợp đồng dữ liệu chung** của luồng đặt vé: muốn sửa phải báo cả nhóm.

## Chuyển sang Giai đoạn 2 (gọi API thật)

1. Thêm package `http` vào `pubspec.yaml`.
2. Đổi `ApiConfig.useMockData` thành `false` và sửa `baseUrl`.
3. Mỗi người viết phần gọi API trong service của mình (chỗ đang `throw UnimplementedError`). Màn hình giữ nguyên, không phải sửa.
