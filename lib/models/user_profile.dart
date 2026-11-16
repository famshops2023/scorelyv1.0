import 'dart:convert';

class UserProfile {
  String id;
  String email;        // InsForge auth email
  String name;
  String role;
  String location;
  String association;
  String dateOfBirth;
  String mobile;
  String playingRole;
  String battingStyle;
  String bowlingStyle;
  String gender;
  String? profileImagePath;
  bool isLoggedIn;     // true once authenticated via InsForge
  String? accessToken; // InsForge JWT token
  String? refreshToken; // InsForge 7-day refresh token from cookie
  String? csrfToken;   // CSRF token required for /api/auth/refresh

  UserProfile({
    this.id = '',
    this.email = '',
    this.name = 'Scorely User',
    this.role = 'Cricket Enthusiast',
    this.location = '',
    this.association = '',
    this.dateOfBirth = '',
    this.mobile = '',
    this.playingRole = 'Batsman',
    this.battingStyle = 'Right Hand',
    this.bowlingStyle = 'Right-arm Fast',
    this.gender = 'Prefer not to say',
    this.profileImagePath,
    this.isLoggedIn = false,
    this.accessToken,
    this.refreshToken,
    this.csrfToken,
  });

  /// Returns a short, human-readable ID like SP-1042 for players.
  /// Derived deterministically from the raw UUID so it is always consistent.
  String get displayId => deriveDisplayId(id);

  /// Helper to deterministically derive player display ID (SP-xxxx) from any UUID or raw ID
  static String deriveDisplayId(String rawId) {
    if (rawId.isEmpty) return 'SP-0000';
    final hex = rawId.replaceAll('-', '');
    final tail = hex.length >= 4 ? hex.substring(hex.length - 4) : hex.padLeft(4, '0');
    final num = int.tryParse(tail, radix: 16) ?? 0;
    return 'SP-${(num % 9000 + 1000)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'location': location,
      'association': association,
      'dateOfBirth': dateOfBirth,
      'mobile': mobile,
      'playingRole': playingRole,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'gender': gender,
      'profileImagePath': profileImagePath,
      'isLoggedIn': isLoggedIn,
      // Persist tokens so authentication and silent refresh work across app restarts
      if (accessToken != null && accessToken!.isNotEmpty) 'accessToken': accessToken,
      if (refreshToken != null && refreshToken!.isNotEmpty) 'refreshToken': refreshToken,
      if (csrfToken != null && csrfToken!.isNotEmpty) 'csrfToken': csrfToken,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Scorely User',
      role: map['role'] ?? 'Cricket Enthusiast',
      location: map['location'] ?? '',
      association: map['association'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      mobile: map['mobile'] ?? '',
      playingRole: map['playingRole'] ?? 'Batsman',
      battingStyle: map['battingStyle'] ?? 'Right Hand',
      bowlingStyle: map['bowlingStyle'] ?? 'Right-arm Fast',
      gender: map['gender'] ?? 'Prefer not to say',
      profileImagePath: map['profileImagePath'],
      isLoggedIn: map['isLoggedIn'] == true,
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      csrfToken: map['csrfToken'] as String?,
    );
  }

  Map<String, dynamic> toInsForgeMap() {
    String? formattedDob;
    if (dateOfBirth.isNotEmpty) {
      try {
        if (dateOfBirth.contains('/')) {
          final parts = dateOfBirth.split('/');
          if (parts.length == 3) {
            if (parts[2].length == 4) {
              // MM/DD/YYYY -> YYYY-MM-DD
              final m = parts[0].padLeft(2, '0');
              final d = parts[1].padLeft(2, '0');
              final y = parts[2];
              formattedDob = '$y-$m-$d';
            } else if (parts[0].length == 4) {
              // YYYY/MM/DD
              formattedDob = '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
            }
          }
        } else {
          final parsed = DateTime.tryParse(dateOfBirth);
          if (parsed != null) {
            formattedDob =
                "${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
          }
        }
      } catch (_) {}
    }

    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (email.isNotEmpty) 'email': email,
      'role': role,
      'location': location,
      'association': association,
      'date_of_birth': formattedDob,
      'mobile': mobile,
      'playing_role': playingRole,
      'batting_style': battingStyle,
      'bowling_style': bowlingStyle,
      'gender': gender,
      'profile_image_url': profileImagePath,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromInsForgeMap(
    Map<String, dynamic> map, {
    String? accessToken,
    String? refreshToken,
    String? csrfToken,
  }) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Scorely User',
      role: map['role']?.toString() ?? 'Cricket Enthusiast',
      location: map['location']?.toString() ?? '',
      association: map['association']?.toString() ?? '',
      dateOfBirth: map['date_of_birth']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      playingRole: map['playing_role']?.toString() ?? 'Batsman',
      battingStyle: map['batting_style']?.toString() ?? 'Right Hand',
      bowlingStyle: map['bowling_style']?.toString() ?? 'Right-arm Fast',
      gender: map['gender']?.toString() ?? 'Prefer not to say',
      profileImagePath: map['profile_image_url'] as String?,
      isLoggedIn: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      csrfToken: csrfToken,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? location,
    String? association,
    String? dateOfBirth,
    String? mobile,
    String? playingRole,
    String? battingStyle,
    String? bowlingStyle,
    String? gender,
    String? profileImagePath,
    bool? isLoggedIn,
    String? accessToken,
    String? refreshToken,
    String? csrfToken,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      association: association ?? this.association,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      mobile: mobile ?? this.mobile,
      playingRole: playingRole ?? this.playingRole,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      csrfToken: csrfToken ?? this.csrfToken,
    );
  }
}
