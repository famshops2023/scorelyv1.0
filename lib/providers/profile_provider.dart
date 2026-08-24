import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());
final authServiceProvider = Provider((ref) => AuthService());

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<UserProfile> {
  late ProfileService _service;
  late AuthService _auth;

  @override
  UserProfile build() {
    _service = ref.watch(profileServiceProvider);
    _auth = ref.watch(authServiceProvider);
    _loadProfile();
    return UserProfile();
  }

  // ─────────────────── Load from local storage ─────────────────────────────

  Future<void> _loadProfile() async {
    final profile = await _service.loadProfile();
    state = profile;
  }

  // ─────────────────── Sign Up ──────────────────────────────────────────────

  /// Returns `null` on success, an error string on failure, or the special
  /// string `'EMAIL_VERIFICATION_SENT'` when the account was created but
  /// needs email verification before the user can sign in.
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _auth.signUp(email: email, password: password, name: name);

    if (result.requiresEmailVerification) {
      // Account created — email verification pending
      return 'EMAIL_VERIFICATION_SENT';
    }

    if (result.success && result.profile != null) {
      // Merge auth data with any existing local profile data
      final merged = state.copyWith(
        id: result.profile!.id,
        email: result.profile!.email,
        name: name.isNotEmpty ? name : state.name,
        isLoggedIn: true,
        accessToken: result.profile!.accessToken,
      );
      state = merged;
      await _service.saveProfile(merged);
      return null; // null = success
    }
    return result.errorMessage ?? 'Sign-up failed';
  }

  // ─────────────────── Verify OTP ───────────────────────────────────────────

  Future<String?> verifyOTP({
    required String email,
    required String token,
  }) async {
    final result = await _auth.verifyOTP(email: email, token: token);
    if (result.success && result.profile != null) {
      final merged = state.copyWith(
        id: result.profile!.id,
        email: result.profile!.email,
        name: result.profile!.name,
        isLoggedIn: true,
        accessToken: result.profile!.accessToken,
      );
      state = merged;
      await _service.saveProfile(merged);
      return null;
    }
    return result.errorMessage ?? 'Invalid verification code.';
  }

  // ─────────────────── Sign In ──────────────────────────────────────────────

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signIn(email: email, password: password);
    if (result.success && result.profile != null) {
      final merged = state.copyWith(
        id: result.profile!.id,
        email: result.profile!.email,
        name: result.profile!.name,
        isLoggedIn: true,
        accessToken: result.profile!.accessToken,
      );
      state = merged;
      await _service.saveProfile(merged);
      return null;
    }
    return result.errorMessage ?? 'Sign-in failed';
  }

  // ─────────────────── Google Sign In ───────────────────────────────────────

  Future<String?> signInWithGoogle() async {
    final result = await _auth.signInWithGoogle();
    if (result.success && result.profile != null) {
      final merged = state.copyWith(
        id: result.profile!.id,
        email: result.profile!.email,
        name: result.profile!.name,
        isLoggedIn: true,
        accessToken: result.profile!.accessToken,
      );
      state = merged;
      await _service.saveProfile(merged);
      return null;
    }
    return result.errorMessage ?? 'Google Sign-in failed';
  }

  // ─────────────────── Sign Out ─────────────────────────────────────────────

  Future<void> signOut() async {
    final cleared = state.copyWith(
      isLoggedIn: false,
      accessToken: '',
    );
    state = cleared;
    await _service.saveProfile(cleared);
  }

  // ─────────────────── Profile update (existing) ────────────────────────────

  Future<void> updateProfile(UserProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }
}
