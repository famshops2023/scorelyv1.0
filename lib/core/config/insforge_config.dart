import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InsforgeConfig {
  static const String baseUrl = String.fromEnvironment(
    'INSFORGE_BASE_URL',
    defaultValue: 'https://ip53vj9s.ap-southeast.insforge.app',
  );

  static const String apiKey = String.fromEnvironment(
    'INSFORGE_API_KEY',
    defaultValue: 'ik_d23aa9a406864853f254a0722fc1e56b',
  );

  static String get recordsUrl => '$baseUrl/api/database/records';

  /// In-memory JWT for the signed-in user. Set via [setAuthToken] on login,
  /// cleared on sign-out. When present and valid, it is used in preference
  /// to the anonymous API key so that PostgREST evaluates auth.uid() correctly.
  static String? _authToken;

  /// Optional callback to silently refresh an expired JWT.
  /// Registered by ProfileNotifier on initialization.
  static Future<String?> Function()? tokenRefresher;

  /// Call this whenever the user signs in or the token is refreshed.
  /// Pass `null` or empty string to revert to the anonymous API key.
  static void setAuthToken(String? token) {
    _authToken = (token != null && token.isNotEmpty) ? token : null;
  }

  /// Inspects a JWT string and checks if it is expired (or will expire within 60s).
  static bool isTokenExpired([String? token]) {
    final t = token ?? _authToken;
    if (t == null || t.isEmpty) return true;
    try {
      final parts = t.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Treat as expired 60 seconds early to prevent race conditions during transit
      return DateTime.now().isAfter(expiryDate.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return true;
    }
  }

  /// Returns the currently active token.
  /// If the user JWT is known to be expired, falls back to apiKey immediately
  /// to prevent PostgREST 401 "JWT expired" errors.
  static String get activeToken {
    if (_authToken != null && !isTokenExpired(_authToken)) {
      return _authToken!;
    }
    return apiKey;
  }

  /// Ensures the active token is valid before sending a critical authenticated request.
  /// If the token is expired, attempts silent refresh via [tokenRefresher].
  static Future<String> ensureValidToken() async {
    if (_authToken != null && isTokenExpired(_authToken)) {
      if (tokenRefresher != null) {
        try {
          final refreshed = await tokenRefresher!();
          if (refreshed != null && refreshed.isNotEmpty) {
            return refreshed;
          }
        } catch (e) {
          debugPrint('InsforgeConfig.ensureValidToken refresh failed: $e');
        }
      }
    }
    return activeToken;
  }

  /// Default headers — always uses the active valid token.
  static Map<String, String> get headers => {
    'apikey': apiKey,
    'Authorization': 'Bearer $activeToken',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// Build headers with an explicit user token (overrides _authToken).
  static Map<String, String> authHeaders([String? userToken]) {
    final token = (userToken != null && userToken.isNotEmpty)
        ? userToken
        : activeToken;
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }

  /// Anonymous headers — guaranteed to bypass expired user tokens for public reads.
  static Map<String, String> get anonHeaders => {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// Performs a GET request with automatic token refresh and fallback to anon headers
  /// if the user token is expired (401).
  static Future<http.Response> getWithFallback(
    Uri uri, {
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final res = await http.get(uri, headers: {...headers, ...?extraHeaders});
      if (res.statusCode == 401) {
        // Attempt silent refresh first
        if (tokenRefresher != null) {
          final refreshed = await tokenRefresher!();
          if (refreshed != null && refreshed.isNotEmpty) {
            // Retry with refreshed token
            return await http.get(uri, headers: {...headers, ...?extraHeaders});
          }
        }
        // Fallback to anon key so public data still loads
        return await http.get(uri, headers: {...anonHeaders, ...?extraHeaders});
      }
      return res;
    } catch (_) {
      return http.get(uri, headers: {...anonHeaders, ...?extraHeaders});
    }
  }
}
