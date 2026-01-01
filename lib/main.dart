import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MediaKit.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingComplete =
      prefs.getBool('isOnboardingComplete') ?? false;

  runApp(MyApp(isOnboardingComplete: isOnboardingComplete));
}

class MyApp extends StatelessWidget {
  final bool isOnboardingComplete;

  const MyApp({
    super.key,
    required this.isOnboardingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeCinema',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home:
          isOnboardingComplete ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
