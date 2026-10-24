// Widget dùng chung - Người giữ: Triết
import 'package:flutter/material.dart';

import '../models/movie.dart';

/// Poster phim: có posterUrl thì tải ảnh thật, chưa có thì vẽ gradient giả lập.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.emojiSize = 56,
    this.showTitle = false,
  });

  final Movie movie;
  final double emojiSize;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final url = movie.posterUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: movie.posterColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              Icons.movie_creation_outlined,
              size: emojiSize * 2.4,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Center(
            child: Text(movie.emoji, style: TextStyle(fontSize: emojiSize)),
          ),
          if (showTitle)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                movie.title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
