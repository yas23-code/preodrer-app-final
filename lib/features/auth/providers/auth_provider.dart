import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

// ─── Custom exception for user-initiated cancellations ────────────
/// Thrown when the user deliberately cancels an auth flow (e.g. dismissing
/// the Google account picker). The UI should handle this silently.
class AuthCancelledException implements Exception {
  final String message;
  const AuthCancelledException([this.message = 'Sign-in was cancelled.']);
  @override
  String toString() => message;
}

// ─── Providers ────────────────────────────────────────────────────
final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

final currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );
  if (user == null) return null;

  final supabase = ref.read(supabaseClientProvider);

  final row = await supabase
      .from(kProfilesTableName)
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return row;
});

// ─── Auth Controller ──────────────────────────────────────────────
class AuthController extends AsyncNotifier<User?> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _fcmTokenSubscription;
  bool _googleInitialized = false;

  @override
  Future<User?> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final currentUser = supabase.auth.currentUser;

    _authSubscription?.cancel();
    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      state = AsyncValue.data(user);
      
      if (user != null) {
        _syncFcmToken(user.id);
      } else {
        _fcmTokenSubscription?.cancel();
      }
    });

    ref.onDispose(() async {
      await _authSubscription?.cancel();
      await _fcmTokenSubscription?.cancel();
    });

    return currentUser;
  }

  // ─── Email / Password Sign In ────────────────────────────────────
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw StateError('Sign-in failed. Please check your credentials.');
    }
  }

  // ─── Email / Password Sign Up ───────────────────────────────────
  /// [role] should be 'student' or 'vendor'.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );

    final user = response.user;
    if (user == null) {
      throw StateError('Sign-up failed. Please try again.');
    }

    // Upsert a row in the profiles table so backend has the user metadata.
    try {
      await supabase.from(kProfilesTableName).upsert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'role': role,
      });
    } catch (_) {
      // Profile upsert is best-effort; the RLS policy or schema
      // may handle this via a database trigger instead.
    }
  }

  // ─── Google Sign In ─────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    // 1. Initialize once with serverClientId (web client ID).
    //    This is REQUIRED on Android for the Credential Manager
    //    to request an ID token from Google.
    if (!_googleInitialized) {
      final webClientId = dotenv.env[kGoogleWebClientIdEnvKey] ?? '';
      if (webClientId.isEmpty) {
        developer.log(
          'WARNING: $kGoogleWebClientIdEnvKey is not set in .env. '
          'Google Sign-In will likely fail on Android.',
          name: 'AuthController',
        );
      }
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );
      _googleInitialized = true;
    }

    // 2. Trigger the account picker / Credential Manager.
    GoogleSignInAccount? account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      developer.log(
        'GoogleSignInException: code=${e.code}, description=${e.description}',
        name: 'AuthController',
      );
      // User deliberately dismissed the picker
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      // Any other Google-level failure
      throw StateError(
        'Google sign-in failed. Please check your internet connection '
        'and try again.',
      );
    }

    // 3. Extract the ID token.
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      developer.log(
        'Google account returned but idToken is null/empty. '
        'Ensure the Web Client ID is correctly configured.',
        name: 'AuthController',
      );
      throw StateError(
        'Could not retrieve authentication token from Google. '
        'Please try again.',
      );
    }

    // 4. Exchange the Google ID token with Supabase.
    //    Note: google_sign_in v7.2.0 only returns idToken from
    //    authentication. accessToken requires a separate authorization
    //    call via authorizationClient.authorizeScopes(), which is not
    //    needed for Supabase ID-token-based auth.
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // ─── Sign Out ───────────────────────────────────────────────────
  Future<void> signOut() async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google sign-out can throw if user wasn't signed in via Google.
    }
  }

  // ─── FCM Token Management ───────────────────────────────────────
  Future<void> _syncFcmToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      final token = await messaging.getToken();
      if (token != null) {
        final supabase = ref.read(supabaseClientProvider);
        await supabase.from('user_device_tokens').upsert({
          'user_id': userId,
          'fcm_token': token,
        });
      }

      await _fcmTokenSubscription?.cancel();
      _fcmTokenSubscription = messaging.onTokenRefresh.listen((newToken) async {
        final supabase = ref.read(supabaseClientProvider);
        await supabase.from('user_device_tokens').upsert({
          'user_id': userId,
          'fcm_token': newToken,
        });
      });
    } catch (e) {
      developer.log('Error syncing FCM token: $e', name: 'AuthController');
    }
  }
}
