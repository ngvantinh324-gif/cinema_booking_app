import 'package:flutter/material.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;
  final String cinemaName;
  final String showtime;
  final String date;

  const SeatSelectionScreen({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.showtime,
    required this.date,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final int rows = 6; // Hàng A -> F
  final int cols = 7; // Ghế 1 -> 7
  final int seatPrice = 85000; // Giá vé: 85.000 VNĐ

  // Danh sách các ghế đã bán (không thể chọn)
  final Set<String> bookedSeats = {'B3', 'B4', 'D4', 'D5', 'E2'};

  // Danh sách các ghế người dùng đang chọn
  final Set<String> selectedSeats = {};

  String _getSeatCode(int row, int col) {
    String rowLetter = String.fromCharCode(65 + row); // 0 -> A, 1 -> B...
    return '$rowLetter${col + 1}';
  }

  void _onSeatTap(String seatCode) {
    if (bookedSeats.contains(seatCode)) return;

    setState(() {
      if (selectedSeats.contains(seatCode)) {
        selectedSeats.remove(seatCode);
      } else {
        selectedSeats.add(seatCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = selectedSeats.length * seatPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.movieTitle, style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.cinemaName} • ${widget.date} • ${widget.showtime}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2235),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 1. Màn hình cong chiếu phim
          Center(
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MÀN HÌNH CHIẾU',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Chú thích các trạng thái ghế
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(const Color(0xFF2B3048), 'Ghế trống'),
              _buildLegend(const Color(0xFFFF8C00), 'Đang chọn'),
              _buildLegend(Colors.white10, 'Đã đặt'),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Ma trận lưới ghế ngồi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows * cols,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  int r = index ~/ cols;
                  int c = index % cols;
                  String seatCode = _getSeatCode(r, c);

                  bool isBooked = bookedSeats.contains(seatCode);
                  bool isSelected = selectedSeats.contains(seatCode);

                  Color seatBgColor = const Color(0xFF2B3048);
                  if (isBooked) seatBgColor = Colors.white10;
                  if (isSelected) seatBgColor = const Color(0xFFFF8C00);

                  return GestureDetector(
                    onTap: () => _onSeatTap(seatCode),
                    child: Container(
                      decoration: BoxDecoration(
                        color: seatBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        seatCode,
                        style: TextStyle(
                          color: isBooked ? Colors.white24 : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Thanh thanh toán dưới cùng (Cập nhật thời gian thực)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2235),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSeats.isEmpty
                                ? 'Chưa chọn ghế nào'
                                : 'Ghế đã chọn: ${selectedSeats.join(", ")}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalAmount VNĐ',
                            style: const TextStyle(
                              color: Color(0xFFFF8C00),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: selectedSeats.isEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã chọn ${selectedSeats.length} ghế (${selectedSeats.join(", ")}). '
                                    'Sẵn sàng chuyển tiếp sang luồng Bắp nước & Thanh toán của Bạn 3!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      child: const Text('Tiếp tục', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}