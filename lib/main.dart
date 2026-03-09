import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_theme.dart';
import 'app_router.dart';
import 'services/api_service.dart';
import 'providers/content_provider.dart';
import 'providers/download_provider.dart';
import 'providers/storage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('bookmarks');
  await Hive.openBox('history');
  await Hive.openBox('downloads');
  await Hive.openBox('settings');

  runApp(const StreamBoxApp());
}

class StreamBoxApp extends StatelessWidget {
  const StreamBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<ContentProvider>(
          create: (_) => ContentProvider(apiService),
        ),
        ChangeNotifierProvider<DownloadProvider>(
          create: (_) => DownloadProvider(),
        ),
        ChangeNotifierProvider<StorageProvider>(
          create: (_) => StorageProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'StreamBox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: Routes.home,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
