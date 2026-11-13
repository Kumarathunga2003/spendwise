import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'data/app_store.dart';
import 'notifications/expense_notifications.dart';
import 'security/app_security.dart';
import 'security/lock_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatefulWidget {
  const SpendWiseApp({super.key});

  @override
  State<SpendWiseApp> createState() => _SpendWiseAppState();
}

class _SpendWiseAppState extends State<SpendWiseApp>
    with WidgetsBindingObserver {
  final AppStore store = AppStore();
  final AppSecurity security = AppSecurity.instance;

  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();

    _lockTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => security.checkForegroundTimeout(),
    );
  }

  Future<void> _initialize() async {
    await security.load();
    await store.load();

    if (store.loadError == null) {
      try {
        await ExpenseNotifications.sync(
          store.features.reminders,
        );
      } catch (_) {
        // Notifications are optional.
        // Never block financial data loading.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      security.onPause();
    } else if (state == AppLifecycleState.resumed) {
      security.onResume();

      if (store.ready && store.loadError == null) {
        store.processRecurringNow().catchError((Object _) {
          // Keep the app responsive if recurring processing fails.
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _lockTimer?.cancel();
    store.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        store,
        security,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'SpendWise',
          debugShowCheckedModeBanner: false,
          // Keep layouts readable if Android font size is set very large.
          // Honor system scaling up to 125% (accessibility trade-off).
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.25,
            child: child ?? const SizedBox.shrink(),
          ),

          // Smooth theme transitions.
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeOutCubic,

          // Application themes.
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,

          // Application startup and security.
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    // Wait until security and financial data are initialized.
    if (!security.ready || !store.ready) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show a helpful message if financial data cannot load.
    if (store.loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SpendWise'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              store.loadError!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // PIN-only application lock.
    if (security.enabled && !security.unlocked) {
      return SpendWiseLockScreen(
        security: security,
      );
    }

    // Main SpendWise application.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => security.touch(),
      child: HomeShell(store: store),
    );
  }
}
