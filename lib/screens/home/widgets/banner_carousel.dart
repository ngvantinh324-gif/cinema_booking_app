// Người phụ trách: Triết - banner phim hot tự trượt
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/movie.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/movie_poster.dart';
import '../movie_detail_screen.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.movies});

  final List<Movie> movies;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    if (widget.movies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_controller.hasClients) return;
        final next = (_current + 1) % widget.movies.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.movies.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final movie = widget.movies[i];
              return AnimatedScale(
                scale: i == _current ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: _BannerItem(movie: movie),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.movies.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MoviePoster(movie: movie, emojiSize: 72),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${movie.genreText} • ${movie.durationText}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Đặt vé',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
