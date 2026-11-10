// Người phụ trách: Tính (Nhóm trưởng)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/main_shell.dart';
import 'screens/profile/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Đảm bảo các dịch vụ nền tảng của Flutter Engine sẵn sàng trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo kết nối Firebase theo cấu hình đa nền tảng
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: const CinemaApp(),
    ),
  );
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Khi nộp bài/demo đầy đủ: dùng AuthGate()
      // Nếu muốn test nhanh riêng màn hình của Tính: đổi thành const MainShell()
      home: const AuthGate(),
    );
  }
}

/// Cổng xác thực:
/// - Chưa đăng nhập -> LoginScreen (Khôi)
/// - Đã đăng nhập -> MainShell (Tính)
/// Tự động chuyển màn hình mượt mà khi trạng thái người dùng thay đổi.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121420),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: user == null
            ? const LoginScreen(key: ValueKey('login'))
            : MainShell(key: ValueKey(user.id)),
      ),
    );
  }
}