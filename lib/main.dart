import 'package:flutter/material.dart';
import 'app.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  runApp(const MoXiaApp());
}
