import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'scorely_user_profile';
  static String get _baseUrl => '${InsforgeConfig.recordsUrl}/profiles';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Save to local device storage & sync with InsForge backend
  Future<void> saveProfile(UserProfile profile) async {
    // 1. Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());

    // 2. Sync to InsForge if user is authenticated with a valid ID
    if (profile.isLoggedIn && profile.id.isNotEmpty) {
      await syncProfileToInsForge(profile);
    }
  }

  /// Syncs user profile details to InsForge `profiles` table
  Future<bool> syncProfileToInsForge(UserProfile profile) async {
    if (profile.id.isEmpty) return false;

    try {
      final bodyMap = profile.toInsForgeMap();

      // First try to PATCH (update existing profile record)
      final patchRes = await http.patch(
        Uri.parse('$_baseUrl?id=eq.${profile.id}'),
        headers: _headers,
        body: jsonEncode(bodyMap),
      );

      // If PATCH updated 1 or more rows
      if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
        final decoded = jsonDecode(patchRes.body);
        if (decoded is List && decoded.isNotEmpty) {
          return true;
        }
      }

      // If record didn't exist yet, INSERT (POST) the profile record
      final postRes = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode([bodyMap]),
      );

      if (postRes.statusCode == 200 || postRes.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to insert profile to InsForge: ${postRes.statusCode} ${postRes.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing profile to InsForge: $e');
      return false;
    }
  }

  /// Fetch remote profile from InsForge by user ID
  Future<UserProfile?> fetchRemoteProfile(String userId,
      {String? accessToken}) async {
    if (userId.isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl?id=eq.$userId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          return UserProfile.fromInsForgeMap(
            decoded.first as Map<String, dynamic>,
            accessToken: accessToken,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching remote profile: $e');
    }
    return null;
  }

  /// Load profile from local storage and optionally refresh from remote
  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    UserProfile localProfile = UserProfile();

    if (profileJson != null) {
      try {
        localProfile = UserProfile.fromJson(profileJson);
      } catch (e) {
        localProfile = UserProfile();
      }
    }

    // If logged in, attempt to fetch fresh profile from InsForge
    if (localProfile.isLoggedIn && localProfile.id.isNotEmpty) {
      try {
        final remoteProfile = await fetchRemoteProfile(localProfile.id);
        if (remoteProfile != null) {
          // Merge local and remote
          final merged = localProfile.copyWith(
            name: remoteProfile.name.isNotEmpty
                ? remoteProfile.name
                : localProfile.name,
            role: remoteProfile.role.isNotEmpty
                ? remoteProfile.role
                : localProfile.role,
            location: remoteProfile.location.isNotEmpty
                ? remoteProfile.location
                : localProfile.location,
            association: remoteProfile.association.isNotEmpty
                ? remoteProfile.association
                : localProfile.association,
            dateOfBirth: remoteProfile.dateOfBirth.isNotEmpty
                ? remoteProfile.dateOfBirth
                : localProfile.dateOfBirth,
            mobile: remoteProfile.mobile.isNotEmpty
                ? remoteProfile.mobile
                : localProfile.mobile,
            playingRole: remoteProfile.playingRole.isNotEmpty
                ? remoteProfile.playingRole
                : localProfile.playingRole,
            battingStyle: remoteProfile.battingStyle.isNotEmpty
                ? remoteProfile.battingStyle
                : localProfile.battingStyle,
            bowlingStyle: remoteProfile.bowlingStyle.isNotEmpty
                ? remoteProfile.bowlingStyle
                : localProfile.bowlingStyle,
            gender: remoteProfile.gender.isNotEmpty
                ? remoteProfile.gender
                : localProfile.gender,
            profileImagePath: remoteProfile.profileImagePath ??
                localProfile.profileImagePath,
          );
          await prefs.setString(_profileKey, merged.toJson());
          return merged;
        }
      } catch (_) {}
    }

    return localProfile;
  }
}
