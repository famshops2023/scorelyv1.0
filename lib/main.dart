import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/sync_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force edge-to-edge on all Android versions so the system navigation
  // bar is transparent and Flutter's SafeArea insets work correctly.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  runApp(
    const ProviderScope(
      child: ScorelyApp(),
    ),
  );
}

class ScorelyApp extends ConsumerStatefulWidget {
  const ScorelyApp({super.key});

  @override
  ConsumerState<ScorelyApp> createState() => _ScorelyAppState();
}

class _ScorelyAppState extends ConsumerState<ScorelyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    // Bootstrap sync manager so it starts listening for connectivity immediately.
    ref.read(syncManagerProvider);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle incoming links while the app is in the background or foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      // Example uri: https://scorely.com/joinTeam?teamId=123
      if (uri.path.isNotEmpty) {
        final query = uri.hasQuery ? '?${uri.query}' : '';
        goRouter.go('${uri.path}$query');
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scorely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
