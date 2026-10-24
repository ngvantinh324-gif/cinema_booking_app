import 'package:cinema_booking_app/core/utils/formatters.dart';
import 'package:cinema_booking_app/core/utils/validators.dart';
import 'package:cinema_booking_app/models/seat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatVnd định dạng tiền Việt', () {
    expect(formatVnd(95000), '95.000đ');
    expect(formatVnd(1250000), '1.250.000đ');
    expect(formatVnd(0), '0đ');
  });

  test('Validators kiểm tra email và mật khẩu', () {
    expect(Validators.email('abc'), isNotNull);
    expect(Validators.email('sv@hutech.edu.vn'), isNull);
    expect(Validators.newPassword('123456'), isNotNull); // thiếu chữ
    expect(Validators.newPassword('abc123'), isNull);
    expect(Validators.phone('0901234567'), isNull);
    expect(Validators.phone('0123'), isNotNull);
  });

  test('Giá ghế theo loại', () {
    expect(seatPrice(SeatType.normal, 85000), 85000);
    expect(seatPrice(SeatType.vip, 85000), 105000);
    expect(seatPrice(SeatType.couple, 85000), 190000);
  });
}
