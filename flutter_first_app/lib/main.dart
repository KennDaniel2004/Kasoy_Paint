import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This was previously missing entirely, so Firebase was never
  // initialized and every Firestore/Auth call silently failed.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KasoyApp());
}

/// Central place for the app's color palette, matching the Figma design.
class AppColors {
  static const Color splashBg = Color(0xFF1C1B20); // dark charcoal splash bg
  static const Color surfaceLight = Color(0xFFF7F6F2); // onboarding/auth bg
  static const Color primaryOrange = Color(0xFFFF6A1A);
  static const Color textDark = Color(0xFF17171B);
  static const Color textGrey = Color(0xFF8B8B93);
  static const Color fieldFill = Color(0xFFF1EFEA);
  static const Color success = Color(0xFF34C759);
}

class KasoyApp extends StatelessWidget {
  const KasoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasoy Paint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surfaceLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
          primary: AppColors.primaryOrange,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primaryOrange,
          selectionHandleColor: AppColors.primaryOrange,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.4),
          ),
          hintStyle: const TextStyle(color: AppColors.textGrey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}