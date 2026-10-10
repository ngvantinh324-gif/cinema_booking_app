import 'package:flutter/material.dart';
import 'screens/booking/showtime_screen.dart';

void main() {
  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt Vé Phim - HUTECH',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111D),
        primaryColor: const Color(0xFFFF8C00),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 1: Trang chủ (Mock để liên kết sang luồng Đặt vé của Bạn)
          _buildHomeMockScreen(),

          // Tab 2: Vé của tôi (Dành cho Bạn 4 ráp vào)
          const Center(
            child: Text('Màn hình "Vé của tôi" (Thành viên 4 đảm nhận)', style: TextStyle(color: Colors.white70)),
          ),

          // Tab 3: Cá nhân (Dành cho Bạn 4 ráp vào)
          const Center(
            child: Text('Màn hình "Hồ sơ cá nhân" (Thành viên 4 đảm nhận)', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E2235),
        selectedItemColor: const Color(0xFFFF8C00),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie_creation_outlined), label: 'Phim'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Vé của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildHomeMockScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RẠP CHIẾU PHIM HUTECH'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E2235),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PHIM ĐANG CHIẾU HÔM NAY',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1E2235),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.movie, size: 40, color: Color(0xFFFF8C00)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mai (2D Phụ Đề)',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Thời lượng: 131 phút • T18', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('⭐ 9.2/10 (1.2k đánh giá)', style: TextStyle(color: Colors.amber, fontSize: 12)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              // Chuyển sang màn hình Suất chiếu & Ghế của Bạn (Nhóm trưởng)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShowtimeScreen(movieTitle: 'Mai (2D Phụ Đề)'),
                                ),
                              );
                            },
                            child: const Text('Đặt vé ngay'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}