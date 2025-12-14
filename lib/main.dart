import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://srfdbrsxytouwkysdyzs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyZmRicnN4eXRvdXdreXNkeXpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTQ4MDQsImV4cCI6MjA4MTAzMDgwNH0.tKTqO2quQ3Patg9-P7j1Ddx7EvfoiPWYEcQ7LTWNF0c',
  );
  
  // Initialize settings before running app
  final settingsService = SettingsService();
  await settingsService.init();

  final historyService = HistoryService();
  await historyService.init();
  
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: historyService),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    
    return MaterialApp(
      title: 'AI Homework Solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006400)), // Dark Green
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      locale: settings.locale,
      home: const HomeScreen(),
    );
  }
}
