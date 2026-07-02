import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'db/database_helper.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const StudyFlowApp(),
    ),
  );
}
