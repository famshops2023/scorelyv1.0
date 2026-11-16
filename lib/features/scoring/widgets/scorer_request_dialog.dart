import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../models/scorer_assignment_request.dart';
import '../../../models/user_profile.dart';
import '../../../services/scorer_handover_service.dart';

class ScorerRequestDialog extends StatefulWidget {
  final ScorerAssignmentRequest request;
  final String currentUserId;
  final Function(bool accepted) onDecision;

  const ScorerRequestDialog({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.onDecision,
  });

  @override
  State<ScorerRequestDialog> createState() => _ScorerRequestDialogState();
}

class _ScorerRequestDialogState extends State<ScorerRequestDialog> {
  bool _isProcessing = false;

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    final success = await ScorerHandoverService.instance.acceptRequest(
      requestId: widget.request.id,
      userId: widget.currentUserId,
      matchId: widget.request.matchId,
      inningsId: widget.request.inningsId,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Navigator.pop(context);
      widget.onDecision(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to accept scorer request. It may have expired or been cancelled.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleDecline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Decline Scorer Request?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to decline scoring this match?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Decline', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    await ScorerHandoverService.instance.declineRequest(
      requestId: widget.request.id,
      userId: widget.currentUserId,
      reason: 'Declined by recipient',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context);
    widget.onDecision(false);
  }

  @override
  Widget build(BuildContext context) {
    final requester = widget.request.requestedByName ?? 'The current scorer';
    final match = widget.request.matchTitle ?? 'Live Cricket Match';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCORER REQUEST',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.lightTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Requested by: ',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                    Text(
                      requester,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        UserProfile.deriveDisplayId(widget.request.requestedByUserId),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$requester has requested you to take over the scorer role. If accepted, you will become the only active scorer for this match.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFECEEF1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isProcessing ? null : _handleDecline,
                  child: Text(
                    'Decline',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing ? null : _handleAccept,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Accept & Become Scorer',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
