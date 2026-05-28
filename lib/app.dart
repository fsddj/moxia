import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'utils/constants.dart';
import 'utils/theme_inherited.dart';
import 'screens/main_screen.dart';

class MoXiaApp extends StatelessWidget {
  const MoXiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _AppShell();
  }
}

class _AppShell extends StatefulWidget {
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  final DatabaseHelper _db = DatabaseHelper();
  ThemeMode _themeMode = ThemeMode.light;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await _db.getSetting('theme_mode');
    if (!mounted) return;
    setState(() {
      _themeMode = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _loaded = true;
    });
  }

  void _toggleTheme() {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _db.setSetting('theme_mode', next == ThemeMode.dark ? 'dark' : 'light');
    setState(() => _themeMode = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ThemeInherited(
          toggle: _toggleTheme,
          themeMode: _themeMode,
          child: child!,
        );
      },
      home: _loaded
          ? const MainScreen()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
