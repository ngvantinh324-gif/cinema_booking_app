// Người phụ trách: Triết - dữ liệu phim giả lập (giai đoạn 1)
import 'package:flutter/material.dart';

import '../../models/movie.dart';

final List<Movie> mockMovies = [
  Movie(
    id: 'm1',
    title: 'Hành Tinh Cát Đỏ',
    genres: const ['Khoa học viễn tưởng', 'Phiêu lưu'],
    durationMinutes: 148,
    ageRating: 'T13',
    rating: 8.7,
    status: MovieStatus.nowShowing,
    releaseDate: DateTime(2026, 9, 26),
    director: 'Trần Minh Quân',
    cast: const ['Lê Hoàng Long', 'Ngô Thanh Vy', 'Phạm Gia Bảo', 'Đỗ Mỹ Anh'],
    description:
        'Năm 2187, phi hành đoàn tàu Hy Vọng nhận nhiệm vụ cuối cùng: tìm nguồn '
        'nước trên hành tinh cát đỏ Kepler-9. Khi bão cát cắt đứt liên lạc với '
        'Trái Đất, cơ trưởng Long phải chọn giữa việc cứu đồng đội và hoàn thành '
        'sứ mệnh của cả nhân loại.',
    posterColors: const [Color(0xFFD35400), Color(0xFF2B0F0A)],
    emoji: '🪐',
  ),
  Movie(
    id: 'm2',
    title: 'Bóng Ma Chợ Lớn',
    genres: const ['Kinh dị', 'Bí ẩn'],
    durationMinutes: 112,
    ageRating: 'T18',
    rating: 7.9,
    status: MovieStatus.nowShowing,
    releaseDate: DateTime(2026, 10, 2),
    director: 'Lý Hải Đăng',
    cast: const ['Hứa Vĩ Kiệt', 'Trương Ngọc Hân', 'Mã Quốc Thái'],
    description:
        'Một nhóm sinh viên làm phim tài liệu về căn nhà cổ bỏ hoang ở Chợ Lớn. '
        'Đêm đầu tiên quay phim, chiếc máy quay ghi lại hình ảnh một người phụ nữ '
        'mặc áo dài đỏ đứng sau lưng từng người.',
    posterColors: const [Color(0xFF1E3A3A), Color(0xFF050A0A)],
    emoji: '👻',
  ),
  Movie(
    id: 'm3',
    title: 'Mèo Mập Đi Lạc',
    genres: const ['Hoạt hình', 'Gia đình'],
    durationMinutes: 95,
    ageRating: 'P',
    rating: 8.9,
    status: MovieStatus.nowShowing,
    releaseDate: DateTime(2026, 9, 19),
    director: 'Nguyễn Thu Hà',
    cast: const ['Lồng tiếng: Bé Na', 'Hoàng Phúc', 'Kim Chi'],
    description:
        'Mập là chú mèo lười nhất phố Hàng Mã. Một ngày đuổi theo con cá khô, '
        'Mập lạc lên chuyến xe khách vào Sài Gòn và bắt đầu hành trình tìm đường '
        'về nhà cùng những người bạn mới.',
    posterColors: const [Color(0xFFFFB347), Color(0xFFE0674B)],
    emoji: '🐱',
  ),
  Movie(
    id: 'm4',
    title: 'Điệp Vụ 2049',
    genres: const ['Hành động', 'Gián điệp'],
    durationMinutes: 131,
    ageRating: 'T16',
    rating: 8.2,
    status: MovieStatus.nowShowing,
    releaseDate: DateTime(2026, 10, 9),
    director: 'Võ Thành Nam',
    cast: const ['Đinh Quốc Huy', 'Lâm Tuyết Mai', 'Bùi Anh Tuấn'],
    description:
        'Một con chip AI có thể điều khiển toàn bộ hệ thống ngân hàng châu Á bị '
        'đánh cắp. Đặc vụ Huy có 48 giờ để thu hồi nó trước khi phiên đấu giá '
        'ngầm diễn ra trên du thuyền giữa vịnh Hạ Long.',
    posterColors: const [Color(0xFF243B55), Color(0xFF141E30)],
    emoji: '💥',
  ),
  Movie(
    id: 'm5',
    title: 'Chuyến Tàu Cuối Năm',
    genres: const ['Tâm lý', 'Gia đình'],
    durationMinutes: 118,
    ageRating: 'T13',
    rating: 8.5,
    status: MovieStatus.nowShowing,
    releaseDate: DateTime(2026, 9, 12),
    director: 'Phan Ngọc Diệp',
    cast: const ['Trịnh Văn Sang', 'Mai Thu Trang', 'Lê Bảo Ngọc'],
    description:
        'Ba thế hệ trong một gia đình tình cờ ngồi chung toa trên chuyến tàu '
        'Thống Nhất chiều 29 Tết. 36 tiếng đồng hồ đủ để những bí mật cũ được '
        'nói ra và những khoảng cách được hàn gắn.',
    posterColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    emoji: '🚂',
  ),
  Movie(
    id: 'm6',
    title: 'Thanh Xuân Ở Đà Lạt',
    genres: const ['Tình cảm', 'Hài'],
    durationMinutes: 104,
    ageRating: 'T13',
    rating: 0,
    status: MovieStatus.comingSoon,
    releaseDate: DateTime(2026, 10, 24),
    director: 'Đặng Khánh Linh',
    cast: const ['Vũ Minh Khoa', 'Hồ Ngọc Diệp', 'Tạ Quang Vinh'],
    description:
        'Hai người lạ cùng thuê nhầm một căn homestay ở Đà Lạt trong mùa hoa dã '
        'quỳ. Bảy ngày "ở chung bất đắc dĩ" khiến cả hai nhận ra điều mình thật '
        'sự muốn ở tuổi 25.',
    posterColors: const [Color(0xFFEC6EAD), Color(0xFF3494E6)],
    emoji: '🌸',
  ),
  Movie(
    id: 'm7',
    title: 'Siêu Robot Học Đường',
    genres: const ['Hoạt hình', 'Khoa học viễn tưởng'],
    durationMinutes: 99,
    ageRating: 'P',
    rating: 0,
    status: MovieStatus.comingSoon,
    releaseDate: DateTime(2026, 11, 7),
    director: 'Trương Gia Huy',
    cast: const ['Lồng tiếng: Minh Tú', 'Quốc Bảo', 'Thảo Vy'],
    description:
        'Cậu học sinh lớp 6 tự lắp ráp một con robot từ đồ phế liệu để tham gia '
        'cuộc thi khoa học của trường. Không ngờ con robot lại có cảm xúc và '
        'muốn trở thành... học sinh.',
    posterColors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
    emoji: '🤖',
  ),
  Movie(
    id: 'm8',
    title: 'Đảo Không Tên',
    genres: const ['Kinh dị', 'Sinh tồn'],
    durationMinutes: 116,
    ageRating: 'T18',
    rating: 0,
    status: MovieStatus.comingSoon,
    releaseDate: DateTime(2026, 11, 21),
    director: 'Lê Văn Khải',
    cast: const ['Nguyễn Trung Hiếu', 'Phạm Lan Anh', 'Kiều Minh Đức'],
    description:
        'Sau vụ đắm tàu, năm người sống sót dạt vào một hòn đảo không có trên '
        'bản đồ. Mỗi đêm, một người biến mất và để lại đúng một dấu chân hướng '
        'ra biển.',
    posterColors: const [Color(0xFF134E5E), Color(0xFF71B280)],
    emoji: '🏝️',
  ),
];
