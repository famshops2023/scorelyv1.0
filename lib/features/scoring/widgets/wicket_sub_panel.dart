import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';
import '../../../models/player_setup.dart';

class WicketSubPanel extends StatelessWidget {
  final String? selectedWicketType;
  final ValueChanged<String> onWicketTypeChanged;
  final String? selectedWicketBatter;
  final ValueChanged<String> onWicketBatterChanged;
  final String? selectedWicketFielder;
  final ValueChanged<String?> onWicketFielderChanged;
  final String? striker;
  final String? nonStriker;
  final List<PlayerSetupData> fieldingPlayers;
  final VoidCallback onConfirmWicket;

  const WicketSubPanel({
    super.key,
    required this.selectedWicketType,
    required this.onWicketTypeChanged,
    required this.selectedWicketBatter,
    required this.onWicketBatterChanged,
    required this.selectedWicketFielder,
    required this.onWicketFielderChanged,
    required this.striker,
    required this.nonStriker,
    required this.fieldingPlayers,
    required this.onConfirmWicket,
  });

  @override
  Widget build(BuildContext context) {
    final wicketTypes = ['Bowled', 'Caught', 'Run Out', 'LBW', 'Stumped', 'Hit Wicket'];
    final batters = [striker, nonStriker].whereType<String>().toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WICKET DETAILS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          // Wicket Type Dropdown
          Text(
            'Type',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF0F172A),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            initialValue: (selectedWicketType?.isNotEmpty ?? false) ? selectedWicketType : null,
            items: wicketTypes
                .map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w, style: GoogleFonts.inter(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) onWicketTypeChanged(val);
            },
          ),
          const SizedBox(height: 12),
          // Dismissed Batter Dropdown (only striker/non-striker)
          Text(
            'Dismissed Batter',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF0F172A),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            initialValue: (selectedWicketBatter?.isNotEmpty ?? false) ? selectedWicketBatter : null,
            items: batters
                .map((b) => DropdownMenuItem(
                      value: b == striker ? 'Striker' : 'Non-Striker',
                      child: Text(b == striker ? 'Striker ($b)' : 'Non-Striker ($b)',
                          style: GoogleFonts.inter(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) onWicketBatterChanged(val);
            },
          ),
          const SizedBox(height: 12),
          // Conditional fielder selector for Caught / Run Out / Stumped
          if (selectedWicketType == 'Caught' ||
              selectedWicketType == 'Run Out' ||
              selectedWicketType == 'Stumped') ...[
            Text(
              selectedWicketType == 'Caught' ? 'Catcher' : 'Assisting Fielder',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF0F172A),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              initialValue: selectedWicketFielder,
              items: fieldingPlayers
                  .map((f) => DropdownMenuItem(
                      value: f.name,
                      child: Text(f.name,
                          style: GoogleFonts.inter(color: Colors.white))))
                  .toList(),
              onChanged: onWicketFielderChanged,
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkCard2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onConfirmWicket,
            child: Text(
              'Confirm Wicket',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
