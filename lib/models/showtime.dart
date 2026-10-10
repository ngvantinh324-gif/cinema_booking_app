class Showtime {
  final int id;
  final String cinemaName;
  final String cinemaAddress;
  final String date; // YYYY-MM-DD
  final List<String> times;

  Showtime({
    required this.id,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.date,
    required this.times,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    return Showtime(
      id: json['id'],
      cinemaName: json['cinema_name'],
      cinemaAddress: json['cinema_address'] ?? '',
      date: json['date'],
      times: List<String>.from(json['times']),
    );
  }
}