import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../core/config/insforge_config.dart';

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
    // Wire up global silent token refresh hook
    InsforgeConfig.tokenRefresher = _silentRefreshToken;
    _loadProfile();
    return UserProfile();
  }

  // ─────────────────── Load from local storage ─────────────────────────────

  Future<void> _loadProfile() async {
    final profile = await _service.loadProfile();
    state = profile;

    // Check JWT validity upon app launch
    if (profile.isLoggedIn) {
      if (profile.accessToken?.isNotEmpty ?? false) {
        if (!InsforgeConfig.isTokenExpired(profile.accessToken)) {
          InsforgeConfig.setAuthToken(profile.accessToken);
        } else {
          // Token is expired! Silently refresh using stored 7-day refresh token
          debugPrint('ProfileNotifier: Token expired on app startup, triggering silent refresh...');
          await _silentRefreshToken();
        }
      }
    }
  }

  // ─────────────────── Silent Token Refresh ─────────────────────────────────

  /// Silently refreshes the user's JWT access token using the stored refresh token.
  /// Runs automatically before expired tokens are sent, or upon 401 response.
  Future<String?> _silentRefreshToken() async {
    final rToken = state.refreshToken;
    final cToken = state.csrfToken;

    if (rToken == null || rToken.isEmpty) {
      debugPrint('ProfileNotifier._silentRefreshToken: No refresh token available');
      return null;
    }

    try {
      final res = await _auth.refreshToken(
        refreshToken: rToken,
        csrfToken: cToken ?? '',
      );

      if (res.success && res.profile != null) {
        final renewed = state.copyWith(
          accessToken: res.profile!.accessToken,
          refreshToken: res.profile!.refreshToken ?? rToken,
          csrfToken: res.profile!.csrfToken ?? cToken,
        );
        state = renewed;
        InsforgeConfig.setAuthToken(renewed.accessToken);
        await _service.saveProfile(renewed);
        debugPrint('ProfileNotifier._silentRefreshToken: Token successfully refreshed!');
        return renewed.accessToken;
      } else {
        debugPrint('ProfileNotifier._silentRefreshToken failed: ${res.errorMessage}');
      }
    } catch (e) {
      debugPrint('ProfileNotifier._silentRefreshToken exception: $e');
    }
    return null;
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
      InsforgeConfig.setAuthToken(merged.accessToken);
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
      final remote = await _service.fetchRemoteProfile(result.profile!.id);
      final merged = (remote != null)
          ? remote.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: remote.name.isNotEmpty ? remote.name : result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            )
          : state.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            );
      state = merged;
      InsforgeConfig.setAuthToken(merged.accessToken);
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
      final remote = await _service.fetchRemoteProfile(result.profile!.id);
      final merged = (remote != null)
          ? remote.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: remote.name.isNotEmpty ? remote.name : result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            )
          : state.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            );
      state = merged;
      InsforgeConfig.setAuthToken(merged.accessToken);
      await _service.saveProfile(merged);
      return null;
    }
    return result.errorMessage ?? 'Sign-in failed';
  }

  // ─────────────────── Google Sign In ───────────────────────────────────────

  Future<String?> signInWithGoogle() async {
    final result = await _auth.signInWithGoogle();
    if (result.success && result.profile != null) {
      final remote = await _service.fetchRemoteProfile(result.profile!.id);
      final merged = (remote != null)
          ? remote.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: remote.name.isNotEmpty ? remote.name : result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            )
          : state.copyWith(
              id: result.profile!.id,
              email: result.profile!.email,
              name: result.profile!.name,
              isLoggedIn: true,
              accessToken: result.profile!.accessToken,
              refreshToken: result.profile!.refreshToken,
              csrfToken: result.profile!.csrfToken,
            );
      state = merged;
      InsforgeConfig.setAuthToken(merged.accessToken);
      await _service.saveProfile(merged);
      return null;
    }
    return result.errorMessage ?? 'Google Sign-in failed';
  }

  // ─────────────────── Sign Out ─────────────────────────────────────────────

  Future<void> signOut() async {
    InsforgeConfig.setAuthToken(null); // Revert to anonymous API key
    final cleared = state.copyWith(
      isLoggedIn: false,
      accessToken: '',
      refreshToken: '',
      csrfToken: '',
    );
    state = cleared;
    await _service.saveProfile(cleared);
  }

  // ─────────────────── Delete Account ───────────────────────────────────────

  /// Permanently deletes the remote account and profile, and resets local state.
  Future<void> deleteAccount() async {
    final userId = state.id;
    final token = state.accessToken;

    if (userId.isNotEmpty) {
      // 1. Delete profile from InsForge database
      await _service.deleteRemoteProfile(userId);

      // 2. Delete user account from InsForge auth
      await _auth.deleteAccount(userId: userId, accessToken: token);
    }

    // 3. Clear locally stored user profile
    await _service.clearLocalProfile();

    // 4. Reset in-memory state
    state = UserProfile();
  }

  // ─────────────────── Profile update (existing) ────────────────────────────

  Future<void> updateProfile(UserProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }
}
