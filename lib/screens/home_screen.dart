import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/content_provider.dart';
import '../widgets/content_horizontal_list.dart';

/// Home screen with category tabs: Drama, Anime, Komik, Movie.
/// Each tab auto-loads its content sections on first view.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Drama'),
    Tab(text: 'Anime'),
    Tab(text: 'Komik'),
    Tab(text: 'Movie'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load drama tab on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadDrama();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final provider = context.read<ContentProvider>();
    switch (_tabController.index) {
      case 0: provider.loadDrama(); break;
      case 1: provider.loadAnime(); break;
      case 2: provider.loadKomik(); break;
      case 3: provider.loadMovie(); break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Row(
              children: [
                Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 28),
                SizedBox(width: 8),
                Text(
                  'StreamBox',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: _tabs,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DramaTab(),
            _AnimeTab(),
            _KomikTab(),
            _MovieTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DRAMA TAB
// ============================================================
class _DramaTab extends StatelessWidget {
  const _DramaTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isDramaLoading;
        final error = provider.getError('drama');

        if (error != null && provider.dramaForYou.isEmpty) {
          return _ErrorView(
            message: error,
            onRetry: () => provider.loadDrama(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDrama(forceRefresh: true),
          color: AppTheme.primary,
          child: ListView(
            children: [
              ContentHorizontalList(
                title: 'For You',
                subtitle: 'Across all drama platforms',
                icon: Icons.local_fire_department,
                items: provider.dramaForYou,
                isLoading: isLoading,
                cardWidth: 140,
                cardHeight: 200,
              ),
              ContentHorizontalList(
                title: 'Trending',
                icon: Icons.trending_up,
                items: provider.dramaTrending,
                isLoading: isLoading,
              ),
              ContentHorizontalList(
                title: 'Latest',
                icon: Icons.new_releases_outlined,
                items: provider.dramaLatest,
                isLoading: isLoading,
              ),
              if (provider.dramaVip.isNotEmpty)
                ContentHorizontalList(
                  title: 'VIP Collection',
                  icon: Icons.diamond_outlined,
                  items: provider.dramaVip,
                  isLoading: false,
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ANIME TAB
// ============================================================
class _AnimeTab extends StatelessWidget {
  const _AnimeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isAnimeLoading;
        final error = provider.getError('anime');

        if (error != null && provider.animeRecommended.isEmpty) {
          return _ErrorView(
            message: error,
            onRetry: () => provider.loadAnime(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAnime(forceRefresh: true),
          color: AppTheme.primary,
          child: ListView(
            children: [
              ContentHorizontalList(
                title: 'Recommended',
                icon: Icons.recommend,
                items: provider.animeRecommended,
                isLoading: isLoading,
                cardWidth: 140,
                cardHeight: 200,
              ),
              ContentHorizontalList(
                title: 'Latest Episode',
                icon: Icons.new_releases_outlined,
                items: provider.animeLatest,
                isLoading: isLoading,
              ),
              ContentHorizontalList(
                title: 'Anime Movies',
                icon: Icons.movie_outlined,
                items: provider.animeMovies,
                isLoading: isLoading,
                cardWidth: 150,
                cardHeight: 210,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// KOMIK TAB
// ============================================================
class _KomikTab extends StatelessWidget {
  const _KomikTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isKomikLoading;
        final error = provider.getError('komik');

        if (error != null && provider.komikPopular.isEmpty) {
          return _ErrorView(
            message: error,
            onRetry: () => provider.loadKomik(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadKomik(forceRefresh: true),
          color: AppTheme.primary,
          child: ListView(
            children: [
              ContentHorizontalList(
                title: 'Popular',
                icon: Icons.local_fire_department,
                items: provider.komikPopular,
                isLoading: isLoading,
                cardWidth: 120,
                cardHeight: 170,
              ),
              ContentHorizontalList(
                title: 'Latest Project',
                icon: Icons.auto_awesome,
                items: provider.komikLatestProject,
                isLoading: isLoading,
                cardWidth: 120,
                cardHeight: 170,
              ),
              ContentHorizontalList(
                title: 'Manhwa',
                subtitle: 'Korean comics',
                icon: Icons.auto_stories,
                items: provider.komikManhwa,
                isLoading: isLoading,
                cardWidth: 120,
                cardHeight: 170,
              ),
              ContentHorizontalList(
                title: 'Manhua',
                subtitle: 'Chinese comics',
                icon: Icons.auto_stories,
                items: provider.komikManhua,
                isLoading: isLoading,
                cardWidth: 120,
                cardHeight: 170,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// MOVIE TAB
// ============================================================
class _MovieTab extends StatelessWidget {
  const _MovieTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isMovieLoading;
        final error = provider.getError('movie');

        if (error != null && provider.movieHomepage.isEmpty) {
          return _ErrorView(
            message: error,
            onRetry: () => provider.loadMovie(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMovie(forceRefresh: true),
          color: AppTheme.primary,
          child: ListView(
            children: [
              ContentHorizontalList(
                title: 'Featured',
                icon: Icons.star_outlined,
                items: provider.movieHomepage,
                isLoading: isLoading,
                cardWidth: 150,
                cardHeight: 210,
              ),
              ContentHorizontalList(
                title: 'Trending Now',
                icon: Icons.trending_up,
                items: provider.movieTrending,
                isLoading: isLoading,
                cardWidth: 150,
                cardHeight: 210,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ERROR VIEW
// ============================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
