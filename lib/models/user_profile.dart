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
  String? accessToken; // InsForge JWT token (not persisted to prefs)

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
  });

  /// Returns a short, human-readable ID like SCR-1042.
  /// Derived deterministically from the raw UUID so it is always consistent.
  String get displayId {
    if (id.isEmpty) return 'SCR-0000';
    // Use the last 4 hex chars of the UUID → integer → 4-digit number
    final hex = id.replaceAll('-', '');
    final tail = hex.length >= 4 ? hex.substring(hex.length - 4) : hex.padLeft(4, '0');
    final num = int.tryParse(tail, radix: 16) ?? 0;
    return 'SCR-${(num % 9000 + 1000)}';
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
      // accessToken is intentionally NOT persisted
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
    );
  }
}
