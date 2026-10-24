// Người phụ trách: Triết
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/movie.dart';
import '../../theme/app_theme.dart';
import '../../widgets/age_badge.dart';
import '../../widgets/movie_poster.dart';
import '../booking/showtime_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _expanded = false;

  void _openTrailer() {
    // Giai đoạn 2: dùng url_launcher mở movie.trailerUrl trên YouTube
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trailer sẽ mở YouTube khi tích hợp url_launcher')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 440,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster_${movie.id}',
                    child: MoviePoster(movie: movie, emojiSize: 110),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AgeBadge(rating: movie.ageRating),
                      _InfoChip(icon: Icons.schedule, text: movie.durationText),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        text: formatDate(movie.releaseDate),
                      ),
                      if (movie.rating > 0)
                        _InfoChip(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                          text: '${movie.rating.toStringAsFixed(1)}/10',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres
                        .map((g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text(
                                g,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  _TrailerCard(movie: movie, onTap: _openTrailer),
                  const _SectionTitle('Nội dung'),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topCenter,
                    child: Text(
                      movie.description,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
                  ),
                  const _SectionTitle('Đạo diễn'),
                  Text(movie.director, style: const TextStyle(fontSize: 15)),
                  const _SectionTitle('Diễn viên'),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: movie.cast.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, i) =>
                          _CastAvatar(name: movie.cast[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: movie.isNowShowing
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShowtimeScreen(movie: movie),
                      ),
                    )
                : null,
            child: Text(
              movie.isNowShowing
                  ? 'ĐẶT VÉ NGAY'
                  : 'KHỞI CHIẾU ${formatDate(movie.releaseDate)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TrailerCard extends StatelessWidget {
  const _TrailerCard({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: movie.posterColors.reversed.toList(),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 12,
                child: Text(
                  'Trailer chính thức',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              initialsOf(name.replaceFirst('Lồng tiếng: ', '')),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
