import 'dart:convert';

class UserProfile {
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

  UserProfile({
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
  });

  Map<String, dynamic> toMap() {
    return {
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
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
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
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));

  UserProfile copyWith({
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
  }) {
    return UserProfile(
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
    );
  }
}
