import 'package:flutter/material.dart';

import 'data/app_store.dart';
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

class _SpendWiseAppState extends State<SpendWiseApp> {
  final AppStore store = AppStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: !store.ready
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : store.loadError != null
                ? Scaffold(
                    appBar: AppBar(title: const Text('SpendWise')),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(store.loadError!, textAlign: TextAlign.center),
                      ),
                    ),
                  )
                : HomeShell(store: store),
      ),
    );
  }
}
