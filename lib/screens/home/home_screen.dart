// Người phụ trách: Triết
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../services/movie_service.dart';
import '../../theme/app_theme.dart';
import 'movie_search.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Movie>? _movies;
  Object? _error;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lần đầu: hiện khung xương. Kéo xuống tải lại: giữ danh sách cũ trên màn hình.
  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final movies =
          await MovieService.instance.getMovies(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (_movies != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải lại được danh sách phim')),
        );
      }
    }
  }

  void _retry() {
    setState(() {
      _movies = null;
      _error = null;
    });
    _load(forceRefresh: true);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().currentUser?.name ?? 'bạn';
    final movies = _movies;

    Widget body;
    if (movies == null && _error == null) {
      body = const HomeSkeleton();
    } else if (movies == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tải được danh sách phim'),
            const SizedBox(height: 12),
            TextButton(onPressed: _retry, child: const Text('Thử lại')),
          ],
        ),
      );
    } else {
      body = _buildContent(movies, userName);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(movies == null ? 'loading' : 'content'),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Movie> movies, String userName) {
    final filtered = movies.where((m) => movieMatches(m, _query)).toList();
    final nowShowing = filtered.where((m) => m.isNowShowing).toList();
    final comingSoon = filtered.where((m) => !m.isNowShowing).toList();
    final bannerMovies =
        movies.where((m) => m.isNowShowing).take(5).toList();
    final emptyText =
        _query.trim().isEmpty ? 'Chưa có phim' : 'Không tìm thấy phim phù hợp';

    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        // Lưới phim nằm trong NestedScrollView + TabBarView nên cuộn ở tầng sâu hơn
        notificationPredicate: (n) => n.depth <= 2,
        onRefresh: () => _load(forceRefresh: true),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _Header(
                name: userName,
                searching: _searching,
                onSearchTap: _toggleSearch,
              ),
            ),
            if (_searching)
              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            // Đang tìm kiếm thì ẩn banner cho gọn
            if (_query.trim().isEmpty)
              SliverToBoxAdapter(
                child: BannerCarousel(movies: bannerMovies),
              ),
            // Absorber + Injector để lưới phim không bị TabBar ghim che mất
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  nowCount: nowShowing.length,
                  soonCount: comingSoon.length,
                  showCounts: _query.trim().isNotEmpty,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _MovieGrid(
                key: const PageStorageKey('now'),
                movies: nowShowing,
                emptyText: emptyText,
              ),
              _MovieGrid(
                key: const PageStorageKey('soon'),
                movies: comingSoon,
                emptyText: emptyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.searching,
    required this.onSearchTap,
  });

  final String name;
  final bool searching;
  final VoidCallback onSearchTap;

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
          IconButton(
            tooltip: searching ? 'Đóng tìm kiếm' : 'Tìm phim',
            onPressed: onSearchTap,
            icon: Icon(searching ? Icons.close_rounded : Icons.search_rounded),
          ),
          const SizedBox(width: 4),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tên phim, thể loại, diễn viên...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.nowCount,
    required this.soonCount,
    required this.showCounts,
  });

  final int nowCount;
  final int soonCount;
  final bool showCounts;

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
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: showCounts ? 'Đang chiếu ($nowCount)' : 'Đang chiếu'),
          Tab(text: showCounts ? 'Sắp chiếu ($soonCount)' : 'Sắp chiếu'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.nowCount != nowCount ||
      oldDelegate.soonCount != soonCount ||
      oldDelegate.showCounts != showCounts;
}

class _MovieGrid extends StatelessWidget {
  const _MovieGrid({
    super.key,
    required this.movies,
    required this.emptyText,
  });

  final List<Movie> movies;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Luôn cho cuộn để danh sách ngắn/rỗng vẫn kéo xuống tải lại được
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        if (movies.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(emptyText)),
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
