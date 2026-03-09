import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.dart';
import '../app_theme.dart';
import '../models/content_model.dart';
import '../providers/storage_provider.dart';

/// Bookmarks & History screen with tab bar.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            color: AppTheme.surface,
            onSelected: (val) => _onMenuAction(val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear_bookmarks',
                child: Text('Clear all bookmarks', style: TextStyle(color: AppTheme.textPrimary))),
              const PopupMenuItem(value: 'clear_history',
                child: Text('Clear all history', style: TextStyle(color: AppTheme.textPrimary))),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BookmarksTab(),
          _HistoryTab(),
        ],
      ),
    );
  }

  void _onMenuAction(String action) {
    final storage = context.read<StorageProvider>();
    final label = action == 'clear_bookmarks' ? 'bookmarks' : 'history';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Clear all $label?', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text('This cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (action == 'clear_bookmarks') {
                storage.clearBookmarks();
              } else {
                storage.clearHistory();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// BOOKMARKS TAB — Grid of saved content
// ═══════════════════════════════════════════
class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageProvider>(
      builder: (ctx, storage, _) {
        final bookmarks = storage.bookmarks;
        if (bookmarks.isEmpty) {
          return _emptyState(
            icon: Icons.bookmark_border,
            title: 'No bookmarks yet',
            subtitle: 'Tap the bookmark icon on any\ncontent to save it here',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: bookmarks.length,
          itemBuilder: (ctx, i) => _BookmarkCard(bookmark: bookmarks[i]),
        );
      },
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  const _BookmarkCard({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail screen
        final item = ContentItem(
          id: bookmark.contentId,
          title: bookmark.title,
          cover: bookmark.cover,
          platform: bookmark.platform,
          type: bookmark.type,
        );
        Navigator.pushNamed(context, Routes.detail,
          arguments: DetailArgs(item: item));
      },
      onLongPress: () => _showRemoveDialog(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bookmark.cover != null && bookmark.cover!.isNotEmpty)
                    Image.network(bookmark.cover!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover())
                  else
                    _fallbackCover(),
                  // Platform badge
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bookmark.platform.toUpperCase(),
                        style: const TextStyle(fontSize: 8, color: AppTheme.accent,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Type icon
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        bookmark.type == ContentType.komik ? Icons.menu_book
                            : bookmark.type == ContentType.anime ? Icons.animation
                            : Icons.play_circle,
                        size: 14, color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(bookmark.title,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _fallbackCover() => Center(
    child: Icon(
      bookmark.type == ContentType.komik ? Icons.menu_book : Icons.movie,
      size: 32, color: AppTheme.textSecondary,
    ),
  );

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove bookmark?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(bookmark.title, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<StorageProvider>().removeBookmark(
                bookmark.contentId, bookmark.platform);
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HISTORY TAB — List with continue watching
// ═══════════════════════════════════════════
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageProvider>(
      builder: (ctx, storage, _) {
        final items = storage.history;
        if (items.isEmpty) {
          return _emptyState(
            icon: Icons.history,
            title: 'No history yet',
            subtitle: 'Content you watch or read\nwill appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _HistoryTile(item: items[i]),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isKomik = item.type == ContentType.komik;
    final subtitle = isKomik
        ? 'Chapter: ${item.lastChapterId ?? 'N/A'}'
        : 'Episode ${item.lastEpisode ?? '?'}';
    final timeAgo = _formatTimeAgo(item.updatedAt);

    return Dismissible(
      key: ValueKey('${item.platform}_${item.contentId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<StorageProvider>().removeHistory(item.contentId, item.platform);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: (item.cover != null && item.cover!.isNotEmpty)
              ? Image.network(item.cover!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon())
              : _fallbackIcon(),
        ),
        title: Text(item.title, style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            if (!isKomik && item.progress > 0) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: AppTheme.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 3,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(timeAgo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isKomik ? Icons.menu_book : Icons.play_circle_outline,
            color: AppTheme.primary,
          ),
          onPressed: () {
            final contentItem = ContentItem(
              id: item.contentId,
              title: item.title,
              cover: item.cover,
              platform: item.platform,
              type: item.type,
            );
            Navigator.pushNamed(context, Routes.detail,
              arguments: DetailArgs(item: contentItem));
          },
        ),
        onTap: () {
          final contentItem = ContentItem(
            id: item.contentId,
            title: item.title,
            cover: item.cover,
            platform: item.platform,
            type: item.type,
          );
          Navigator.pushNamed(context, Routes.detail,
            arguments: DetailArgs(item: contentItem));
        },
      ),
    );
  }

  Widget _fallbackIcon() => Center(
    child: Icon(
      item.type == ContentType.komik ? Icons.menu_book : Icons.movie,
      color: AppTheme.textSecondary, size: 24,
    ),
  );

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Shared empty state widget ──
Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(
          fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      ],
    ),
  );
}
