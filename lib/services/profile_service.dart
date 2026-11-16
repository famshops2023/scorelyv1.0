import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'scorely_user_profile';
  static String get _baseUrl => '${InsforgeConfig.recordsUrl}/profiles';
  static String get _playersUrl => '${InsforgeConfig.recordsUrl}/players';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Save to local device storage & sync with InsForge backend
  Future<void> saveProfile(UserProfile profile) async {
    // 1. Update the global auth token so all subsequent API calls use the user JWT
    if (profile.isLoggedIn && (profile.accessToken?.isNotEmpty ?? false)) {
      InsforgeConfig.setAuthToken(profile.accessToken);
    } else if (!profile.isLoggedIn) {
      InsforgeConfig.setAuthToken(null);
    }

    // 2. Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());

    // 3. Sync to InsForge if user is authenticated with a valid ID
    if (profile.isLoggedIn && profile.id.isNotEmpty) {
      await syncProfileToInsForge(profile);
      // 4. Also upsert the player record in InsForge players table
      await syncPlayerRecordToInsForge(profile);
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

  /// Upserts a player record in the InsForge `players` table for the signed-in user.
  /// The player is identified by `profile_id` (the user's auth UUID).
  /// `team_id` is intentionally left null — the user is a standalone player
  /// until they join or create a team.
  Future<bool> syncPlayerRecordToInsForge(UserProfile profile) async {
    if (profile.id.isEmpty) return false;

    try {
      final playerBody = {
        'profile_id': profile.id,
        'name': profile.name,
        'playing_role': profile.playingRole.isNotEmpty ? profile.playingRole : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try PATCH first — update existing player record for this profile_id
      final patchRes = await http.patch(
        Uri.parse('$_playersUrl?profile_id=eq.${profile.id}'),
        headers: _headers,
        body: jsonEncode(playerBody),
      );

      if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
        try {
          final decoded = jsonDecode(patchRes.body);
          if (decoded is List && decoded.isNotEmpty) {
            debugPrint('ProfileService: player record updated for profile_id=${profile.id}');
            return true;
          }
        } catch (_) {}
      }

      // No existing player row → INSERT a new one
      final postBody = {
        ...playerBody,
        'created_at': DateTime.now().toIso8601String(),
      };
      final postRes = await http.post(
        Uri.parse(_playersUrl),
        headers: _headers,
        body: jsonEncode([postBody]),
      );

      if (postRes.statusCode == 200 || postRes.statusCode == 201) {
        debugPrint('ProfileService: player record created for profile_id=${profile.id}');
        return true;
      } else {
        debugPrint(
            'ProfileService: failed to insert player record: ${postRes.statusCode} ${postRes.body}');
        return false;
      }
    } catch (e) {
      debugPrint('ProfileService.syncPlayerRecordToInsForge error: $e');
      return false;
    }
  }

  /// Fetch remote profile from InsForge by user ID
  Future<UserProfile?> fetchRemoteProfile(String userId,
      {String? accessToken}) async {
    if (userId.isEmpty) return null;
    try {
      final res = await InsforgeConfig.getWithFallback(
        Uri.parse('$_baseUrl?id=eq.$userId'),
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

    // Restore auth token immediately so API calls during remote fetch are authenticated
    if (localProfile.isLoggedIn && (localProfile.accessToken?.isNotEmpty ?? false)) {
      InsforgeConfig.setAuthToken(localProfile.accessToken);
    }

    // If logged in, attempt to fetch fresh profile from InsForge
    if (localProfile.isLoggedIn && localProfile.id.isNotEmpty) {
      try {
        final remoteProfile = await fetchRemoteProfile(localProfile.id);
        if (remoteProfile != null) {
          // Merge local and remote, preserving local access token
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
            accessToken: localProfile.accessToken,
            refreshToken: localProfile.refreshToken,
            csrfToken: localProfile.csrfToken,
          );
          await prefs.setString(_profileKey, merged.toJson());
          return merged;
        }
      } catch (_) {}
    }

    return localProfile;
  }

  /// Delete remote profile record from InsForge database
  Future<bool> deleteRemoteProfile(String userId) async {
    if (userId.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl?id=eq.$userId'),
        headers: _headers,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('ProfileService.deleteRemoteProfile error: $e');
      return false;
    }
  }

  /// Clear locally stored user profile
  Future<void> clearLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (e) {
      debugPrint('ProfileService.clearLocalProfile error: $e');
    }
  }
}
