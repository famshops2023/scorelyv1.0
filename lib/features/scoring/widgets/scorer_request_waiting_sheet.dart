import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../models/scorer_assignment_request.dart';
import '../../../models/user_profile.dart';
import '../../../services/scorer_handover_service.dart';

class ScorerRequestWaitingSheet extends StatefulWidget {
  final ScorerAssignmentRequest request;
  final VoidCallback onAccepted;
  final VoidCallback onChooseAnother;

  const ScorerRequestWaitingSheet({
    super.key,
    required this.request,
    required this.onAccepted,
    required this.onChooseAnother,
  });

  @override
  State<ScorerRequestWaitingSheet> createState() => _ScorerRequestWaitingSheetState();
}

class _ScorerRequestWaitingSheetState extends State<ScorerRequestWaitingSheet> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  late Duration _remaining;
  String _status = 'pending';
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _status = widget.request.status;
    _remaining = widget.request.remainingDuration;

    // 1. Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _status = 'expired';
          timer.cancel();
          _pollingTimer?.cancel();
        }
      });
    });

    // 2. Status polling timer (every 3 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final updated = await ScorerHandoverService.instance.getRequestById(widget.request.id);
    if (!mounted || updated == null) return;

    if (updated.status != _status) {
      setState(() {
        _status = updated.status;
      });

      if (updated.isAccepted) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
          widget.onAccepted();
        }
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _isCancelling = true);
    await ScorerHandoverService.instance.cancelRequest(widget.request.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final recipientName = widget.request.requestedScorerName ?? 'Selected Player';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_status == 'accepted') ...[
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 56),
            const SizedBox(height: 12),
            Text(
              'Scorer Transferred! 🏏',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$recipientName accepted the scorer request and is now scoring.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
          ] else if (_status == 'declined') ...[
            const Icon(Icons.cancel_outlined, color: AppColors.primary, size: 56),
            const SizedBox(height: 12),
            Text(
              'Request Declined',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$recipientName declined the scorer request. You remain the active scorer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onChooseAnother();
                },
                child: Text('Choose Another Scorer',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ] else if (_status == 'expired') ...[
            const Icon(Icons.timer_off_outlined, color: Colors.orange, size: 56),
            const SizedBox(height: 12),
            Text(
              'Request Expired',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The scorer request has expired after 10 minutes. You remain the active scorer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onChooseAnother();
                },
                child: Text('Select Another Scorer',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ] else ...[
            // Pending State
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Scorer Request Sent',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Waiting for $recipientName ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    UserProfile.deriveDisplayId(widget.request.requestedScorerUserId),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  ' to accept...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Expires in ${_formatDuration(_remaining)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextSecondary,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isCancelling ? null : _cancel,
                    child: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Cancel Request',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onChooseAnother();
                    },
                    child: Text(
                      'Choose Another',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
