import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../teams/providers/teams_provider.dart';

class DiscoveryItem {
  final String id;        // Human-readable code (team_code or display ID)
  final String rawId;     // Actual database UUID for navigation
  final String name;
  final String type; // 'team', 'player', 'tournament'
  final String location;
  final String? role;

  DiscoveryItem({
    required this.id,
    String? rawId,
    required this.name,
    required this.type,
    required this.location,
    this.role,
  }) : rawId = rawId ?? id;
}

class DiscoveryScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const DiscoveryScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'All';

  final List<String> _tabs = ['All', 'Teams', 'Players', 'Tournaments'];

  bool _isLoading = true;
  List<DiscoveryItem> _fetchedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.isSelectionMode) {
      _selectedTab = 'Teams';
    }
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    const baseUrl = 'https://ip53vj9s.ap-southeast.insforge.app/api/database/records';
    const headers = {
      'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
      'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
    };

    List<DiscoveryItem> items = [];

    try {
      // 1. Fetch teams from backend database
      final teamsRes = await http.get(
        Uri.parse('$baseUrl/teams?select=*&order=created_at.desc'),
        headers: headers,
      );
      if (teamsRes.statusCode == 200) {
        final List<dynamic> data = json.decode(teamsRes.body);
        for (var t in data) {
          final city = t['city'] as String? ?? '';
          final state = t['state'] as String? ?? '';
          final location = [city, state].where((s) => s.isNotEmpty).join(', ');
          final rawId = t['id']?.toString() ?? '';
          final code = t['team_code']?.toString();
          final displayId = (code != null && code.isNotEmpty)
              ? code
              : (rawId.length >= 8 ? 'SCR-${rawId.substring(0, 4).toUpperCase()}' : rawId);

          items.add(DiscoveryItem(
            id: displayId,
            rawId: rawId,
            name: t['name'] ?? 'Unknown Team',
            type: 'team',
            location: location.isNotEmpty ? location : 'Unknown Location',
          ));
        }
      }

      // 2. Fetch players from backend database
      final playersRes = await http.get(
        Uri.parse('$baseUrl/players?select=*'),
        headers: headers,
      );
      if (playersRes.statusCode == 200) {
        final List<dynamic> data = json.decode(playersRes.body);
        for (var p in data) {
          final rawId = p['id']?.toString() ?? '';
          final rolesList = (p['roles'] as List?)?.map((e) => e.toString()).join('/') ?? '';
          final roleStr = rolesList.isNotEmpty
              ? rolesList
              : (p['attribute'] as String? ?? p['role'] as String? ?? 'Cricketer');

          items.add(DiscoveryItem(
            id: rawId.length >= 8 ? 'P-${rawId.substring(0, 4).toUpperCase()}' : rawId,
            rawId: rawId,
            name: p['name'] ?? 'Unknown Player',
            type: 'player',
            role: roleStr,
            location: p['location'] as String? ?? 'India',
          ));
        }
      }
    } catch (_) {
      // Network or API error — handle gracefully
    }

    if (mounted) {
      setState(() {
        _fetchedItems = items;
        _isLoading = false;
      });
    }
  }

  /// Combines static backend items with real-time dynamic items from Riverpod `teamsProvider`
  List<DiscoveryItem> _getAllItems() {
    final Map<String, DiscoveryItem> combinedMap = {};

    // 1. Add Riverpod local / dynamic teams first
    final stateTeams = ref.watch(teamsProvider).value ?? [];
    for (final t in stateTeams) {
      final code = t.teamCode.isNotEmpty
          ? t.teamCode
          : (t.id.length >= 8 ? 'SCR-${t.id.substring(0, 4).toUpperCase()}' : t.id);

      combinedMap[t.id] = DiscoveryItem(
        id: code,
        rawId: t.id,
        name: t.name,
        type: 'team',
        location: t.location.isNotEmpty ? t.location : 'Unknown Location',
      );
    }

    // 2. Add fetched remote items (without overwriting if already in Riverpod state)
    for (final item in _fetchedItems) {
      if (!combinedMap.containsKey(item.rawId)) {
        combinedMap[item.rawId] = item;
      }
    }

    return combinedMap.values.toList();
  }

  List<DiscoveryItem> get _filteredItems {
    final allItems = _getAllItems();

    return allItems.where((item) {
      // Tab filter
      if (!widget.isSelectionMode) {
        if (_selectedTab == 'Teams' && item.type != 'team') return false;
        if (_selectedTab == 'Players' && item.type != 'player') return false;
        if (_selectedTab == 'Tournaments' && item.type != 'tournament') return false;
      } else {
        // Selection mode always forces 'team' type
        if (item.type != 'team') return false;
      }

      // Search query filter (name, id, location, or player attribute)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = item.name.toLowerCase().contains(query);
        final matchId = item.id.toLowerCase().contains(query);
        final matchRawId = item.rawId.toLowerCase().contains(query);
        final matchLocation = item.location.toLowerCase().contains(query);
        final matchRole = (item.role ?? '').toLowerCase().contains(query);
        if (!matchName && !matchId && !matchRawId && !matchLocation && !matchRole) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFF111317), // surface
      appBar: AppBar(
        backgroundColor: const Color(0xFF111317),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isSelectionMode ? 'Select Team' : 'Discovery',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e2024), // surface-container
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333539)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search teams, players, or IDs...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFbcc7de)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFbcc7de)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFFbcc7de), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Filter Tabs (only if not in selection mode)
          if (!widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) => _buildTab(tab)).toList(),
                ),
              ),
            ),

          if (!widget.isSelectionMode) const SizedBox(height: 16),

          // List with Pull-To-Refresh
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFBA0013)))
                : RefreshIndicator(
                    color: const Color(0xFFBA0013),
                    backgroundColor: const Color(0xFF1e2024),
                    onRefresh: () async {
                      await ref.read(teamsProvider.notifier).refresh();
                      await _fetchData();
                    },
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.search_off_rounded,
                                      size: 56,
                                      color: Color(0xFF5A6278),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No results found',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try searching for another team, player, or ID',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF5A6278),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildItemCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF1a1c20),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFFe2e2e8),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(DiscoveryItem item) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          context.pop(item.name);
        } else {
          if (item.type == 'team') {
            // Use rawId (UUID) for team-squad navigation
            context.push('/team-squad', extra: {
              'teamId': item.rawId,
              'readOnly': true,
            });
          } else if (item.type == 'player') {
            context.push('/profile');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1e2024),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333539)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF111317),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333539)),
              ),
              child: Center(
                child: item.type == 'team'
                    ? const Icon(Icons.shield, color: Color(0xFFBA0013), size: 32)
                    : const Icon(Icons.person, color: Color(0xFFbcc7de), size: 32),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '#${item.id}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFbcc7de),
                        ),
                      ),
                      if (item.role != null) ...[
                        Text(
                          ' • ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFbcc7de),
                          ),
                        ),
                        Text(
                          item.role!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3ce36a), // Tertiary Green
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFFbcc7de), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.location,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFbcc7de),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
