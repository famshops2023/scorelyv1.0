import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<UserProfile> {
  late ProfileService _service;

  @override
  UserProfile build() {
    _service = ref.watch(profileServiceProvider);
    _loadProfile();
    return UserProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _service.loadProfile();
    state = profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }
}
