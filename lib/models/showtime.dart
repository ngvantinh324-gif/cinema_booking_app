// Người phụ trách: Tính (Nhóm trưởng)

class Cinema {
  final String id;
  final String name;
  final String address;

  const Cinema({required this.id, required this.name, required this.address});
}

class Showtime {
  final String id;
  final String movieId;
  final Cinema cinema;
  final String room;
  final DateTime startTime;
  final String format; // 2D, 3D, IMAX
  final int basePrice; // giá ghế thường

  const Showtime({
    required this.id,
    required this.movieId,
    required this.cinema,
    required this.room,
    required this.startTime,
    required this.format,
    required this.basePrice,
  });

  bool get isPast => startTime.isBefore(DateTime.now());
}
