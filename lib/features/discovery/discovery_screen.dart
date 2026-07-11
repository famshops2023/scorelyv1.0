import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DiscoveryItem {
  final String id;
  final String name;
  final String type; // 'team', 'player', 'tournament'
  final String location;
  final String? role;

  DiscoveryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.role,
  });
}

class DiscoveryScreen extends StatefulWidget {
  final bool isSelectionMode;

  const DiscoveryScreen({super.key, this.isSelectionMode = false});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'All';

  final List<String> _tabs = ['All', 'Teams', 'Players', 'Tournaments'];

  bool _isLoading = true;
  List<DiscoveryItem> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.isSelectionMode) {
      _selectedTab = 'Teams';
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final url = 'https://ip53vj9s.ap-southeast.insforge.app/rest/v1/';
    final headers = {
      'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
      'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
    };

    List<DiscoveryItem> fetchedItems = [];

    try {
      // Try fetching teams
      final teamsRes = await http.get(Uri.parse('${url}teams?select=*'), headers: headers);
      if (teamsRes.statusCode == 200) {
        final List<dynamic> data = json.decode(teamsRes.body);
        for (var t in data) {
          fetchedItems.add(DiscoveryItem(
            id: t['id']?.toString() ?? '',
            name: t['name'] ?? 'Unknown Team',
            type: 'team',
            location: t['location'] ?? 'Unknown Location',
          ));
        }
      } else {
        throw Exception('Failed to load teams');
      }

      // Try fetching players
      final playersRes = await http.get(Uri.parse('${url}players?select=*'), headers: headers);
      if (playersRes.statusCode == 200) {
        final List<dynamic> data = json.decode(playersRes.body);
        for (var p in data) {
          fetchedItems.add(DiscoveryItem(
            id: p['id']?.toString() ?? '',
            name: p['name'] ?? 'Unknown Player',
            type: 'player',
            role: p['attribute'] ?? p['role'] ?? 'Unknown Role', // Added player attribute
            location: p['location'] ?? 'Unknown Location',
          ));
        }
      } else {
        throw Exception('Failed to load players');
      }
    } catch (e) {
      // Fallback dummy data if API fails or endpoints don't exist yet
      fetchedItems = [
        DiscoveryItem(id: 'TS-4421', name: 'Thunder Strikers', type: 'team', location: 'Mumbai, India'),
        DiscoveryItem(id: 'AK-998', name: 'Arjun K.', type: 'player', role: 'All-rounder', location: 'Chennai, India'),
        DiscoveryItem(id: 'RT-1102', name: 'Royal Titans', type: 'team', location: 'London, UK'),
        DiscoveryItem(id: 'SJ-452', name: 'Sarah J.', type: 'player', role: 'Fast Bowler', location: 'Melbourne, AUS'),
      ];
    }

    if (mounted) {
      setState(() {
        _items = fetchedItems;
        _isLoading = false;
      });
    }
  }

  List<DiscoveryItem> get _filteredItems {
    return _items.where((item) {
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
        final matchLocation = item.location.toLowerCase().contains(query);
        final matchRole = (item.role ?? '').toLowerCase().contains(query);
        if (!matchName && !matchId && !matchLocation && !matchRole) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'Discovery',
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

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF22C33)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildItemCard(item);
                    },
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
          color: isSelected ? const Color(0xFFF22C33) : const Color(0xFF1a1c20),
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
            context.push('/team-squad', extra: item.id);
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
                    ? const Icon(Icons.shield, color: Color(0xFFF22C33), size: 32)
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
