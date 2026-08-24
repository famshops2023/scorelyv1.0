import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScorelyShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScorelyShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ScorelyShell> createState() => _ScorelyShellState();
}

class _ScorelyShellState extends ConsumerState<ScorelyShell> {
  // Helper to map branch index to our tab index (since SCORE FAB is index 2 but not a branch)
  int _getSelectedIndex() {
    final branchIndex = widget.navigationShell.currentIndex;
    if (branchIndex >= 2) {
      return branchIndex + 1; // Shift by 1 for the center button
    }
    return branchIndex;
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      // Show match start bottom sheet
      _showMatchPickerBottomSheet(context);
    } else {
      // Map back to branch index
      final branchIndex = index > 2 ? index - 1 : index;
      widget.navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == widget.navigationShell.currentIndex,
      );
    }
  }

  Future<void> _handleQuickMatchTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenQuickMatchWarning =
        prefs.getBool('seen_quick_match_warning') ?? false;
    final int limit = prefs.getInt('settings_storage_limit') ?? 5;
    final int defaultOvers = prefs.getInt('settings_default_overs') ?? 20;

    if (hasSeenQuickMatchWarning) {
      if (context.mounted) {
        context.push('/create-team', extra: {'isQuickMatch': true});
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFBA0013), width: 6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info, color: Color(0xFFBA0013), size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Heads Up!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2138),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dynamic match details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E3E6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$defaultOvers',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFBA0013),
                                ),
                              ),
                              Text(
                                'Default Overs',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF5A6278),
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE0E3E6)),
                          Column(
                            children: [
                              Text(
                                '$limit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A2138),
                                ),
                              ),
                              Text(
                                'Matches Stored',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF5A6278),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your match will start with $defaultOvers overs. To keep Scorely running smoothly, only your latest $limit matches are stored on this device — older ones are auto-deleted.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5A6278),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF1A2138)),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2138),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBA0013),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'I UNDERSTAND',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      await prefs.setBool('seen_quick_match_warning', true);
      if (context.mounted) {
        context.push('/create-team', extra: {'isQuickMatch': true});
      }
    }
  }

  void _showMatchPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(26, 33, 56, 0.15),
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E3E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start a New Match',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to configure your cricket match',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF575D78),
                ),
              ),
              const SizedBox(height: 24),
              // Quick Match Card
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _handleQuickMatchTap(this.context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA0013),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA0013).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK MATCH',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start scoring instantly with offline teams in 30s',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Scheduled Match Card
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  this.context.push('/match-setup');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: Color(0xFFBA0013), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCHEDULE MATCH',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF191C1E),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure a planned match with detailed configurations',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF575D78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF191C1E), size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex();

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, _) {
          final bottomInset = MediaQuery.of(context).viewPadding.bottom;
          return Container(
            padding: EdgeInsets.only(
              bottom: 8 + bottomInset,
              top: 8,
              left: 10,
              right: 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.06),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', selectedIndex == 0),
                _buildNavItem(1, Icons.groups_outlined, Icons.groups, 'Teams', selectedIndex == 1),
                _buildScoreFabItem(),
                _buildNavItem(3, Icons.history, Icons.history, 'History', selectedIndex == 3),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile', selectedIndex == 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFE8E6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? filledIcon : outlineIcon,
                  color: isActive ? const Color(0xFFBA0013) : const Color(0xFF575D78),
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFFBA0013) : const Color(0xFF575D78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreFabItem() {
    return GestureDetector(
      onTap: () => _onTabSelected(2),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFBA0013),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBA0013).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.sports_cricket,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
