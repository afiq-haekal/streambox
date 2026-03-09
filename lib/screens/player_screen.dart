import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../app_router.dart';
import '../app_theme.dart';
import '../providers/storage_provider.dart';

/// Full-screen video player using Chewie.
/// Supports landscape lock, play/pause, seek, and episode info overlay.
class PlayerScreen extends StatefulWidget {
  final PlayerArgs args;
  const PlayerScreen({super.key, required this.args});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Lock to landscape for immersive playback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.args.streamUrl),
      );

      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          bufferedColor: AppTheme.textSecondary.withOpacity(0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Playback error',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryPlayback,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {});
        // Save to watch history
        if (widget.args.contentItem != null) {
          context.read<StorageProvider>().addHistory(widget.args.contentItem!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _retryPlayback() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _chewieController?.dispose();
    _videoController.dispose();
    _chewieController = null;
    await _initPlayer();
  }

  @override
  void dispose() {
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          Center(
            child: _hasError
                ? _buildErrorView()
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const CircularProgressIndicator(color: AppTheme.primary),
          ),

          // Top overlay — back button + title
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopOverlay(
              title: widget.args.title,
              episodeNumber: widget.args.episodeNumber,
              onBack: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Failed to load video',
          style: const TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _retryPlayback,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Retry'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Top overlay with back button, title, and episode number.
/// Fades in on tap and auto-hides.
class _TopOverlay extends StatelessWidget {
  final String title;
  final int? episodeNumber;
  final VoidCallback onBack;

  const _TopOverlay({
    required this.title,
    this.episodeNumber,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episodeNumber != null)
                      Text(
                        'Episode $episodeNumber',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
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
