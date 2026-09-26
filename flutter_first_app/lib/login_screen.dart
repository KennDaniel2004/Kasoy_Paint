import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'biometric_scan_screen.dart';
import 'forgot_password_screen.dart';
import 'services/biometric_service.dart';
import 'services/firestore_service.dart';
import 'services/session_service.dart';

/// UI-facing biometric state for this screen. Kept separate from the
/// device-level "does this phone support fingerprints" check — that check
/// alone must never be used to decide whether biometric login is offered
/// or triggered.
enum _BiometricUiState {
  /// No biometric has been registered for this device/account yet, or the
  /// registration that used to exist is no longer valid (biometrics were
  /// removed from the device, enrollment changed, etc).
  notRegistered,

  /// A biometric registration exists and is currently valid. The Quick
  /// Fingerprint Login button is enabled, but authentication has NOT been
  /// started — it only starts when the user taps the button.
  registered,

  /// The OS biometric prompt is currently open, waiting on the user.
  authenticating,

  /// The most recent attempt did not succeed. Still allowed to retry —
  /// functionally the same as [registered] for the button, just used to
  /// show a "try again" style message.
  authenticationFailed,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  _BiometricUiState _biometricState = _BiometricUiState.notRegistered;
  String? _linkedUid;

  // Whether this phone has ever completed registration (any account).
  // Used purely to hide the "Create Account" link — a device that's
  // already registered has nowhere useful for that link to go, since
  // RegisterScreen blocks a second registration anyway.
  bool _deviceRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // NOTE: this ONLY reads persisted state to decide whether to enable
    // the Quick Fingerprint Login button. It never opens the OS biometric
    // prompt by itself — that only happens from
    // _onQuickFingerprintButtonPressed, in response to a tap.
    _refreshBiometricState();
    _refreshDeviceRegisteredState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-validate (not re-authenticate) when the user comes back to the
    // app, in case biometric enrollment changed while it was backgrounded.
    if (state == AppLifecycleState.resumed) {
      _refreshBiometricState();
    }
  }

  /// Determines whether Quick Fingerprint Login should be offered.
  ///
  /// This is a REGISTRATION check, not an authentication attempt:
  ///   1. Has this device previously completed biometric registration
  ///      (`SessionService.getBiometricUid()` returns a uid)?
  ///   2. Is that registration still valid — does the device still
  ///      support biometrics, and is something still enrolled at the OS
  ///      level?
  ///
  /// "Device supports biometrics" on its own is deliberately NOT enough —
  /// that only means the hardware exists, not that this app/account ever
  /// registered it.
  Future<void> _refreshBiometricState() async {
    final linkedUid = await SessionService.instance.getBiometricUid();

    if (linkedUid == null) {
      if (!mounted) return;
      setState(() {
        _linkedUid = null;
        _biometricState = _BiometricUiState.notRegistered;
      });
      return;
    }

    final hasBiometrics = await BiometricService.instance.isDeviceSupported();
    final enrolled = hasBiometrics
        ? await BiometricService.instance.availableBiometrics()
        : const <dynamic>[];

    if (!mounted) return;

    if (hasBiometrics && enrolled.isNotEmpty) {
      setState(() {
        _linkedUid = linkedUid;
        _biometricState = _BiometricUiState.registered;
      });
    } else {
      // The registration on file is stale — biometrics were removed or
      // are no longer available on this device. Clear it so the UI
      // reflects reality instead of offering a button that can't work.
      await SessionService.instance.clearBiometric();
      if (!mounted) return;
      setState(() {
        _linkedUid = null;
        _biometricState = _BiometricUiState.notRegistered;
      });
    }
  }

  Future<void> _refreshDeviceRegisteredState() async {
    final registered = await SessionService.instance.isDeviceRegistered();
    if (!mounted) return;
    setState(() => _deviceRegistered = registered);
  }

  bool get _biometricEnabled => _biometricState != _BiometricUiState.notRegistered;

  String get _biometricLabel {
    switch (_biometricState) {
      case _BiometricUiState.authenticating:
        return 'Scanning fingerprint…';
      case _BiometricUiState.notRegistered:
        return 'Fingerprint not set up on this device';
      case _BiometricUiState.registered:
      case _BiometricUiState.authenticationFailed:
        return 'Quick Fingerprint Login';
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = credential.user!.uid;

      if (!mounted) return;

      final alreadyLinked = await SessionService.instance.getBiometricUid();
      final biometricEnabledOnAccount =
          await FirestoreService.instance.isBiometricEnabled(uid);
      final deviceSupportsBiometrics =
          await BiometricService.instance.isDeviceSupported();

      if (biometricEnabledOnAccount &&
          deviceSupportsBiometrics &&
          alreadyLinked != uid &&
          mounted) {
        await _offerToLinkBiometrics(uid);
      }

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' => 'No account found for that email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'That email address looks invalid.',
        'invalid-credential' => 'Incorrect email or password.',
        _ => e.message ?? 'Login failed. Please try again.',
      };
      _showSnack(message, isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Part of ONE-TIME BIOMETRIC REGISTRATION — offered right after a
  /// successful password login, on an account that has biometrics enabled
  /// but hasn't linked THIS device yet. This is separate from, and never
  /// triggers, biometric authentication.
  Future<void> _offerToLinkBiometrics(String uid) async {
    final shouldLink = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Quick Fingerprint Login?'),
        content: const Text(
          'This account has fingerprint login turned on. Link it to this '
          'device so you can log in with your fingerprint next time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldLink != true) return;

    final result = await BiometricService.instance.authenticate(
      reason: 'Scan your fingerprint to enable Quick Fingerprint Login',
    );
    if (result == BiometricCheckResult.success) {
      await SessionService.instance.setBiometricEnabledForUid(uid);
      if (mounted) {
        setState(() {
          _linkedUid = uid;
          _biometricState = _BiometricUiState.registered;
        });
        _showSnack('Quick Fingerprint Login enabled on this device.');
      }
    }
  }

  /// Entry point for the "Quick Fingerprint Login" button. This is the
  /// ONLY place that ever opens the BIOMETRIC LOGIN screen. It is never
  /// called from initState, build, app resume, or any other automatic
  /// trigger — only a direct user tap reaches this method.
  Future<void> _onQuickFingerprintButtonPressed() async {
    if (_biometricState == _BiometricUiState.notRegistered) {
      _showSnack(
        'No fingerprint is registered on this device yet. Log in with your '
        'password once, then enable it when prompted.',
      );
      return;
    }
    if (_biometricState == _BiometricUiState.authenticating) return;

    final linkedUid = _linkedUid;
    if (linkedUid == null) return;

    setState(() => _biometricState = _BiometricUiState.authenticating);

    final outcome = await Navigator.of(context).push<BiometricScanOutcome>(
      MaterialPageRoute(
        builder: (_) => BiometricScanScreen(linkedUid: linkedUid),
      ),
    );

    if (!mounted) return;

    switch (outcome) {
      case BiometricScanOutcome.success:
        _goHome();
        return;

      case BiometricScanOutcome.staleSession:
        // The fingerprint matched, but the Firebase session behind it is
        // gone (e.g. fully signed out elsewhere). The registration is
        // stale — clear it rather than let the button fail silently
        // every time from now on.
        await SessionService.instance.clearBiometric();
        setState(() {
          _linkedUid = null;
          _biometricState = _BiometricUiState.notRegistered;
        });
        _showSnack('Your session expired. Please log in again with your password.');
        return;

      case BiometricScanOutcome.notEnrolled:
        await SessionService.instance.clearBiometric();
        setState(() {
          _linkedUid = null;
          _biometricState = _BiometricUiState.notRegistered;
        });
        _showSnack(
          'No fingerprint is enrolled on this device anymore. Please log in '
          'with your password.',
        );
        return;

      case BiometricScanOutcome.notAvailable:
        setState(() => _biometricState = _BiometricUiState.authenticationFailed);
        _showSnack('Biometrics unavailable right now. Please log in with your password.');
        return;

      case BiometricScanOutcome.cancelled:
      case null:
        // User backed out of the biometric screen — just return to Login.
        setState(() => _biometricState = _BiometricUiState.registered);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The regular Login screen is ALWAYS the screen built here — there is
    // no branch that swaps in a full-screen biometric view on its own.
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/main_logo.jpg',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Log-In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('EMAIL ADDRESS'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'maria.santos@gmail.com',
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 18),
                const _FieldLabel('PASSWORD'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password is too short'
                      : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _biometricState == _BiometricUiState.authenticating
                      ? null
                      : _onQuickFingerprintButtonPressed,
                  icon: _biometricState == _BiometricUiState.authenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.fingerprint,
                          color: _biometricEnabled
                              ? AppColors.primaryOrange
                              : Colors.grey.shade400,
                        ),
                  label: Text(
                    _biometricLabel,
                    style: TextStyle(
                      color:
                          _biometricEnabled ? AppColors.textDark : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_deviceRegistered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: AppColors.textGrey)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Shared field label ─────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }
}