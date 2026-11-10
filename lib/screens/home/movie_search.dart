// Người phụ trách: Triết - lọc phim theo từ khóa trên trang chủ
import '../../models/movie.dart';

const _withMarks = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _withoutMarks = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Chữ thường, bỏ dấu tiếng Việt: "Đấu Trường" -> "dau truong"
String foldVietnamese(String input) {
  // Bỏ dấu dạng tổ hợp (bàn phím gõ kiểu tách dấu), rồi đổi chữ có dấu sẵn
  final lower =
      input.toLowerCase().replaceAll(RegExp('[̀-ͯ]'), '');
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = _withMarks.indexOf(ch);
    buffer.write(i >= 0 ? _withoutMarks[i] : ch);
  }
  return buffer.toString();
}

/// Tìm theo tên phim, thể loại, đạo diễn, diễn viên; gõ không dấu vẫn ra.
bool movieMatches(Movie movie, String query) {
  final q = foldVietnamese(query.trim());
  if (q.isEmpty) return true;
  final haystack = foldVietnamese([
    movie.title,
    ...movie.genres,
    movie.director,
    ...movie.cast,
  ].join(' '));
  return q.split(RegExp(r'\s+')).every(haystack.contains);
}
