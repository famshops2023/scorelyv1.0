import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/profile_provider.dart';
import '../match_setup_screen.dart';

/// Shows the "Let others view the match live" info dialog.
///
/// If the user is already logged in → proceeds directly to `/toss`.
/// If not → shows the promo dialog with **Cancel** and **Sign In** options.
///
/// Call this from every place that previously called `context.push('/toss', extra: data)`.
Future<void> proceedToToss(
  BuildContext context,
  WidgetRef ref,
  MatchSetupData setupData,
) async {
  final profile = ref.read(profileProvider);

  if (profile.isLoggedIn || setupData.isQuickMatch) {
    // Already signed in or Quick Match → go straight to toss
    context.push('/toss', extra: setupData);
    return;
  }

  // Not signed in → show promo dialog
  final shouldLogin = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => const _LiveMatchPromoDialog(),
  );

  if (!context.mounted) return;

  if (shouldLogin == true) {
    // Push to /login; when user returns, check if they logged in and proceed
    await context.push('/login');

    if (!context.mounted) return;
    final updated = ref.read(profileProvider);
    if (updated.isLoggedIn) {
      context.push('/toss', extra: setupData);
    }
  } else if (shouldLogin == false) {
    // User explicitly chose to score offline -> proceed to toss
    context.push('/toss', extra: setupData);
  }
  // If shouldLogin == null (dismissed via tap outside) -> do nothing
}

class _LiveMatchPromoDialog extends StatelessWidget {
  const _LiveMatchPromoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
            // ── Top red banner ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBA0013), Color(0xFF7B000D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.live_tv_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'GO LIVE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Text(
                    'Let others view the match!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1A2138),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to broadcast this match live. Friends, fans, and coaches '
                    'can follow the score in real-time from anywhere.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A2138).withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Benefit chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _chip(Icons.visibility_outlined, 'Live Spectators'),
                      _chip(Icons.bar_chart, 'Live Stats'),
                      _chip(Icons.share_outlined, 'Share Match'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA0013),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'SIGN IN / CREATE ACCOUNT',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel — score offline',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A2138).withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2138).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2138).withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1A2138).withValues(alpha: 0.6), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF1A2138).withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
