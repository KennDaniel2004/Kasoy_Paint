import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'kasoy_logo.dart';
import 'services/biometric_service.dart';

/// Result handed back to whoever pushed this screen.
enum BiometricScanOutcome {
  success,
  staleSession,
  notEnrolled,
  notAvailable,
  cancelled,
}

/// The "BIOMETRIC LOGIN" screen from the flow diagram.
///
/// IMPORTANT: this screen is reached ONLY by an explicit push from
/// LoginScreen's "Quick Fingerprint Login" button. Nothing else — not
/// app startup, not a splash screen, not initState of any other widget —
/// is allowed to navigate here on its own. It pops itself with an
/// outcome; the caller (LoginScreen) decides what to do next.
class BiometricScanScreen extends StatefulWidget {
  const BiometricScanScreen({super.key, required this.linkedUid});

  final String linkedUid;

  @override
  State<BiometricScanScreen> createState() => _BiometricScanScreenState();
}

class _BiometricScanScreenState extends State<BiometricScanScreen> {
  bool _scanning = true;
  String _statusText = 'Scan your fingerprint to continue';

  @override
  void initState() {
    super.initState();
    // Safe to auto-start the scan HERE, because arriving at this screen
    // already required a deliberate tap on Quick Fingerprint Login.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _statusText = 'Scan your fingerprint to continue';
    });

    final result = await BiometricService.instance.authenticate(
      reason: 'Scan your fingerprint to log in to Kasoy Painting Shop',
    );

    if (!mounted) return;

    switch (result) {
      case BiometricCheckResult.success:
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == widget.linkedUid) {
          Navigator.of(context).pop(BiometricScanOutcome.success);
        } else {
          Navigator.of(context).pop(BiometricScanOutcome.staleSession);
        }
        return;

      case BiometricCheckResult.notEnrolled:
        Navigator.of(context).pop(BiometricScanOutcome.notEnrolled);
        return;

      case BiometricCheckResult.notAvailable:
        Navigator.of(context).pop(BiometricScanOutcome.notAvailable);
        return;

      case BiometricCheckResult.failed:
      case BiometricCheckResult.error:
        // Stay on this screen so the user can retry or back out.
        setState(() {
          _scanning = false;
          _statusText = 'Fingerprint not recognized. Tap to try again.';
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14131A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const KasoyLogo(size: 100),
              const SizedBox(height: 28),
              const Text(
                'Biometric Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _scanning ? null : _scan,
                child: Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primaryOrange,
                        Colors.black26,
                        Colors.black26,
                        AppColors.primaryOrange,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1C1B20),
                    ),
                    child: _scanning
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Icon(Icons.fingerprint,
                            size: 72, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _scanning ? 'Waiting for fingerprint…' : 'Tap the sensor to try again',
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
              const Spacer(flex: 2),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(BiometricScanOutcome.cancelled),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}