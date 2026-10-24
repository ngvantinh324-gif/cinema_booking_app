// Người phụ trách: Tính (Nhóm trưởng)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/main_shell.dart';
import 'screens/profile/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
      home: const AuthGate(),
    );
  }
}

/// Cổng xác thực: chưa đăng nhập -> LoginScreen (Khôi),
/// đã đăng nhập -> MainShell (Tính). Tự đổi khi AuthProvider thay đổi.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: user == null
          ? const LoginScreen(key: ValueKey('login'))
          : MainShell(key: ValueKey(user.id)),
    );
  }
}
