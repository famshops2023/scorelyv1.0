import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'providers/teams_provider.dart';
import '../../providers/profile_provider.dart';
import '../discovery/discovery_screen.dart';

class EditSquadScreen extends ConsumerStatefulWidget {
  final String teamId;

  const EditSquadScreen({super.key, required this.teamId});

  @override
  ConsumerState<EditSquadScreen> createState() => _EditSquadScreenState();
}

class _EditSquadScreenState extends ConsumerState<EditSquadScreen> {
  TeamData _team = TeamData(
    id: '',
    name: '',
    location: '',
    dateActive: DateTime.now(),
    members: [],
  );
  bool _isLoading = true;
  String? _localLogoPath;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teams = ref.read(teamsProvider).value ?? [];
      final team = teams.firstWhere(
        (t) => t.id == widget.teamId,
        orElse: () => _team,
      );
      setState(() {
        _team = team;
        _teamNameController.text = team.name;

        final locParts = team.location.split(', ');
        _cityController.text = locParts.isNotEmpty ? locParts[0] : '';
        _stateController.text = locParts.length > 1 ? locParts[1] : '';
        _countryController.text = 'India';
        _isLoading = false;
      });
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _localLogoPath = picked.path;
      });
    }
  }

  /// Generates the deep-link invite URL for this team.
  String _buildInviteLink() {
    final code = _team.teamCode.isNotEmpty ? _team.teamCode : _team.id;
    final name = _teamNameController.text.trim().isNotEmpty
        ? _teamNameController.text.trim()
        : _team.name;
    final encodedName = Uri.encodeComponent(name);
    return 'scorely://join?team=$code${encodedName.isNotEmpty ? '&name=$encodedName' : ''}';
  }

  /// Copies [text] to clipboard and shows a SnackBar.
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invite link copied!',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF191C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows the invite bottom sheet with QR code and share options.
  void _showInviteSheet() {
    if (!_validateMandatoryFields(actionName: 'inviting players')) return;
    final link = _buildInviteLink();
    final displayTeamName = _teamNameController.text.trim().isNotEmpty
        ? _teamNameController.text.trim()
        : _team.name;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Invite Players to Join',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF191C1E),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share the link or scan the QR code below',
                style: GoogleFonts.inter(
                  color: const Color(0xFF8E95A5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E3E6)),
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.transparent,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF191C1E),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Link row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E3E6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF575D78),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyToClipboard(link),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEEF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Color(0xFF575D78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Share via WhatsApp button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final whatsappMsg = Uri.encodeComponent(
                      'Join my cricket team on Scorely! Tap the link to join:\n$link',
                    );
                    final whatsappUrl = 'https://wa.me/?text=$whatsappMsg';
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Join my cricket team *$displayTeamName* on Scorely! Tap to join:\n$link',
                        subject: 'Join $displayTeamName on Scorely',
                        uri: Uri.parse(whatsappUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                  label: Text(
                    'Share via WhatsApp',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Generic share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Join my cricket team *$displayTeamName* on Scorely! Tap to join:\n$link',
                        subject: 'Join $displayTeamName on Scorely',
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.share,
                    size: 18,
                    color: Color(0xFF191C1E),
                  ),
                  label: Text(
                    'Share via Other Apps',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF191C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E3E6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showValidationPopup({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFBA0013), width: 5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDEBED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFBA0013),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF575D78),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA0013),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'OK, GOT IT',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateMandatoryFields({required String actionName}) {
    final name = _teamNameController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    final List<String> missing = [];
    if (name.isEmpty) missing.add('Team Name');
    if (city.isEmpty) missing.add('City');
    if (state.isEmpty) missing.add('State');

    if (missing.isNotEmpty) {
      final String missingStr;
      if (missing.length == 1) {
        missingStr = missing.first;
      } else if (missing.length == 2) {
        missingStr = '${missing[0]} & ${missing[1]}';
      } else {
        missingStr = '${missing[0]}, ${missing[1]} & ${missing[2]}';
      }

      _showValidationPopup(
        title: 'Enter Team Details',
        message: 'Please enter $missingStr before $actionName.',
      );
      return false;
    }
    return true;
  }

  void _saveChanges() {
    if (!_validateMandatoryFields(actionName: 'saving team details')) return;
    final name = _teamNameController.text.trim();
    final location =
        '${_cityController.text.trim()}, ${_stateController.text.trim()}';

    if (_team.id.isEmpty) {
      // New team — add with the logged-in user as admin creator
      final profile = ref.read(profileProvider);
      final creatorId = profile.id;
      final creatorName = profile.name.isNotEmpty ? profile.name : 'Me';
      final newTeam = _team.copyWith(
        name: name,
        location: location,
        createdBy: creatorId.isNotEmpty ? creatorId : null,
      );
      ref
          .read(teamsProvider.notifier)
          .addTeam(
            newTeam,
            creatorId: creatorId.isNotEmpty ? creatorId : null,
            creatorName: creatorName,
          );
    } else {
      // Existing team — update it
      final profile = ref.read(profileProvider);
      final creatorId = profile.id;
      final ownerId = (_team.createdBy != null && _team.createdBy!.isNotEmpty)
          ? _team.createdBy
          : (creatorId.isNotEmpty ? creatorId : null);
      final updatedTeam = _team.copyWith(
        name: name,
        location: location,
        createdBy: ownerId,
      );
      ref.read(teamsProvider.notifier).updateTeam(updatedTeam);
    }
    context.pop();
  }

  /// Opens Discovery in Players-only, signed-up-only, multi-select mode.
  /// Returns a `List<DiscoveryItem>` of selected players.
  Future<void> _openDiscoveryForPlayers() async {
    if (!_validateMandatoryFields(actionName: 'adding players')) return;
    final result = await context.push<dynamic>(
      '/discovery',
      extra: {
        'isSelectionMode': true,
        'initialTab': 'Players',
        'signedUpOnly': true, // only show players with a profile_id
        'multiSelect': true, // enable multi-select mode
      },
    );

    if (result != null && mounted) {
      // Handle multi-select result (List<DiscoveryItem>)
      final List<DiscoveryItem> selected;
      if (result is List) {
        selected = result.whereType<DiscoveryItem>().toList();
      } else if (result is DiscoveryItem) {
        selected = [result];
      } else {
        return;
      }

      if (selected.isEmpty) return;

      final List<TeamMember> toAdd = [];
      final List<String> duplicates = [];

      for (final item in selected) {
        // Skip duplicates already in squad (by name or profileId)
        if (_team.members.any(
          (m) =>
              m.name.toLowerCase() == item.name.toLowerCase() ||
              (m.profileId != null && m.profileId == item.rawId),
        )) {
          duplicates.add(item.name);
          continue;
        }

        String playerRole = 'BAT';
        if (item.role != null && item.role!.isNotEmpty) {
          final r = item.role!.toUpperCase();
          if (r.contains('WK') || r.contains('WICKET')) {
            playerRole = 'WK';
          } else if (r.contains('AR') || r.contains('ALL')) {
            playerRole = 'AR';
          } else if (r.contains('BOWL')) {
            playerRole = 'BOWL';
          }
        }

        toAdd.add(
          TeamMember(
            id: item.rawId,
            profileId: item.rawId,
            name: item.name,
            roles: [playerRole],
          ),
        );
      }

      if (toAdd.isNotEmpty) {
        setState(() {
          _team = _team.copyWith(members: [..._team.members, ...toAdd]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toAdd.length == 1
                  ? '${toAdd.first.name} added to squad'
                  : '${toAdd.length} players added to squad',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: const Color(0xFF191C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (duplicates.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${duplicates.join(', ')} already in squad',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: const Color(0xFFBA0013),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- Inline add-player method (commented out: replaced by Discovery flow) ---
  // void _addNewPlayer() {
  //   final name = _addPlayerController.text.trim();
  //   if (name.isNotEmpty) {
  //     final newMember = TeamMember(
  //       id: DateTime.now().millisecondsSinceEpoch.toString(),
  //       name: name,
  //       roles: _newPlayerRoles.isEmpty ? ['BAT'] : List.from(_newPlayerRoles),
  //     );
  //     setState(() {
  //       _team = _team.copyWith(members: [..._team.members, newMember]);
  //       _newPlayerRoles = [];
  //     });
  //     _addPlayerController.clear();
  //   }
  // }

  void _removePlayer(String id) {
    setState(() {
      _team = _team.copyWith(
        members: _team.members.where((m) => m.id != id).toList(),
      );
    });
  }

  void _toggleAdmin(String id) {
    setState(() {
      _team = _team.copyWith(
        members: _team.members.map((m) {
          if (m.id == id) {
            return m.copyWith(isAdmin: !m.isAdmin);
          }
          return m;
        }).toList(),
      );
    });
  }

  void _toggleCaptain(String id) {
    setState(() {
      _team = _team.copyWith(
        members: _team.members.map((m) {
          if (m.id == id) {
            return m.copyWith(isCaptain: !m.isCaptain);
          }
          return m;
        }).toList(),
      );
    });
  }

  void _toggleRole(String id, String role) {
    setState(() {
      _team = _team.copyWith(
        members: _team.members.map((m) {
          if (m.id == id) {
            List<String> updatedRoles = List.from(m.roles);
            if (updatedRoles.contains(role)) {
              updatedRoles.remove(role);
            } else {
              updatedRoles.add(role);
            }
            // Ensure at least one role is selected if possible, but allow empty for flexibility
            return m.copyWith(roles: updatedRoles);
          }
          return m;
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EDIT SQUAD',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showInviteSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 17.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE SQUAD',
                style: GoogleFonts.inter(
                  color: const Color(
                    0xFF5D3F3C,
                  ), // on-surface-variant based color
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF3EAE9,
                  ), // Light variant of red/primary
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Avatar/Logo
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(26, 33, 56, 0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              image: _localLogoPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(_localLogoPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : (_team.logoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_team.logoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                            ),
                            alignment: Alignment.center,
                            child:
                                (_localLogoPath == null &&
                                    _team.logoUrl == null)
                                ? Text(
                                    _team.name.isNotEmpty
                                        ? _team.name[0].toUpperCase()
                                        : 'T',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFBA0013),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBA0013),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Team Code badge
                    if (_team.teamCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFBA0013,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFBA0013,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _team.teamCode,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFBA0013),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField('TEAM NAME*', _teamNameController),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'CITY*',
                      _cityController,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('STATE*', _stateController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField('COUNTRY', _countryController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),

              // Invite Players
              GestureDetector(
                onTap: _showInviteSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(26, 33, 56, 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: Color(0xFFBA0013),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite players to join',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF191C1E),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tap to share link or QR code',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8E95A5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF575D78),
                          size: 20,
                        ),
                        onPressed: () {
                          if (_validateMandatoryFields(
                            actionName: 'copying invite link',
                          )) {
                            _copyToClipboard(_buildInviteLink());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 17),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(26, 33, 56, 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_team.members.length}',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFBA0013),
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Players',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF191C1E),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(26, 33, 56, 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Live',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF006B1B),
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Status',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF191C1E),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Roster Title & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Roster',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF191C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        // Navigates directly to Discovery (Players filter, signed-up only, multi-select)
                        onPressed: _openDiscoveryForPlayers,
                        icon: const Icon(
                          Icons.person_search,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Add Players',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBA0013),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Inline new-player input card (commented out: replaced by Discovery flow) ---
              // if (_showAddPlayerCard) _buildNewPlayerCard(),

              // Existing Players List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _team.members.length,
                itemBuilder: (context, index) {
                  final member = _team.members[index];
                  return _buildPlayerCard(member);
                },
              ),

              // Add more players placeholder / Discover prompt
              GestureDetector(
                onTap: _openDiscoveryForPlayers,
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 80),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE7BDB8),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(26, 33, 56, 0.03),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDEBED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Color(0xFFBA0013),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Find players in Discovery',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to browse & add registered players to squad',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8E95A5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveChanges,
        backgroundColor: const Color(0xFFBA0013),
        child: const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF5D3F3C),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            color: const Color(0xFF191C1E),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF575D78), size: 18)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF191C1E),
            width: 4,
          ), // existing players dark border
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFECEEF1),
              child: Icon(Icons.person, color: Color(0xFF575D78), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (member.isCaptain) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEBED),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'C',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFBA0013),
                              fontWeight: FontWeight.w700,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRolePill(
                        'BAT',
                        member.roles.contains('BAT'),
                        () => _toggleRole(member.id, 'BAT'),
                      ),
                      _buildRolePill(
                        'WK',
                        member.roles.contains('WK'),
                        () => _toggleRole(member.id, 'WK'),
                      ),
                      _buildRolePill(
                        'BOWL',
                        member.roles.contains('BOWL'),
                        () => _toggleRole(member.id, 'BOWL'),
                      ),
                      _buildRolePill(
                        'AR',
                        member.roles.contains('AR'),
                        () => _toggleRole(member.id, 'AR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF575D78),
                    size: 18,
                  ),
                  onPressed: () => _removePlayer(member.id),
                ),
                const SizedBox(height: 8),
                _buildToggleRow(
                  'Admin',
                  member.isAdmin,
                  (v) => _toggleAdmin(member.id),
                ),
                _buildToggleRow(
                  'Captain',
                  member.isCaptain,
                  (v) => _toggleCaptain(member.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA0013) : const Color(0xFFE0E3E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF575D78),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF191C1E),
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          height: 18,
          child: Transform.scale(
            scale: 0.6,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFFBA0013),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE0E3E6),
            ),
          ),
        ),
      ],
    );
  }
}
