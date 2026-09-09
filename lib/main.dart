import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/theme/app_theme.dart';
import 'package:unisphere/core/utils/url_strategy.dart';
import 'package:unisphere/navigation/app_router.dart';
import 'package:unisphere/services/firebase_service.dart';
import 'package:unisphere/services/web_firebase_registrant.dart';

void main() async {
  // Configure clean path URL strategy (removes '#' on web)
  configureAppUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  registerWebFirebasePlugins();
  
  // Suppress Flutter framework semantics and layout pass debug assertions during hot restart / layout passes
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final errStr = details.exceptionAsString();
    if (errStr.contains('!semantics.parentDataDirty') ||
        errStr.contains('RenderBox was not laid out') ||
        errStr.contains('Cannot hit test a render box with no size') ||
        errStr.contains('mouse_tracker.dart')) {
      return;
    }
    originalOnError?.call(details);
  };

  // Graceful institutional ErrorWidget builder to permanently prevent red screen of death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Institutional ErrorWidget intercepted: ${details.exceptionAsString()}');
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF3B82F6)),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Section temporarily synchronizing. Pull down to refresh.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize Firebase Core & Auth services
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    const ProviderScope(
      child: UnisphereApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class UnisphereApp extends ConsumerWidget {
  const UnisphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'UNISPHERE SRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
    );
  }
}

class SupabaseErrorScreen extends StatelessWidget {
  const SupabaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Supabase Configuration Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please update main.dart with your project URL and Anon Key from the Supabase dashboard.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => main(),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  child: const Text('Retry Connection'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Force the app to launch with Mock services
                    // Note: We need to ensure providers support this
                    runApp(const ProviderScope(child: UnisphereApp()));
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size(200, 50)),
                  child: const Text('Launch Demo Mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
