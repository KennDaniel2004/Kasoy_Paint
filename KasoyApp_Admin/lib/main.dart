import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KasoyAdminApp());
}

class AdminColors {
  static const Color splashBg = Color(0xFF1C1B20);
  static const Color surfaceLight = Color(0xFFF7F6F2);
  static const Color primaryOrange = Color(0xFFFF6A1A);
  static const Color textDark = Color(0xFF17171B);
  static const Color textGrey = Color(0xFF8B8B93);
  static const Color fieldFill = Color(0xFFF1EFEA);
  static const Color success = Color(0xFF34C759);
  static const Color statusScheduled = Color(0xFF2563EB);
  static const Color statusQuoted = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
}

class KasoyAdminApp extends StatelessWidget {
  const KasoyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasoy Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AdminColors.surfaceLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.primaryOrange,
          primary: AdminColors.primaryOrange,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AdminColors.fieldFill,
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
            borderSide: const BorderSide(
              color: AdminColors.primaryOrange,
              width: 1.4,
            ),
          ),
          hintStyle: const TextStyle(color: AdminColors.textGrey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      home: const AdminSplashScreen(),
    );
  }
}