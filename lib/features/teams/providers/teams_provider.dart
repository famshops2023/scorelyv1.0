import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ============================================================
// INSFORGE CONFIG
// ============================================================
class _InsForge {
  static const baseUrl =
      'https://ip53vj9s.ap-southeast.insforge.app/api/database/records';
  static const apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';
  static const headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}

// ============================================================
// MODELS
// ============================================================
class TeamMember {
  final String id;
  final String name;
  final List<String> roles; // 'BAT', 'BOWL', 'AR', 'WK'
  final bool isAdmin;
  final bool isCaptain;
  final String? profileImageUrl;

  TeamMember({
    required this.id,
    required this.name,
    required this.roles,
    this.isAdmin = false,
    this.isCaptain = false,
    this.profileImageUrl,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isAdmin: json['is_admin'] as bool? ?? false,
      isCaptain: json['is_captain'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'roles': roles,
        'is_admin': isAdmin,
        'is_captain': isCaptain,
        'profile_image_url': profileImageUrl,
      };

  TeamMember copyWith({
    String? id,
    String? name,
    List<String>? roles,
    bool? isAdmin,
    bool? isCaptain,
    String? profileImageUrl,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      isAdmin: isAdmin ?? this.isAdmin,
      isCaptain: isCaptain ?? this.isCaptain,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class TeamData {
  final String id;
  final String teamCode;
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

  factory TeamData.fromJson(Map<String, dynamic> json,
      {List<TeamMember>? members}) {
    final city = json['city'] as String? ?? '';
    final state = json['state'] as String? ?? '';
    final location =
        [city, state].where((s) => s.isNotEmpty).join(', ');

    return TeamData(
      id: json['id']?.toString() ?? '',
      teamCode: json['team_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: location,
      logoUrl: json['logo_url'] as String?,
      dateActive: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      members: members ?? [],
    );
  }

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

// ============================================================
// CURRENT USER PROVIDER  (hardcoded until auth is added)
// ============================================================
final currentUserIdProvider = Provider<String>((ref) => 'u1');

// ============================================================
// TEAMS NOTIFIER — fully synced with InsForge
// ============================================================
class TeamsNotifier extends AsyncNotifier<List<TeamData>> {
  @override
  Future<List<TeamData>> build() async {
    return _fetchAll();
  }

  Future<List<TeamData>> _fetchAll() async {
    try {
      // 1. Fetch teams
      final teamsRes = await http.get(
        Uri.parse('${_InsForge.baseUrl}/teams?select=*&order=created_at.desc'),
        headers: _InsForge.headers,
      );
      if (teamsRes.statusCode != 200) return [];
      final teamsJson = jsonDecode(teamsRes.body) as List;

      // 2. Fetch all players
      final playersRes = await http.get(
        Uri.parse('${_InsForge.baseUrl}/players?select=*'),
        headers: _InsForge.headers,
      );
      final playersJson =
          playersRes.statusCode == 200 ? jsonDecode(playersRes.body) as List : [];

      // 3. Group players by team_id
      final Map<String, List<TeamMember>> membersByTeam = {};
      for (final p in playersJson) {
        final teamId = p['team_id']?.toString() ?? '';
        membersByTeam.putIfAbsent(teamId, () => []);
        membersByTeam[teamId]!.add(TeamMember.fromJson(p));
      }

      // 4. Assemble TeamData objects
      return teamsJson.map((t) {
        final id = t['id']?.toString() ?? '';
        return TeamData.fromJson(t, members: membersByTeam[id] ?? []);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ---- ADD TEAM ----
  Future<TeamData?> addTeam(TeamData team) async {
    try {
      final location = team.location.split(',');
      final city = location.isNotEmpty ? location[0].trim() : team.location;
      final statePart =
          location.length > 1 ? location[1].trim() : '';

      final body = jsonEncode({
        'name': team.name,
        'city': city,
        'state': statePart,
        'logo_url': team.logoUrl,
      });

      final res = await http.post(
        Uri.parse('${_InsForge.baseUrl}/teams'),
        headers: _InsForge.headers,
        body: body,
      );

      if (res.statusCode != 201 && res.statusCode != 200) return null;

      final created = (jsonDecode(res.body) as List).first;
      final teamId = created['id']?.toString() ?? '';

      // Insert members
      List<TeamMember> insertedMembers = [];
      for (final m in team.members) {
        final memberRes = await _insertPlayer(m, teamId);
        if (memberRes != null) insertedMembers.add(memberRes);
      }

      final newTeam =
          TeamData.fromJson(created, members: insertedMembers);
      state = AsyncData([...state.value ?? [], newTeam]);
      return newTeam;
    } catch (e) {
      return null;
    }
  }

  // ---- UPDATE TEAM ----
  Future<void> updateTeam(TeamData updatedTeam) async {
    try {
      final location = updatedTeam.location.split(',');
      final city = location.isNotEmpty ? location[0].trim() : updatedTeam.location;
      final statePart = location.length > 1 ? location[1].trim() : '';

      await http.patch(
        Uri.parse('${_InsForge.baseUrl}/teams?id=eq.${updatedTeam.id}'),
        headers: _InsForge.headers,
        body: jsonEncode({
          'name': updatedTeam.name,
          'city': city,
          'state': statePart,
          'logo_url': updatedTeam.logoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      state = AsyncData([
        for (final t in state.value ?? [])
          if (t.id == updatedTeam.id) updatedTeam else t
      ]);
    } catch (e) {
      // keep local state on failure
    }
  }

  // ---- REMOVE TEAM ----
  Future<void> removeTeam(String id) async {
    try {
      await http.delete(
        Uri.parse('${_InsForge.baseUrl}/teams?id=eq.$id'),
        headers: _InsForge.headers,
      );
      state = AsyncData(
          (state.value ?? []).where((t) => t.id != id).toList());
    } catch (e) {
      // keep local state on failure
    }
  }

  // ---- ADD MEMBER TO TEAM ----
  Future<TeamMember?> addMember(String teamId, TeamMember member) async {
    final inserted = await _insertPlayer(member, teamId);
    if (inserted == null) return null;

    state = AsyncData([
      for (final t in state.value ?? [])
        if (t.id == teamId)
          t.copyWith(members: [...t.members, inserted])
        else
          t
    ]);
    return inserted;
  }

  // ---- UPDATE MEMBER ----
  Future<void> updateMember(
      String teamId, String memberId, TeamMember updated) async {
    try {
      await http.patch(
        Uri.parse('${_InsForge.baseUrl}/players?id=eq.$memberId'),
        headers: _InsForge.headers,
        body: jsonEncode({
          'name': updated.name,
          'roles': updated.roles,
          'is_admin': updated.isAdmin,
          'is_captain': updated.isCaptain,
          'profile_image_url': updated.profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      state = AsyncData([
        for (final t in state.value ?? [])
          if (t.id == teamId)
            t.copyWith(
              members: [
                for (final m in t.members)
                  if (m.id == memberId) updated else m
              ],
            )
          else
            t
      ]);
    } catch (e) {
      // keep local state on failure
    }
  }

  // ---- REMOVE MEMBER ----
  Future<void> removeMember(String teamId, String memberId) async {
    try {
      await http.delete(
        Uri.parse('${_InsForge.baseUrl}/players?id=eq.$memberId'),
        headers: _InsForge.headers,
      );

      state = AsyncData([
        for (final t in state.value ?? [])
          if (t.id == teamId)
            t.copyWith(
                members: t.members.where((m) => m.id != memberId).toList())
          else
            t
      ]);
    } catch (e) {
      // keep local state on failure
    }
  }

  // ---- REFRESH ----
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchAll());
  }

  // ---- PRIVATE: insert a player row ----
  Future<TeamMember?> _insertPlayer(TeamMember m, String teamId) async {
    try {
      final res = await http.post(
        Uri.parse('${_InsForge.baseUrl}/players'),
        headers: _InsForge.headers,
        body: jsonEncode({
          'team_id': teamId,
          'name': m.name,
          'roles': m.roles,
          'is_admin': m.isAdmin,
          'is_captain': m.isCaptain,
          'profile_image_url': m.profileImageUrl,
        }),
      );
      if (res.statusCode != 201 && res.statusCode != 200) return null;
      final created = (jsonDecode(res.body) as List).first;
      return TeamMember.fromJson(created);
    } catch (e) {
      return null;
    }
  }
}

final teamsProvider =
    AsyncNotifierProvider<TeamsNotifier, List<TeamData>>(TeamsNotifier.new);

// Helper: teams where current user is a member
final myTeamsProvider = Provider<List<TeamData>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final teamsAsync = ref.watch(teamsProvider);
  return teamsAsync.value
          ?.where((t) => t.members.any((m) => m.id == currentUserId))
          .toList() ??
      [];
});
