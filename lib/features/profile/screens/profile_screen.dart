import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(authControllerProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      data: (profile) {
        final email = profile?['email']?.toString() ?? user?.email;
        final name = profile?['full_name']?.toString() ??
            profile?['name']?.toString() ??
            user?.userMetadata?['name']?.toString();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              name?.isNotEmpty == true ? name! : 'Your Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(email?.isNotEmpty == true ? email! : '—'),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
              },
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 20),
            // TODO: render more profile fields once you confirm your `profiles` schema.
            const Text('More profile fields will appear here (TODO).'),
          ],
        );
      },
    );
  }
}

