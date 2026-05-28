import 'package:flutter/material.dart';

class ThemeInherited extends InheritedWidget {
  final VoidCallback toggle;
  final ThemeMode themeMode;

  const ThemeInherited({
    super.key,
    required this.toggle,
    required this.themeMode,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant ThemeInherited oldWidget) {
    return themeMode != oldWidget.themeMode;
  }

  static ThemeInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeInherited>();
  }

  static void toggleTheme(BuildContext context) {
    maybeOf(context)?.toggle();
  }

  static ThemeMode themeModeOf(BuildContext context) {
    return maybeOf(context)?.themeMode ?? ThemeMode.light;
  }

  static bool isDark(BuildContext context) {
    return themeModeOf(context) == ThemeMode.dark;
  }
}
