import 'package:flutter/material.dart';

import '../main.dart';
import 'admin_login_screen.dart';

/// Dark splash shown while the app boots. After a short delay, it
/// routes to the Login screen. If a user is already signed in AND has
/// an admin profile, we could skip straight to the dashboard later —
/// for now we always show Login, keeping the flow simple.
class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset(
                'assets/images/main_logo.jpg',
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 220,
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage. Track. Serve.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(flex: 4),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white38, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    AdminColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}