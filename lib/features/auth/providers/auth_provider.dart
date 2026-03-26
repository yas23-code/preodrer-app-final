import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );
  if (user == null) return null;

  final supabase = ref.read(supabaseClientProvider);

  // TODO: fill in the correct profiles table column names / primary key mapping.
  final row = await supabase
      .from(kProfilesTableName)
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return row;
});

class AuthController extends AsyncNotifier<User?> {
  StreamSubscription? _authSubscription;

  @override
  Future<User?> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final currentUser = supabase.auth.currentUser;

    _authSubscription?.cancel();
    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      state = AsyncValue.data(event.session?.user);
    });

    ref.onDispose(() async {
      await _authSubscription?.cancel();
    });

    return currentUser;
  }

  Future<void> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an idToken.');
    }

    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}

