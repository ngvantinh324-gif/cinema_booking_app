import 'package:flutter/material.dart';
import '../../models/showtime.dart';
import 'seat_selection_screen.dart';

class ShowtimeScreen extends StatefulWidget {
  final String movieTitle;
  const ShowtimeScreen({super.key, this.movieTitle = 'Mai (2D Phụ Đề)'});

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  int _selectedDateIndex = 0;
  String? _selectedTime;
  String? _selectedCinema;

  // Dữ liệu mẫu ngày chiếu
  final List<Map<String, String>> _dates = [
    {'day': 'T7', 'date': '10/10'},
    {'day': 'CN', 'date': '11/10'},
    {'day': 'T2', 'date': '12/10'},
    {'day': 'T3', 'date': '13/10'},
    {'day': 'T4', 'date': '14/10'},
  ];

  // Dữ liệu mẫu lịch chiếu tại các cụm rạp
  final List<Showtime> _showtimes = [
    Showtime(
      id: 1,
      cinemaName: 'CGV Landmark 81',
      cinemaAddress: 'Bình Thạnh, TP.HCM',
      date: '2026-10-10',
      times: ['10:30', '13:45', '16:30', '19:15', '21:45'],
    ),
    Showtime(
      id: 2,
      cinemaName: 'CGV Hùng Vương Plaza',
      cinemaAddress: 'Quận 5, TP.HCM',
      date: '2026-10-10',
      times: ['11:00', '14:20', '17:00', '20:00'],
    ),
    Showtime(
      id: 3,
      cinemaName: 'Lotte Cinema Nowzone',
      cinemaAddress: 'Quận 1, TP.HCM',
      date: '2026-10-10',
      times: ['09:45', '12:30', '15:15', '18:45', '22:10'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        title: Text(widget.movieTitle),
        backgroundColor: const Color(0xFF1E2235),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Chọn ngày xem',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Thanh chọn ngày trượt ngang
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedDateIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _selectedTime = null;
                      _selectedCinema = null;
                    });
                  },
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF8C00) : const Color(0xFF1E2235),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dates[index]['day']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dates[index]['date']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Chọn rạp & khung giờ',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Danh sách cụm rạp và giờ chiếu
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _showtimes.length,
              itemBuilder: (context, index) {
                final cinema = _showtimes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cinema.cinemaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cinema.cinemaAddress,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cinema.times.map((time) {
                          final isTimeSelected =
                              _selectedCinema == cinema.cinemaName && _selectedTime == time;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCinema = cinema.cinemaName;
                                _selectedTime = time;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isTimeSelected ? const Color(0xFFFF8C00) : const Color(0xFF2B3048),
                                borderRadius: BorderRadius.circular(8),
                                border: isTimeSelected
                                    ? Border.all(color: Colors.white, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: isTimeSelected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Nút bấm Tiếp tục chuyển sang Chọn ghế
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2235),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: (_selectedTime == null || _selectedCinema == null)
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeatSelectionScreen(
                              movieTitle: widget.movieTitle,
                              cinemaName: _selectedCinema!,
                              showtime: _selectedTime!,
                              date: _dates[_selectedDateIndex]['date']!,
                            ),
                          ),
                        );
                      },
                child: Text(
                  _selectedTime == null ? 'Vui lòng chọn khung giờ' : 'Tiếp tục chọn ghế ($_selectedTime)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}