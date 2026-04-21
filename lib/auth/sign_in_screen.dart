library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/shared_identity_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await SharedIdentityService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message ?? 'Autentikasi gagal.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Autentikasi gagal.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.description ??
                      'Masuk dengan akun Google untuk melanjutkan, termasuk izin kalender untuk sinkron interview.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _isSubmitting
                          ? 'Menyambungkan Google...'
                          : 'Masuk dengan Google',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
