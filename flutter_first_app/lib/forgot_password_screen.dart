import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'login_screen.dart';

/// "Forgot Password" flow.
///
/// ARCHITECTURE NOTE — read this before wiring up your own version of the
/// "Enter your pass code" (6-box) screen from the mockup:
///
/// This uses Firebase Auth's built-in `sendPasswordResetEmail`, which
/// emails the user a secure one-time RESET LINK. Firebase's client SDK
/// has no way to generate or send an arbitrary numeric code by itself —
/// a real 6-digit-code flow needs a backend: a Cloud Function to generate
/// the code, store it (e.g. Firestore) with an expiry, send it through an
/// email API (SendGrid, Mailgun, etc), and a second function to verify it
/// and reset the password via the Admin SDK. That requires the paid
/// Blaze plan plus an email provider account.
///
/// This screen gets people a working, secure password reset TODAY with
/// zero extra infrastructure, using the same visual language as the rest
/// of the app. Swap in the code-based flow later if you set up the
/// backend for it.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final message = switch (e.code) {
        'user-not-found' => 'No account found for that email.',
        'invalid-email' => 'That email address looks invalid.',
        _ => e.message ?? 'Could not send reset email. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.textDark, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _sent
                    ? _SentConfirmation(onBackToLogin: _backToLogin)
                    : _EmailForm(
                        formKey: _formKey,
                        controller: _emailController,
                        sending: _sending,
                        onSend: _sendResetEmail,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Back to ',
                      style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: _backToLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.formKey,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter Gmail Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll email you a secure link to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'you@gmail.com'),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: sending ? null : onSend,
            child: sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Send Code'),
          ),
        ],
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.onBackToLogin});
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Verified — Check Your Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We sent a password reset link to your inbox. Open it to '
              'choose a new password, then come back and log in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textGrey, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onBackToLogin,
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
