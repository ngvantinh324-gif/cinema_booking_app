// Người phụ trách: Triết
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../services/movie_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = MovieService.instance.getMovies();
  }

  void _reload() {
    setState(() {
      _moviesFuture = MovieService.instance.getMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().currentUser?.name ?? 'bạn';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Movie>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không tải được danh sách phim'),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _reload, child: const Text('Thử lại')),
                  ],
                ),
              );
            }
            final movies = snapshot.data ?? const <Movie>[];
            final nowShowing = movies.where((m) => m.isNowShowing).toList();
            final comingSoon = movies.where((m) => !m.isNowShowing).toList();

            return DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(child: _Header(name: userName)),
                  SliverToBoxAdapter(
                    child: BannerCarousel(movies: nowShowing.take(5).toList()),
                  ),
                  // Absorber + Injector để lưới phim không bị TabBar ghim che mất
                  SliverOverlapAbsorber(
                    handle:
                        NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: const SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _MovieGrid(
                      key: const PageStorageKey('now'),
                      movies: nowShowing,
                    ),
                    _MovieGrid(
                      key: const PageStorageKey('soon'),
                      movies: comingSoon,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hôm nay xem phim gì?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              initialsOf(name),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.centerLeft,
      child: const TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        tabs: [Tab(text: 'Đang chiếu'), Tab(text: 'Sắp chiếu')],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _MovieGrid extends StatelessWidget {
  const _MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        if (movies.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Chưa có phim')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => MovieCard(movie: movies[i]),
                childCount: movies.length,
              ),
            ),
          ),
      ],
    );
  }
}
