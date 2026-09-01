import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

/// Result returned by all [AuthService] calls.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserProfile? profile;

  /// When true, the account was created but the user must verify their
  /// email before they can sign in.
  final bool requiresEmailVerification;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.profile,
    this.requiresEmailVerification = false,
  });

  factory AuthResult.ok(UserProfile profile) =>
      AuthResult(success: true, profile: profile);

  factory AuthResult.err(String msg) =>
      AuthResult(success: false, errorMessage: msg);

  factory AuthResult.emailVerificationRequired() => const AuthResult(
        success: true,
        requiresEmailVerification: true,
      );
}

/// Handles all InsForge authentication REST calls.
///
/// Endpoints used:
///   Sign-up : POST /api/auth/users
///   Sign-in : POST /api/auth/sessions
class AuthService {
  static const _host = 'https://ip53vj9s.ap-southeast.insforge.app';
  static const _apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '572509298477-vcub9bom9ac99n4ei77faialgdeijqov.apps.googleusercontent.com',
  );

  static Future<void>? _googleInitialization;

  static const Map<String, String> _headers = {
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  // ─────────────────────────────── SIGN UP ────────────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_host/api/auth/users'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {'name': name},
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Trigger a confirmation email via InsForge
        await _sendVerificationEmail(email);

        // Return a result indicating email verification is required.
        // The user must verify before they can sign in.
        return AuthResult.emailVerificationRequired();
      }

      final msg = body['message'] as String? ?? 'Sign-up failed';
      return AuthResult.err(_humanise(msg));
    } catch (e) {
      debugPrint('AuthService.signUp error: $e');
      return AuthResult.err('Network error — please check your connection.');
    }
  }

  /// Attempts to trigger a verification email via InsForge.
  Future<void> _sendVerificationEmail(String email) async {
    try {
      await http.post(
        Uri.parse('$_host/api/auth/email/send-verification'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
    } catch (e) {
      // Non-critical — InsForge may auto-send on signup anyway
      debugPrint('AuthService._sendVerificationEmail: $e');
    }
  }

  // ─────────────────────────────── VERIFY OTP ─────────────────────────────

  Future<AuthResult> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_host/api/auth/email/verify'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': token,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final userId = body['user']?['id'] as String? ?? '';
        final accessToken = body['accessToken'] as String? ?? body['access_token'] as String? ?? '';
        final displayName =
            body['user']?['user_metadata']?['name'] as String? ?? email.split('@').first;

        final profile = UserProfile(
          id: userId,
          email: email,
          name: displayName,
          isLoggedIn: true,
          accessToken: accessToken,
        );
        return AuthResult.ok(profile);
      }

      final msg = body['message'] as String? ?? body['error_description'] as String? ?? 'Invalid or expired code.';
      return AuthResult.err(_humanise(msg));
    } catch (e) {
      debugPrint('AuthService.verifyOTP error: $e');
      return AuthResult.err('Error: $e');
    }
  }

  // ─────────────────────────────── SIGN IN ────────────────────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_host/api/auth/sessions'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final userId = body['user']?['id'] as String? ?? '';
        final token = body['accessToken'] as String? ?? '';
        final displayName =
            body['user']?['user_metadata']?['name'] as String? ?? email.split('@').first;

        final profile = UserProfile(
          id: userId,
          email: email,
          name: displayName,
          isLoggedIn: true,
          accessToken: token,
        );
        return AuthResult.ok(profile);
      }

      final msg = body['message'] as String? ?? 'Sign-in failed';
      return AuthResult.err(_humanise(msg));
    } catch (e) {
      debugPrint('AuthService.signIn error: $e');
      return AuthResult.err('Network error — please check your connection.');
    }
  }

  // ─────────────────────────────── GOOGLE SIGN IN ─────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      if (_googleServerClientId.isEmpty) {
        return AuthResult.err(
          'Google Sign-in is not configured. Start the app with '
          '--dart-define=GOOGLE_SERVER_CLIENT_ID=<your Web OAuth client ID>.',
        );
      }

      // The Web OAuth client ID is required so Android returns an ID token
      // whose audience can be verified by InsForge.
      final googleSignIn = GoogleSignIn.instance;
      _googleInitialization ??= googleSignIn.initialize(
        serverClientId: _googleServerClientId,
      );
      await _googleInitialization;

      final googleUser = await googleSignIn.authenticate();

      // 2. Get the ID token from Google
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return AuthResult.err('Failed to get Google credentials.');
      }

      // Exchange the native Google credential for an InsForge session.
      final res = await http.post(
        Uri.parse('$_host/api/auth/id-token'),
        headers: _headers,
        body: jsonEncode({
          'provider': 'google',
          'token': idToken,
        }),
      );

      Map<String, dynamic> body = {};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (e) {
        debugPrint('AuthService JSON decode error: $e. Body: ${res.body}');
        final errorText = res.body.length > 50 ? '${res.body.substring(0, 50)}...' : res.body;
        return AuthResult.err('Server error: $errorText');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        final userId = body['user']?['id'] as String? ?? '';
        final token = body['accessToken'] as String? ?? '';
        final displayName = googleUser.displayName ?? googleUser.email.split('@').first;

        final profile = UserProfile(
          id: userId,
          email: googleUser.email,
          name: displayName,
          isLoggedIn: true,
          accessToken: token,
        );
        return AuthResult.ok(profile);
      }

      final message = body['message'] as String? ??
          body['error_description'] as String? ??
          'InsForge could not complete Google Sign-in.';
      return AuthResult.err(_humanise(message));
    } on GoogleSignInException catch (e) {
      debugPrint('AuthService.signInWithGoogle Google error: $e');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return AuthResult.err('Google Sign-in was cancelled.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return AuthResult.err(
          'Google Sign-in configuration is incomplete. Check the package '
          'name, SHA-1 fingerprint, and Web OAuth client ID.',
        );
      }
      return AuthResult.err(
        e.description ?? 'Google Sign-in failed. Please try again.',
      );
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      if (e.toString().contains('28444') || e.toString().contains('developer console is not set up correctly')) {
         return AuthResult.err(
          'Google Sign-in configuration is incomplete. Check the package '
          'name, SHA-1 fingerprint, and Web OAuth client ID.',
        );
      }
      return AuthResult.err('Google Sign-in failed: $e');
    }
  }

  // ─────────────────────────────── HELPERS ────────────────────────────────

  String _humanise(String raw) {
    const map = {
      'EMAIL_ALREADY_EXISTS': 'An account with this email already exists.',
      'INVALID_CREDENTIALS': 'Incorrect email or password.',
      'EMAIL_VERIFICATION_REQUIRED': 'Please verify your email before signing in.',
      'EMAIL_NOT_CONFIRMED': 'Please verify your email first. Check your inbox.',
    };
    for (final entry in map.entries) {
      if (raw.toUpperCase().contains(entry.key)) return entry.value;
    }
    return raw;
  }
}
