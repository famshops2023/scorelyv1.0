import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/error_reporter.dart';

/// A friendly full-screen error widget that replaces Flutter's red
/// "error occurred" screen in release builds.
///
/// Usage – register once in main.dart:
/// ```dart
/// ErrorWidget.builder = (details) => AppErrorWidget(details: details);
/// ```
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const AppErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA0013).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFBA0013),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Oops! Something went wrong',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'An unexpected error occurred. Your match data is safe. '
                'Please restart the screen or report this issue to our support team.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ErrorReporter.instance.reportByEmail(),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Send Bug Report to Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA0013),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Go Back Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Pop the broken route if possible
                    final nav = Navigator.maybeOf(context);
                    if (nav != null && nav.canPop()) {
                      nav.pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error detail (shown only in debug mode)
              Text(
                'Error ref: ${details.exceptionAsString().substring(0, details.exceptionAsString().length.clamp(0, 80))}...',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
