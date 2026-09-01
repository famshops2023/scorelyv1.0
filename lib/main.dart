import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/error_reporter.dart';
import 'services/sync_manager.dart';
import 'widgets/error_boundary.dart';

void main() {
  // ── 1. Ensure Flutter is initialised before anything else ────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Flutter framework errors (widget build failures, render errors) ───
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to local file
    ErrorReporter.instance.log(
      details.exception,
      details.stack,
      context: details.context?.toString() ?? 'Flutter framework error',
    );
    // In debug, keep default red-screen behaviour for quick diagnosis
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // ── 3. Platform/engine-level errors (native channel crashes, etc.) ───────
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.instance.log(error, stack, context: 'PlatformDispatcher');
    return true; // Returning true means "handled – don't re-throw"
  };

  // ── 4. Custom error widget (replaces the red screen in release builds) ───
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Debug: keep the default red error widget so devs see the full trace
      return ErrorWidget(details.exception);
    }
    return AppErrorWidget(details: details);
  };

  // ── 5. System UI ──────────────────────────────────────────────────────────
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // ── 6. runZonedGuarded catches ALL unhandled Dart / async errors ─────────
  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: ScorelyApp(),
        ),
      );
    },
    (error, stack) {
      ErrorReporter.instance.log(error, stack, context: 'runZonedGuarded');
    },
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
