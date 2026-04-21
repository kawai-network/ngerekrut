library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/shared_identity_service.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.child,
    required this.title,
    this.description,
  });

  final Widget child;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: SharedIdentityService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AuthErrorState(
            message: 'Gagal membaca status autentikasi.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingState();
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(title: title, description: description);
        }

        return child;
      },
    );
  }
}

class _AuthLoadingState extends StatelessWidget {
  const _AuthLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthErrorState extends StatelessWidget {
  const _AuthErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
