import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamMember {
  final String id;
  final String name;
  final List<String> roles; // 'BAT', 'BOWL', 'AR', 'WK'
  final bool isAdmin;
  final bool isCaptain;

  TeamMember({
    required this.id,
    required this.name,
    required this.roles,
    this.isAdmin = false,
    this.isCaptain = false,
  });

  TeamMember copyWith({
    String? id,
    String? name,
    List<String>? roles,
    bool? isAdmin,
    bool? isCaptain,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      isAdmin: isAdmin ?? this.isAdmin,
      isCaptain: isCaptain ?? this.isCaptain,
    );
  }
}

class TeamData {
  final String id;
  final String teamCode; // e.g. ST-1111
  final String name;
  final String location;
  final String? logoUrl;
  final DateTime dateActive;
  final List<TeamMember> members;

  TeamData({
    required this.id,
    this.teamCode = '',
    required this.name,
    required this.location,
    this.logoUrl,
    required this.dateActive,
    required this.members,
  });

  TeamData copyWith({
    String? id,
    String? teamCode,
    String? name,
    String? location,
    String? logoUrl,
    DateTime? dateActive,
    List<TeamMember>? members,
  }) {
    return TeamData(
      id: id ?? this.id,
      teamCode: teamCode ?? this.teamCode,
      name: name ?? this.name,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
      dateActive: dateActive ?? this.dateActive,
      members: members ?? this.members,
    );
  }
}

// Current logged in user ID
final currentUserIdProvider = Provider<String>((ref) => 'u1');

class TeamsNotifier extends Notifier<List<TeamData>> {
  @override
  List<TeamData> build() => _initialTeams;

  void addTeam(TeamData team) {
    state = [...state, team];
  }

  void updateTeam(TeamData updatedTeam) {
    state = [
      for (final team in state)
        if (team.id == updatedTeam.id) updatedTeam else team
    ];
  }

  void removeTeam(String id) {
    state = state.where((team) => team.id != id).toList();
  }
}

final teamsProvider = NotifierProvider<TeamsNotifier, List<TeamData>>(
  TeamsNotifier.new,
);

// Helper provider for "My Teams" (where current user is a member)
final myTeamsProvider = Provider<List<TeamData>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final allTeams = ref.watch(teamsProvider);
  return allTeams.where((t) => t.members.any((m) => m.id == currentUserId)).toList();
});

// Dummy initial data
final List<TeamData> _initialTeams = [
  TeamData(
    id: 't1',
    teamCode: 'ST-1111',
    name: 'Storm Riders',
    location: 'Mumbai, Maharashtra',
    logoUrl: 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?q=80&w=2069&auto=format&fit=crop',
    dateActive: DateTime(2024, 3, 12),
    members: [
      TeamMember(id: 'u1', name: 'V. Kohli', roles: ['BAT'], isAdmin: true, isCaptain: true),
      TeamMember(id: 'u2', name: 'MS Dhoni', roles: ['BAT', 'WK'], isAdmin: true, isCaptain: false),
      TeamMember(id: 'u3', name: 'Rohit Sharma', roles: ['BAT'], isAdmin: true, isCaptain: false),
      TeamMember(id: 'u4', name: 'H. Pandya', roles: ['BAT', 'AR', 'BOWL'], isAdmin: false, isCaptain: false),
    ],
  ),
  TeamData(
    id: 't2',
    teamCode: 'ST-1112',
    name: 'Knights United',
    location: 'Mumbai, Maharashtra',
    logoUrl: null,
    dateActive: DateTime(2024, 3, 12),
    members: [
      TeamMember(id: 'u1', name: 'V. Kohli', roles: ['BAT'], isAdmin: true, isCaptain: false),
      TeamMember(id: 'u5', name: 'S. Iyer', roles: ['BAT'], isAdmin: false, isCaptain: true),
    ],
  ),
  TeamData(
    id: 't3',
    teamCode: 'ST-1113',
    name: 'Titans Strikers',
    location: 'Ahmedabad, Gujarat',
    logoUrl: null,
    dateActive: DateTime(2024, 2, 20),
    members: [
      TeamMember(id: 'u6', name: 'S. Gill', roles: ['BAT'], isAdmin: true, isCaptain: true),
    ],
  )
];
