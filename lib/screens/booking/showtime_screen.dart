// Người phụ trách: Tính (Nhóm trưởng) - chọn ngày, rạp, suất chiếu
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import 'seat_selection_screen.dart';

class ShowtimeScreen extends StatefulWidget {
  const ShowtimeScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  late final List<DateTime> _days;
  int _selectedDay = 0;
  late Future<List<Showtime>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));
    _future = _load();
  }

  Future<List<Showtime>> _load() => BookingService.instance
      .getShowtimes(widget.movie.id, _days[_selectedDay]);

  void _selectDay(int index) {
    if (index == _selectedDay) return;
    setState(() {
      _selectedDay = index;
      _future = _load();
    });
  }

  void _openSeats(Showtime showtime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SeatSelectionScreen(movie: widget.movie, showtime: showtime),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Chọn suất chiếu', style: TextStyle(fontSize: 17)),
            Text(
              widget.movie.title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _DateChip(
                date: _days[i],
                isToday: i == 0,
                selected: i == _selectedDay,
                onTap: () => _selectDay(i),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Showtime>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final showtimes = snapshot.data ?? const <Showtime>[];
                if (showtimes.isEmpty) {
                  return const Center(
                    child: Text('Chưa có suất chiếu cho ngày này'),
                  );
                }
                // Gom suất chiếu theo cụm rạp
                final byCinema = <String, List<Showtime>>{};
                for (final s in showtimes) {
                  byCinema.putIfAbsent(s.cinema.id, () => []).add(s);
                }
                final groups = byCinema.values.toList();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) => _CinemaCard(
                    showtimes: groups[i],
                    onSelect: _openSeats,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 62,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'Hôm nay' : shortWeekdayLabel(date),
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.black87 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pad2(date.day),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            Text(
              'Th${date.month}',
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.black87 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  const _CinemaCard({required this.showtimes, required this.onSelect});

  final List<Showtime> showtimes;
  final ValueChanged<Showtime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = showtimes.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.cinema.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      first.cinema.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  first.format,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Giá từ ${formatVnd(first.basePrice)}',
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: showtimes.map((s) {
              final disabled = s.isPast;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: disabled ? null : () => onSelect(s),
                child: Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: disabled ? Colors.white10 : Colors.white30,
                    ),
                  ),
                  child: Text(
                    formatTime(s.startTime),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: disabled ? Colors.white24 : Colors.white,
                      decoration: disabled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
