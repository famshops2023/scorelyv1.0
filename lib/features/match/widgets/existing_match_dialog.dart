import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../match_setup_screen.dart';

enum ExistingMatchAction {
  continueExisting,
  createNew,
  cancel,
}

class ExistingMatchDialog extends StatelessWidget {
  final MatchSetupData existingMatch;
  final VoidCallback onContinue;
  final VoidCallback onCreateNew;
  final VoidCallback onCancel;

  /// Static guard to prevent multiple popup instances from appearing at once
  static bool _isOpen = false;
  static bool get isOpen => _isOpen;

  const ExistingMatchDialog({
    super.key,
    required this.existingMatch,
    required this.onContinue,
    required this.onCreateNew,
    required this.onCancel,
  });

  static Future<ExistingMatchAction?> show(
    BuildContext context, {
    required MatchSetupData existingMatch,
    required VoidCallback onContinue,
    required VoidCallback onCreateNew,
    required VoidCallback onCancel,
  }) async {
    if (_isOpen) return null;
    _isOpen = true;

    try {
      return await showDialog<ExistingMatchAction>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => ExistingMatchDialog(
          existingMatch: existingMatch,
          onContinue: () {
            Navigator.of(ctx).pop(ExistingMatchAction.continueExisting);
            onContinue();
          },
          onCreateNew: () {
            Navigator.of(ctx).pop(ExistingMatchAction.createNew);
            onCreateNew();
          },
          onCancel: () {
            Navigator.of(ctx).pop(ExistingMatchAction.cancel);
            onCancel();
          },
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = existingMatch.status.toLowerCase();
    final isPending = status == 'pending';
    final isLive = status == 'live';

    final Color statusColor = isLive
        ? Colors.redAccent
        : isPending
            ? const Color(0xFFE67E22)
            : const Color(0xFF27AE60);

    final String statusLabel = isLive
        ? 'LIVE'
        : isPending
            ? 'PENDING'
            : 'COMPLETED';

    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a')
        .format(existingMatch.matchDate.toLocal());

    final matchTypeLabel = existingMatch.isQuickMatch
        ? 'Quick Match'
        : 'Schedule Match (${existingMatch.matchType})';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.4),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Gradient Header Banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7B000D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_toggle_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'EXISTING MATCH FOUND',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      existingMatch.displayMatchId,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  Text(
                    'A match with similar details has already been created. Please review the existing match before proceeding.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5A6278),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Inset Match Details Card ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E3E6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teams & Status Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${existingMatch.teamAName} vs ${existingMatch.teamBName}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 10),

                        // Match Metadata Rows
                        _buildMetaRow(Icons.sports_cricket, 'Type', matchTypeLabel),
                        const SizedBox(height: 6),
                        _buildMetaRow(Icons.calendar_today_outlined, 'Scheduled', dateFormatted),
                        if (existingMatch.venue.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildMetaRow(Icons.place_outlined, 'Venue', existingMatch.venue),
                        ],
                        const SizedBox(height: 6),
                        _buildMetaRow(Icons.repeat, 'Overs', '${existingMatch.overs} Overs'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Option 1: Continue Existing Match (Recommended) ─
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CONTINUE EXISTING MATCH',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open the existing match and continue without creating a duplicate.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF757D95),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Option 2: Create New Match ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onCreateNew,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC0C4D6), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CREATE NEW MATCH',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a separate match with a new Match ID. The existing match will remain unchanged.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF757D95),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Option 3: Cancel ─────────────────────────────────
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel — return to setup',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757D95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF757D95)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A6278),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

