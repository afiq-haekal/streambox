import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/content_model.dart';
import '../providers/download_provider.dart';

/// Downloads screen with active, completed, and failed sections.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          Consumer<DownloadProvider>(
            builder: (ctx, provider, _) {
              if (provider.completedItems.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep, color: AppTheme.textSecondary),
                tooltip: 'Clear completed',
                onPressed: () => _confirmClearCompleted(ctx, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (ctx, provider, _) {
          final active = provider.activeItems;
          final completed = provider.completedItems;
          final failed = provider.failedItems;

          if (active.isEmpty && completed.isEmpty && failed.isEmpty) {
            return _buildEmpty();
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (active.isNotEmpty) ...[
                _sectionHeader('Downloading', active.length),
                ...active.map((item) => _ActiveTile(item: item, provider: provider)),
                const SizedBox(height: 16),
              ],
              if (failed.isNotEmpty) ...[
                _sectionHeader('Failed / Paused', failed.length),
                ...failed.map((item) => _FailedTile(item: item, provider: provider)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader('Completed', completed.length),
                ...completed.map((item) => _CompletedTile(item: item, provider: provider)),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No downloads yet', style: TextStyle(
            fontSize: 18, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Downloaded episodes and chapters\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(
            fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  void _confirmClearCompleted(BuildContext ctx, DownloadProvider provider) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear completed downloads?',
          style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete all completed download files from your device.',
          style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllCompleted();
              Navigator.pop(ctx);
            },
            child: const Text('Delete All', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── Active download tile with progress bar ──
class _ActiveTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadProvider provider;
  const _ActiveTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = provider.getProgress(item.id);
    final pct = (progress * 100).toInt();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _CoverThumb(cover: item.cover, type: item.type),
      title: Text(item.title, style: const TextStyle(color: AppTheme.textPrimary),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('$pct%', style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        onPressed: () => provider.cancel(item.id),
      ),
    );
  }
}

// ── Failed/paused tile with retry ──
class _FailedTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadProvider provider;
  const _FailedTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isPaused = item.status == DownloadStatus.paused;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.cancel(item.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _CoverThumb(cover: item.cover, type: item.type),
        title: Text(item.title, style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          isPaused ? 'Paused - ${(item.progress * 100).toInt()}%' : 'Failed',
          style: TextStyle(
            color: isPaused ? Colors.amber : AppTheme.error,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primary),
              tooltip: 'Retry',
              onPressed: () => provider.cancel(item.id), // cancel clears, user re-triggers from detail
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
              onPressed: () => provider.cancel(item.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completed tile with swipe-to-delete ──
class _CompletedTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadProvider provider;
  const _CompletedTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteDownload(item.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _CoverThumb(cover: item.cover, type: item.type),
        title: Text(item.title, style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(children: [
          Icon(
            item.type == ContentType.komik ? Icons.menu_book : Icons.play_circle,
            size: 14, color: AppTheme.success,
          ),
          const SizedBox(width: 4),
          Text(
            item.type == ContentType.komik ? 'Ready to read offline' : 'Ready to play offline',
            style: const TextStyle(color: AppTheme.success, fontSize: 12),
          ),
        ]),
        trailing: IconButton(
          icon: Icon(
            item.type == ContentType.komik ? Icons.menu_book : Icons.play_arrow,
            color: AppTheme.primary,
          ),
          onPressed: () {
            // TODO: Open offline player/reader with item.localPath
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offline playback coming soon')),
            );
          },
        ),
      ),
    );
  }
}

// ── Cover thumbnail helper ──
class _CoverThumb extends StatelessWidget {
  final String? cover;
  final ContentType type;
  const _CoverThumb({this.cover, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: (cover != null && cover!.isNotEmpty)
          ? Image.network(cover!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackIcon())
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() => Center(
    child: Icon(
      type == ContentType.komik ? Icons.menu_book : Icons.movie,
      color: AppTheme.textSecondary, size: 24,
    ),
  );
}
