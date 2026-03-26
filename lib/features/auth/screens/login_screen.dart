import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: authState.isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle();
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

