import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/storage/local_cache_service.dart';
import 'core/constants/app_constants.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  final localCache = await LocalCacheService.init();

  // Default to production mode with emulator URL for development
  final appMode = prefs.getString(AppConstants.keyAppMode) ?? 'production';
  final baseUrl = appMode == 'mock'
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://10.0.2.2:8000/api/v1';

  runApp(
    ProviderScope(
      overrides: [
        localCacheProvider.overrideWithValue(localCache),
        secureStorageProvider.overrideWithValue(secureStorage),
        baseUrlProvider.overrideWithValue(baseUrl),
      ],
      child: const MyApp(),
    ),
  );
}

final baseUrlProvider = Provider<String>((ref) {
  throw UnimplementedError('baseUrlProvider must be overridden in main.dart');
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}