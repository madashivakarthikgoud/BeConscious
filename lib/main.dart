import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/datasources/local/local_database.dart';

// Firebase imports — uncomment after setting up Firebase
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surfaceDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize local database (works offline, always)
  await LocalDatabase.init();

  // Initialize Firebase — uncomment after setting up Firebase
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   debugPrint('Firebase not configured yet: $e');
  // }

  runApp(const ProviderScope(child: BeConsciousApp()));
}

class BeConsciousApp extends ConsumerWidget {
  const BeConsciousApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BeConscious',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // AMOLED optimized dark mode default
      routerConfig: appRouter,
    );
  }
}
