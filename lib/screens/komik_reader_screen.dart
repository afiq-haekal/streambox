import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../app_router.dart';
import '../app_theme.dart';
import '../providers/content_provider.dart';
import '../providers/storage_provider.dart';

/// Vertical scrollable komik reader with pinch-to-zoom.
/// Fetches chapter images via ContentProvider and displays them
/// in a continuous vertical scroll with per-image loading states.
class KomikReaderScreen extends StatefulWidget {
  final KomikReaderArgs args;
  const KomikReaderScreen({super.key, required this.args});

  @override
  State<KomikReaderScreen> createState() => _KomikReaderScreenState();
}

class _KomikReaderScreenState extends State<KomikReaderScreen> {
  List<String> _images = [];
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  final ScrollController _scrollController = ScrollController();

  // Track current page for the page indicator
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Immersive reading mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<ContentProvider>();
      final images = await provider.fetchChapterImages(widget.args.chapterId);

      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          if (images.isEmpty) _error = 'No images found for this chapter';
        });
        // Save to reading history
        if (images.isNotEmpty && widget.args.contentItem != null) {
          context.read<StorageProvider>().addHistory(widget.args.contentItem!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load chapter: $e';
        });
      }
    }
  }

  void _onScroll() {
    if (_images.isEmpty) return;
    // Estimate current page based on scroll position
    // Assume ~500px per image on average
    final estimatedPage = (_scrollController.offset / 500).floor();
    final page = estimatedPage.clamp(0, _images.length - 1);
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          if (_isLoading)
            _buildLoading()
          else if (_error != null)
            _buildError()
          else
            _buildReader(),

          // Top bar (togglable)
          if (_showControls)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildTopBar(),
            ),

          // Page indicator (togglable)
          if (_showControls && _images.isNotEmpty)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: _buildPageIndicator(),
            ),
        ],
      ),
    );
  }

  // ── Vertical scroll reader ──
  Widget _buildReader() {
    return GestureDetector(
      onTap: _toggleControls,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTap: () => _openZoomView(index),
            child: Image.network(
              _images[index],
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                final progress = loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null;
                return Container(
                  height: 400,
                  color: AppTheme.surface,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Page ${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppTheme.surface,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 32),
                      const SizedBox(height: 4),
                      Text('Page ${index + 1} failed',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Double-tap zoom view using PhotoView ──
  void _openZoomView(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Page ${index + 1}',
            style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: PhotoView(
          imageProvider: NetworkImage(_images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, event) => Center(
            child: CircularProgressIndicator(
              value: event == null ? null
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    ));
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.args.title,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.args.chapterNumber != null)
                      Text(
                        'Chapter ${widget.args.chapterNumber}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Scroll to top
              IconButton(
                icon: const Icon(Icons.vertical_align_top, color: Colors.white),
                onPressed: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page indicator ──
  Widget _buildPageIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_currentPage + 1} / ${_images.length}',
          style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Loading state ──
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text('Loading chapter...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── Error state ──
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImages,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
