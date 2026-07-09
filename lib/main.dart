import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'db/database_helper.dart';
import 'providers/ai_provider.dart';
import 'providers/theme_provider.dart';
import 'services/demo_seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;
  await DemoSeedService().ensureDemoUser();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final aiProvider = AiProvider();
  await aiProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: aiProvider),
      ],
      child: const StudyFlowApp(),
    ),
  );
}
