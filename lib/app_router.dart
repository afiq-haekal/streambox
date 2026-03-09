import 'package:flutter/material.dart';
import 'models/content_model.dart';

// Screen imports (will be created in later phases)
import 'screens/main_shell.dart';
import 'screens/search_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/player_screen.dart';
import 'screens/komik_reader_screen.dart';
import 'screens/downloads_screen.dart';

/// Named route constants
class Routes {
  static const String home = '/';
  static const String search = '/search';
  static const String detail = '/detail';
  static const String player = '/player';
  static const String komikReader = '/komik-reader';
  static const String downloads = '/downloads';
}

/// Centralized route generation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return _fade(const MainShell());

      case Routes.search:
        final query = settings.arguments as String?;
        return _slide(SearchScreen(initialQuery: query));

      case Routes.detail:
        final args = settings.arguments as DetailArgs;
        return _slide(DetailScreen(args: args));

      case Routes.player:
        final args = settings.arguments as PlayerArgs;
        return _fade(PlayerScreen(args: args));

      case Routes.komikReader:
        final args = settings.arguments as KomikReaderArgs;
        return _fade(KomikReaderScreen(args: args));

      case Routes.downloads:
        return _slide(const DownloadsScreen());

      default:
        return _fade(const Scaffold(
          body: Center(child: Text('Page not found')),
        ));
    }
  }

  /// Fade transition
  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );

  /// Slide from right transition
  static PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

/// Route argument classes
class DetailArgs {
  final ContentItem item;
  DetailArgs({required this.item});
}

class PlayerArgs {
  final String streamUrl;
  final String title;
  final int? episodeNumber;
  final String? platform;
  final ContentItem? contentItem; // for history tracking
  PlayerArgs({
    required this.streamUrl,
    required this.title,
    this.episodeNumber,
    this.platform,
    this.contentItem,
  });
}

class KomikReaderArgs {
  final String chapterId;
  final String title;
  final int? chapterNumber;
  final ContentItem? contentItem; // for history tracking
  KomikReaderArgs({
    required this.chapterId,
    required this.title,
    this.chapterNumber,
    this.contentItem,
  });
}
