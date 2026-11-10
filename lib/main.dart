// Người phụ trách: Tính (Nhóm trưởng)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/main_shell.dart';
import 'screens/profile/login_screen.dart';
import 'services/api_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    publishableKey: ApiConfig.supabaseKey,
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
      home: const AuthGate(),
    );
  }
}

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