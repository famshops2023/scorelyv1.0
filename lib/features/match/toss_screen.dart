import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'match_setup_screen.dart';

class TossScreen extends StatefulWidget {
  final MatchSetupData setupData;

  const TossScreen({super.key, required this.setupData});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  late String _tossWonBy;
  String _tossDecision = 'BATTING';

  @override
  void initState() {
    super.initState();
    _tossWonBy = widget.setupData.teamAName;
  }

  void _startScoring() {
    String battingFirstTeam;
    if (_tossWonBy == widget.setupData.teamAName) {
      battingFirstTeam = _tossDecision == 'BATTING'
          ? widget.setupData.teamAName
          : widget.setupData.teamBName;
    } else {
      battingFirstTeam = _tossDecision == 'BATTING'
          ? widget.setupData.teamBName
          : widget.setupData.teamAName;
    }

    final updatedData = widget.setupData.copyWith(
      tossWonBy: _tossWonBy,
      battingFirstTeam: battingFirstTeam,
    );

    context.pushReplacement('/scoring', extra: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'TOSS',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COIN TOSS WINNER',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF575D78),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTossCard(
                    widget.setupData.teamAName,
                    Icons.workspace_premium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTossCard(
                    widget.setupData.teamBName,
                    Icons.stadium_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'DECIDED TO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF575D78),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDecisionButton('BATTING')),
                const SizedBox(width: 12),
                Expanded(child: _buildDecisionButton('BOWLING')),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startScoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA0013),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFBA0013).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.sports_cricket,
                    color: Colors.white, size: 20),
                label: Text(
                  'START SCORING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTossCard(String teamName, IconData icon) {
    bool isSelected = _tossWonBy == teamName;
    return GestureDetector(
      onTap: () => setState(() => _tossWonBy = teamName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF191C1E) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFECEEF1)
                    : const Color(0xFFF7F9FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? const Color(0xFF191C1E)
                    : const Color(0xFFBFC5E4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              teamName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF191C1E)
                    : const Color(0xFFBFC5E4),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButton(String decision) {
    bool isSelected = _tossDecision == decision;
    return GestureDetector(
      onTap: () => setState(() => _tossDecision = decision),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFBA0013) : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          decision,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF575D78),
          ),
        ),
      ),
    );
  }
}
