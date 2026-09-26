import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart';
import 'kasoy_logo.dart';
import 'services/biometric_service.dart';
import 'services/firestore_service.dart';
import 'services/session_service.dart';

class PendingRegistration {
  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
}

enum _Step {
  intro,
  scanning,
  recognized,
  creating,
  created,
  unsupported,
  notEnrolled,
}

class FingerprintRegistrationScreen extends StatefulWidget {
  const FingerprintRegistrationScreen({super.key, required this.pending});

  final PendingRegistration pending;

  @override
  State<FingerprintRegistrationScreen> createState() =>
      _FingerprintRegistrationScreenState();
}

class _FingerprintRegistrationScreenState
    extends State<FingerprintRegistrationScreen> {
  _Step _step = _Step.intro;
  String? _errorMessage;
  bool _biometricWillBeEnabled = true;

  Future<void> _startFingerprintCheck() async {
    setState(() {
      _errorMessage = null;
      _step = _Step.scanning;
    });
    await _runScan();
  }

  Future<void> _runScan() async {
    final result = await BiometricService.instance.authenticate(
      reason: 'Scan your fingerprint to register it for Kasoy Painting Shop',
    );
    if (!mounted) return;

    switch (result) {
      case BiometricCheckResult.success:
        _biometricWillBeEnabled = true;
        setState(() => _step = _Step.recognized);

      case BiometricCheckResult.notEnrolled:
        _biometricWillBeEnabled = false;
        setState(() => _step = _Step.notEnrolled);

      case BiometricCheckResult.notAvailable:
        _biometricWillBeEnabled = false;
        setState(() => _step = _Step.unsupported);

      case BiometricCheckResult.failed:
        setState(() => _step = _Step.intro);
        _showSnack('Fingerprint not recognized. Please try again.');

      case BiometricCheckResult.error:
        setState(() => _step = _Step.intro);
        _showSnack('Something went wrong reading the sensor. Please try again.');
    }
  }

  Future<void> _createAccount({required bool enableBiometric}) async {
    setState(() => _step = _Step.creating);
    final p = widget.pending;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: p.email, password: p.password);
      final uid = credential.user!.uid;

      await credential.user!.updateDisplayName(p.fullName);

      await FirestoreService.instance.saveRegisteredUser(
        uid: uid,
        fullName: p.fullName,
        email: p.email,
        phone: p.phone,
      );

      if (enableBiometric) {
        await FirestoreService.instance.setBiometricEnabled(uid, true);
        await SessionService.instance.setBiometricEnabledForUid(uid);
      }

      // Mark this phone as "already registered" so the login screen
      // knows to show biometric-first login next time.
      await SessionService.instance.markDeviceRegistered();

      if (!mounted) return;
      setState(() => _step = _Step.created);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'That email is already registered.',
        'invalid-email' => 'That email address looks invalid.',
        'weak-password' => 'Please choose a stronger password.',
        _ => e.message ?? 'Registration failed. Please try again.',
      };
      _failAndGoBack(message);
    } catch (e) {
      _failAndGoBack('Error: $e');
    }
  }

  void _failAndGoBack(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _step = _Step.intro;
    });
    _showSnack(message, isError: true);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.intro,
      child: Scaffold(
        backgroundColor: _step == _Step.scanning
            ? const Color(0xFF14131A)
            : AppColors.surfaceLight,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.intro:
        return _IntroStep(
          key: const ValueKey('intro'),
          errorMessage: _errorMessage,
          onRegister: _startFingerprintCheck,
          onSkip: () => _createAccount(enableBiometric: false),
        );
      case _Step.scanning:
        return _ScanningStep(
          key: const ValueKey('scanning'),
          onCancel: () => setState(() => _step = _Step.intro),
        );
      case _Step.recognized:
        return _RecognizedStep(
          key: const ValueKey('recognized'),
          onUseAnotherFinger: () {
            setState(() => _step = _Step.scanning);
            _runScan();
          },
          onProceed: () => _createAccount(enableBiometric: true),
        );
      case _Step.notEnrolled:
        return _NotEnrolledStep(
          key: const ValueKey('notEnrolled'),
          onContinue: () => _createAccount(enableBiometric: false),
        );
      case _Step.unsupported:
        return _UnsupportedStep(
          key: const ValueKey('unsupported'),
          onContinue: () => _createAccount(enableBiometric: false),
        );
      case _Step.creating:
        return const _CreatingStep(key: ValueKey('creating'));
      case _Step.created:
        return _CreatedStep(
          key: const ValueKey('created'),
          onGoToLogin: _goToLogin,
        );
    }
  }
}

// ─────────────────────────── Step 1: intro ───────────────────────────

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    super.key,
    required this.onRegister,
    required this.onSkip,
    this.errorMessage,
  });

  final VoidCallback onRegister;
  final VoidCallback onSkip;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: [
          const KasoyLogo(size: 180),
          const SizedBox(height: 40),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.fingerprint,
                size: 52, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 24),
          const Text(
            'Use Your Fingerprint',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'For a faster and more secure account setup, you can use your '
            'fingerprint first before registering your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14.5, height: 1.4),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onRegister,
            child: const Text('Register Finger Print'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────── Step 2: scanning ──────────────────────────

class _ScanningStep extends StatelessWidget {
  const _ScanningStep({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/images/main_logo.jpg',
                width: 84, height: 84, fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Your Fingerprint',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Place your finger on the sensor to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          const Spacer(flex: 3),
          Container(
            width: 160,
            height: 160,
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
              child: const Icon(Icons.fingerprint, size: 78, color: Colors.white),
            ),
          ),
          const Spacer(flex: 4),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ───────────────────────── Step 3: recognized ─────────────────────────

class _RecognizedStep extends StatelessWidget {
  const _RecognizedStep({
    super.key,
    required this.onUseAnotherFinger,
    required this.onProceed,
  });

  final VoidCallback onUseAnotherFinger;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(
        children: [
          const _ConfettiBadge(icon: Icons.check, color: AppColors.success),
          const SizedBox(height: 24),
          const Text(
            'Fingerprint Recognized!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your fingerprint has been successfully verified. '
            'You can now create your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: onUseAnotherFinger,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: AppColors.primaryOrange),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Use another finger',
                style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onProceed, child: const Text('Proceed')),
        ],
      ),
    );
  }
}

// ───────────── Fallback A: sensor exists but nothing enrolled ─────────────

class _NotEnrolledStep extends StatelessWidget {
  const _NotEnrolledStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.fingerprint,
                size: 52, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Fingerprint Enrolled',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your phone has a fingerprint sensor, but no fingerprint is '
            'saved in Settings yet.\n\n'
            'Open Settings → Security → Fingerprint and add one, then come '
            'back. Or continue without fingerprint login.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}

// ───────────── Fallback B: no sensor / unsupported ─────────────

class _UnsupportedStep extends StatelessWidget {
  const _UnsupportedStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: Icon(Icons.fingerprint, size: 52, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fingerprint Not Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This device doesn\'t have a fingerprint sensor set up, so '
            'we\'ll skip that step. You can still log in with your email '
            'and password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}

// ───────────────────────── Step 4: creating ─────────────────────────

class _CreatingStep extends StatelessWidget {
  const _CreatingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.fingerprint,
                size: 52, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 20),
          const Text(
            'Creating your account...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Please wait a moment.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13.5)),
          const SizedBox(height: 28),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Step 5: created ─────────────────────────

class _CreatedStep extends StatelessWidget {
  const _CreatedStep({super.key, required this.onGoToLogin});

  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            children: [
              const KasoyLogo(size: 96),
              const SizedBox(height: 32),
              const _ConfettiBadge(icon: Icons.check, color: AppColors.success),
              const SizedBox(height: 24),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account has been successfully registered. '
                'Welcome to Kasoy Painting Shop!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                  onPressed: onGoToLogin, child: const Text('Go to Login')),
              const SizedBox(height: 120),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: 90,
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                          color: AppColors.primaryOrange.withValues(alpha: 0.55))),
                  Expanded(
                      child: Container(
                          color: Colors.redAccent.withValues(alpha: 0.45))),
                  Expanded(
                      child: Container(
                          color: Colors.blueAccent.withValues(alpha: 0.45))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── shared confetti badge ─────────────────────────

class _ConfettiBadge extends StatelessWidget {
  const _ConfettiBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static const _dots = <Color>[
    Colors.orange, Colors.blue, Colors.red, Colors.amber, Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < _dots.length; i++)
            Positioned(
              left: 10 + (i * 30) % 140,
              top: (i.isEven ? 6 : 100) + (i * 7) % 20,
              child: Transform.rotate(
                angle: i * 0.7,
                child: Container(
                  width: i.isEven ? 8 : 5,
                  height: i.isEven ? 3 : 5,
                  color: _dots[_dots.length == 0 ? 0 : i % _dots.length],
                ),
              ),
            ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }
}