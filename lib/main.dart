import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/datasources/local/local_database.dart';
import 'presentation/widgets/glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.backgroundDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await LocalDatabase.init();
  } catch (e) {
    debugPrint('Database error: $e. Reinitializing...');
    try {
      await Hive.deleteFromDisk();
      await LocalDatabase.init();
    } catch (e2) {
      debugPrint('Fatal database error: $e2');
    }
  }

  // Catch uncaught Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

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
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return AppBackground(child: child ?? const SizedBox());
      },
    );
  }
}
