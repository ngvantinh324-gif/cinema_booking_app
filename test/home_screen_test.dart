import 'package:cinema_booking_app/data/mock/mock_movies.dart';
import 'package:cinema_booking_app/models/app_user.dart';
import 'package:cinema_booking_app/providers/auth_provider.dart';
import 'package:cinema_booking_app/screens/home/home_screen.dart';
import 'package:cinema_booking_app/screens/home/movie_search.dart';
import 'package:cinema_booking_app/screens/home/widgets/home_skeleton.dart';
import 'package:cinema_booking_app/screens/home/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// AuthProvider thật cần Supabase đã khởi tạo; trang chủ chỉ đọc tên người dùng
class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AppUser? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => ChangeNotifierProvider<AuthProvider>(
      create: (_) => _FakeAuthProvider(),
      child: const MaterialApp(home: HomeScreen()),
    );

/// Màn hình cỡ điện thoại (360x780) thay vì 800x600 mặc định của test
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder _cardTitle(String title) => find.descendant(
      of: find.byType(MovieCard),
      matching: find.text(title),
    );

/// Dữ liệu mock có độ trễ giả lập 500ms
Future<void> _waitForMovies(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Tìm kiếm không dấu', () {
    test('foldVietnamese bỏ dấu và viết thường', () {
      expect(foldVietnamese('Đấu Trường Sinh Tử'), 'dau truong sinh tu');
      expect(foldVietnamese('Mèo Mập Đi Lạc'), 'meo map di lac');
      expect(foldVietnamese('Ỳ ỹ Ữ ợ'), 'y y u o');
      // Chữ có dấu dạng tổ hợp (e + dấu huyền)
      expect(foldVietnamese('Mèo'), 'meo');
    });

    test('movieMatches tìm theo tên, thể loại, diễn viên', () {
      final meo = mockMovies.firstWhere((m) => m.title == 'Mèo Mập Đi Lạc');
      expect(movieMatches(meo, ''), isTrue);
      expect(movieMatches(meo, 'meo map'), isTrue);
      expect(movieMatches(meo, 'MẬP'), isTrue);
      expect(movieMatches(meo, 'hoat hinh'), isTrue); // thể loại
      expect(movieMatches(meo, 'nguyen thu ha'), isTrue); // đạo diễn
      expect(movieMatches(meo, 'kinh di'), isFalse);
    });
  });

  testWidgets('Đang tải thì hiện khung xương, tải xong hiện lưới phim',
      (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_app());
    expect(find.byType(HomeSkeleton), findsOneWidget);

    await _waitForMovies(tester);
    expect(find.byType(HomeSkeleton), findsNothing);
    expect(find.text('Đang chiếu'), findsOneWidget);
    expect(_cardTitle('Mèo Mập Đi Lạc'), findsOneWidget);
  });

  testWidgets('Gõ tìm kiếm không dấu lọc được lưới phim', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_app());
    await _waitForMovies(tester);

    await tester.tap(find.byTooltip('Tìm phim'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'meo map');
    await tester.pump(const Duration(milliseconds: 400));

    expect(_cardTitle('Mèo Mập Đi Lạc'), findsOneWidget);
    expect(_cardTitle('Bóng Ma Chợ Lớn'), findsNothing);
    expect(find.text('Đang chiếu (1)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'khong co phim nay');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Không tìm thấy phim phù hợp'), findsOneWidget);

    // Đóng tìm kiếm -> hiện lại đủ phim
    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TextField), findsNothing);
    expect(_cardTitle('Bóng Ma Chợ Lớn'), findsOneWidget);
  });

  testWidgets('Kéo lưới phim xuống thì hiện vòng tải lại', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_app());
    await _waitForMovies(tester);

    await tester.fling(
      _cardTitle('Hành Tinh Cát Đỏ'),
      const Offset(0, 500),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    // Tải xong thì vòng tải biến mất, danh sách vẫn còn
    await _waitForMovies(tester);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // hiệu ứng thu vòng tải
    }
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(_cardTitle('Hành Tinh Cát Đỏ'), findsOneWidget);
  });
}
