import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'scorely_user_profile';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());
  }

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson != null) {
      try {
        return UserProfile.fromJson(profileJson);
      } catch (e) {
        // If JSON parsing fails, return a default profile
        return UserProfile();
      }
    }
    return UserProfile(); // Default empty profile
  }
}
