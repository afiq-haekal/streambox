import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.dart';
import '../app_theme.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import '../providers/download_provider.dart';
import '../providers/storage_provider.dart';
import '../widgets/shimmer_loading.dart';

class DetailScreen extends StatefulWidget {
  final DetailArgs args;
  const DetailScreen({super.key, required this.args});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().fetchDetail(widget.args.item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) return _buildSkeleton();
          if (provider.detailError != null) return _buildError(provider.detailError!);
          final detail = provider.currentDetail;
          if (detail == null) return _buildError('No detail available');
          return _buildContent(context, detail, provider);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ContentDetail detail, ContentProvider provider) {
    final item = detail.item;
    final isKomik = item.type == ContentType.komik;
    final h = MediaQuery.of(ctx).size.height;

    return CustomScrollView(
      slivers: [
        // Hero cover
        SliverAppBar(
          expandedHeight: h * 0.45,
          pinned: true,
          backgroundColor: AppTheme.bg,
          leading: _backBtn(),
          actions: [
            Consumer<StorageProvider>(
              builder: (ctx, storage, _) {
                final isBookmarked = storage.isBookmarked(widget.args.item.id, widget.args.item.platform);
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? AppTheme.primary : Colors.white,
                  ),
                  onPressed: () {
                    final added = storage.toggleBookmark(widget.args.item);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(added ? 'Added to bookmarks' : 'Removed from bookmarks'),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (item.cover != null && item.cover!.isNotEmpty)
                  Image.network(item.cover!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surface,
                      child: const Icon(Icons.broken_image, size: 64, color: AppTheme.textSecondary),
                    ),
                  )
                else
                  Container(color: AppTheme.surface,
                    child: const Icon(Icons.movie, size: 64, color: AppTheme.textSecondary)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.transparent, AppTheme.bg],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Title + meta
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(children: [
                  _platformBadge(item.platform),
                  const SizedBox(width: 8),
                  if (item.rating != null && item.rating!.isNotEmpty) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(item.rating!, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  if (detail.totalEpisodes != null)
                    Text(
                      isKomik ? '${detail.chapters?.length ?? detail.totalEpisodes} chapters'
                              : '${detail.totalEpisodes} episodes',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                ]),
                const SizedBox(height: 16),

                // Tags
                if (detail.tags != null && detail.tags!.isNotEmpty) ...[
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: detail.tags!.take(8).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Play / Read button
                _actionButton(ctx, detail, provider),
                const SizedBox(height: 16),

                // Synopsis
                if (detail.synopsis != null && detail.synopsis!.isNotEmpty)
                  _SynopsisSection(text: detail.synopsis!),
                const SizedBox(height: 16),

                Text(isKomik ? 'Chapters' : 'Episodes', style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Episode / Chapter list
        if (isKomik && detail.chapters != null)
          _chapterSliver(detail)
        else if (!isKomik && detail.episodes != null)
          _episodeSliver(detail, provider)
        else
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('No episodes/chapters available',
                style: TextStyle(color: AppTheme.textSecondary)))),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  // ── Action button ──
  Widget _actionButton(BuildContext ctx, ContentDetail detail, ContentProvider provider) {
    final isKomik = detail.item.type == ContentType.komik;
    final hasContent = isKomik
        ? (detail.chapters?.isNotEmpty ?? false)
        : (detail.episodes?.isNotEmpty ?? false);

    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        onPressed: hasContent ? () => _onPlayOrRead(ctx, detail, provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(isKomik ? Icons.menu_book : Icons.play_arrow, size: 24),
        label: Text(isKomik ? 'Start Reading' : 'Play Episode 1',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _onPlayOrRead(BuildContext ctx, ContentDetail detail, ContentProvider provider) {
    if (detail.item.type == ContentType.komik) {
      final ch = detail.chapters!.first;
      Navigator.pushNamed(ctx, Routes.komikReader, arguments: KomikReaderArgs(
        chapterId: ch.id, title: '${detail.item.title} - ${ch.title}', chapterNumber: ch.number,
        contentItem: detail.item,
      ));
    } else {
      _playEpisode(ctx, detail, detail.episodes!.first, provider);
    }
  }

  Future<void> _playEpisode(BuildContext ctx, ContentDetail detail, Episode ep, ContentProvider provider) async {
    showDialog(context: ctx, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)));

    final url = await provider.fetchStreamUrl(item: detail.item, episode: ep);
    if (!mounted) return;
    Navigator.pop(ctx);

    if (url != null && url.isNotEmpty) {
      Navigator.pushNamed(ctx, Routes.player, arguments: PlayerArgs(
        streamUrl: url, title: '${detail.item.title} - Ep ${ep.number}',
        episodeNumber: ep.number, platform: detail.item.platform,
        contentItem: detail.item,
      ));
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Could not load stream URL'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _downloadEpisode(BuildContext ctx, ContentDetail detail, Episode ep, ContentProvider provider, DownloadProvider dlProvider) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('Downloading ${detail.item.title} - Ep ${ep.number}...'), duration: const Duration(seconds: 1)));

    final url = await provider.fetchStreamUrl(item: detail.item, episode: ep);
    if (url != null && url.isNotEmpty) {
      dlProvider.downloadVideo(content: detail.item, episode: ep, streamUrl: url);
    } else {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Could not get download URL'), backgroundColor: AppTheme.error));
      }
    }
  }

  // ── Episode sliver ──
  Widget _episodeSliver(ContentDetail detail, ContentProvider provider) {
    final eps = detail.episodes!;
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final ep = eps[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
            child: (ep.thumbnail != null && ep.thumbnail!.isNotEmpty)
                ? ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network(ep.thumbnail!, fit: BoxFit.cover))
                : Center(child: Text('${ep.number}', style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          title: Text(ep.title ?? 'Episode ${ep.number}',
            style: const TextStyle(color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('Episode ${ep.number}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<DownloadProvider>(
                builder: (ctx2, dlProvider, _) {
                  final dlId = dlProvider.videoId(detail.item, ep);
                  final isDl = dlProvider.isDownloaded(dlId);
                  return IconButton(
                    icon: Icon(
                      isDl ? Icons.download_done : Icons.download_outlined,
                      color: isDl ? AppTheme.success : AppTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: isDl ? 'Downloaded' : 'Download',
                    onPressed: isDl ? null : () => _downloadEpisode(ctx2, detail, ep, provider, dlProvider),
                  );
                },
              ),
              const Icon(Icons.play_circle_outline, color: AppTheme.primary),
            ],
          ),
          onTap: () => _playEpisode(ctx, detail, ep, provider),
        );
      }, childCount: eps.length),
    );
  }

  // ── Chapter sliver ──
  Widget _chapterSliver(ContentDetail detail) {
    final chapters = detail.chapters!;
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final ch = chapters[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${ch.number ?? ''}',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
          ),
          title: Text(ch.title, style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: (ch.date != null && ch.date!.isNotEmpty)
              ? Text(ch.date!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          onTap: () => Navigator.pushNamed(ctx, Routes.komikReader, arguments: KomikReaderArgs(
            chapterId: ch.id, title: ch.title, chapterNumber: ch.number,
            contentItem: detail.item)),
        );
      }, childCount: chapters.length),
    );
  }

  Widget _backBtn() => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context)),
  );

  Widget _platformBadge(String platform) {
    final c = _platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.5))),
      child: Text(platform.toUpperCase(), style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, color: c, letterSpacing: 0.5)),
    );
  }

  Color _platformColor(String p) => switch (p) {
    'dramabox' => Colors.pinkAccent, 'reelshort' => Colors.orangeAccent,
    'shortmax' => Colors.tealAccent, 'melolo' => Colors.purpleAccent,
    'flickreels' => Colors.cyanAccent, 'freereels' => Colors.greenAccent,
    'anime' => Colors.blueAccent, 'komik' => Colors.amberAccent,
    'moviebox' => Colors.redAccent, _ => AppTheme.accent,
  };

  Widget _buildSkeleton() => SingleChildScrollView(
    child: Column(children: [
      const ShimmerLoading(width: double.infinity, height: 300),
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ShimmerLoading(width: 250, height: 28),
          const SizedBox(height: 12),
          const ShimmerLoading(width: 180, height: 16),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(right: 8),
            child: ShimmerLoading(width: 70, height: 28, borderRadius: 14)))),
          const SizedBox(height: 16),
          const ShimmerLoading(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: 16),
          ...List.generate(4, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerLoading(width: double.infinity, height: 14))),
          const SizedBox(height: 16),
          ...List.generate(6, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerLoading(width: double.infinity, height: 56, borderRadius: 8))),
        ],
      )),
    ]),
  );

  Widget _buildError(String msg) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
        const SizedBox(height: 16),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.read<ContentProvider>().fetchDetail(widget.args.item),
          child: const Text('Retry')),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
      ],
    )),
  );
}

// ── Synopsis expand/collapse ──
class _SynopsisSection extends StatefulWidget {
  final String text;
  const _SynopsisSection({required this.text});
  @override
  State<_SynopsisSection> createState() => _SynopsisSectionState();
}

class _SynopsisSectionState extends State<_SynopsisSection> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Synopsis', style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      AnimatedCrossFade(
        firstChild: Text(widget.text, maxLines: 3, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
        secondChild: Text(widget.text,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
      if (widget.text.length > 120)
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(_expanded ? 'Show less' : 'Show more',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))),
        ),
    ],
  );
}
