import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Central error reporting service.
///
/// • Writes errors to `error_log.txt` in the app's documents directory.
/// • Provides [reportByEmail] to let the user share/email the log to support.
class ErrorReporter {
  static const String _supportEmail = 'famshops2023@gmail.com';
  static const String _appName = 'Scorely';
  static const int _maxLogLines = 500; // Keep log lean

  // Singleton
  ErrorReporter._();
  static final ErrorReporter instance = ErrorReporter._();

  // ── Public API ──────────────────────────────────────────────────────────

  /// Log an exception + stack trace. Safe to call from any isolate.
  Future<void> log(Object error, StackTrace? stack, {String? context}) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final entry = StringBuffer()
        ..writeln('══════════════════════════════════════')
        ..writeln('[$timestamp]')
        ..writeln('Context : ${context ?? 'Unknown'}')
        ..writeln('Error   : $error')
        ..writeln('Stack   :')
        ..writeln(stack ?? 'No stack trace')
        ..writeln();

      // Print to console for debug builds
      if (kDebugMode) debugPrint(entry.toString());

      // Persist to file
      await _appendToLog(entry.toString());
    } catch (_) {
      // Never let the reporter itself crash the app
    }
  }

  /// Opens the device share sheet with the log as a text file so the user can
  /// email it to support from any installed mail app.
  Future<void> reportByEmail() async {
    try {
      final logFile = await _getLogFile();
      final exists = await logFile.exists();
      final logContent = exists
          ? await logFile.readAsString()
          : 'No errors have been logged yet.';

      final subject = '[$_appName] Bug Report';
      final body =
          'Hi Support Team,\n\nPlease find the attached error log below.\n\n'
          '─────────────────────────\n$logContent\n─────────────────────────\n\n'
          'Device info: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
          text: '$subject\n\nTo: $_supportEmail\n\n$body',
        ),
      );
    } catch (e) {
      debugPrint('ErrorReporter.reportByEmail failed: $e');
    }
  }

  /// Returns the last N lines of the log for in-app display.
  Future<String> getRecentLogs({int lines = 50}) async {
    try {
      final logFile = await _getLogFile();
      if (!await logFile.exists()) return 'No errors logged yet.';
      final allLines = await logFile.readAsLines();
      final recent = allLines.length > lines
          ? allLines.sublist(allLines.length - lines)
          : allLines;
      return recent.join('\n');
    } catch (_) {
      return 'Unable to read log.';
    }
  }

  /// Clears the log file (useful for "Clear Logs" action in settings).
  Future<void> clearLogs() async {
    try {
      final logFile = await _getLogFile();
      if (await logFile.exists()) await logFile.delete();
    } catch (_) {}
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/scorely_error_log.txt');
  }

  Future<void> _appendToLog(String entry) async {
    final logFile = await _getLogFile();

    // Trim to keep file small
    if (await logFile.exists()) {
      final lines = await logFile.readAsLines();
      if (lines.length > _maxLogLines) {
        final trimmed = lines.sublist(lines.length - _maxLogLines ~/ 2);
        await logFile.writeAsString(trimmed.join('\n'));
      }
    }

    await logFile.writeAsString(entry, mode: FileMode.append, flush: true);
  }
}
