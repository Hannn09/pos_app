import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/data/local/database_helper.dart';
import 'package:food_pos/routers/app_router.dart';
import 'package:food_pos/theme/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Database SQLite & seeding otomatis saat pertama kali run
  await DatabaseHelper.instance.database;
  await DatabaseHelper.instance.inspectDatabase();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      routerConfig: appRouter,
    );
  }
}
