import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/enums/app_theme.dart';
import 'screens/counter_list_screen.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppTheme appTheme;
  try {
    final themeIndex = prefs.getInt('appTheme') ?? 0;
    appTheme = AppTheme.values[themeIndex];
  } catch (e) {
    appTheme = AppTheme.deepPurple; // Default theme on error
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(appTheme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Counters',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: ThemeProvider.getThemeColor(themeProvider.appTheme),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.robotoMonoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const CounterListScreen(),
    );
  }
}
