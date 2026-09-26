import 'package:flutter/material.dart';
import '../main.dart';
import '../models/painting_service.dart';

class QuoteRequestScreen extends StatefulWidget {
  const QuoteRequestScreen({super.key, this.initialService});

  /// Optional preselected service (used when arriving from the details
  /// screen's "Request a Quote" button).
  final PaintingService? initialService;

  @override
  State<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends State<QuoteRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _notesController = TextEditingController();
  late PaintingService _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialService ?? PaintingService.samples.first;
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quote request sent'),
        content: const Text(
          'Thanks! Your quote request has been captured. Our team will '
          'get back to you shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Request a Quote',
          style: TextStyle(color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Tell us about your vehicle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We will prepare an estimate based on the details you '
                'provide. Final pricing is confirmed after inspection.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const _Label('SERVICE'),
              DropdownButtonFormField<PaintingService>(
                initialValue: _selected,
                items: PaintingService.samples
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selected = v);
                },
              ),
              const SizedBox(height: 16),
              const _Label('VEHICLE MODEL'),
              TextFormField(
                controller: _vehicleController,
                decoration:
                    const InputDecoration(hintText: 'e.g. Toyota Vios 2019'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const _Label('NOTES / DAMAGE DESCRIPTION'),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Deep scratch on front bumper...',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Request'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.textDark,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
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
          color: AppColors.textGrey,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}