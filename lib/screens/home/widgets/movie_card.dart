// Người phụ trách: Triết - thẻ phim trong lưới
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/movie.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/age_badge.dart';
import '../../../widgets/movie_poster.dart';
import '../movie_detail_screen.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster_${movie.id}',
                    child: MoviePoster(movie: movie, showTitle: true),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AgeBadge(rating: movie.ageRating, small: true),
                  ),
                  if (movie.isNowShowing && movie.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!movie.isNowShowing)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 36,
                      child: Container(
                        color: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Khởi chiếu ${formatDate(movie.releaseDate)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            movie.genres.isEmpty
                ? movie.durationText
                : '${movie.durationText} • ${movie.genres.first}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
