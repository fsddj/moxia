import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';

class MoXiaApp extends StatelessWidget {
  const MoXiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
