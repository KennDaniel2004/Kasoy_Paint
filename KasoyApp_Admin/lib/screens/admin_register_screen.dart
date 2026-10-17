import 'package:flutter/material.dart';

import '../main.dart';
import '../services/admin_auth_service.dart';
import 'admin_dashboard_screen.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AdminAuthService.instance.registerFirstAdmin(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => false,
      );
    } on AdminAuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AdminColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AdminColors.textDark),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Admin Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One-time setup. Once created, no other admin can '
                  'register from this app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const _Label('Full Name'),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(hintText: 'Juan Dela Cruz'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                const _Label('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'admin@kasoypaintingshop.com'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 14),
                const _Label('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AdminColors.textGrey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password too short'
                      : null,
                ),
                const SizedBox(height: 14),
                const _Label('Confirm Password'),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration:
                      const InputDecoration(hintText: 'Re-enter password'),
                  validator: (v) => (v != _passwordController.text)
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Create Admin Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AdminColors.textDark,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}