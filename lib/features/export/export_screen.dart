import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'pdf_generator.dart';
import '../../services/database.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class ExportScreen extends StatelessWidget {
  final CricketMatch match;

  const ExportScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('EXPORT SCORECARD', style: AppTypography.headlineMedium),
      ),
      body: PdfPreview(
        build: (format) => PdfGenerator.generateScorecard(match),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        pdfFileName: 'Scorely_${match.matchTitle}_Scorecard.pdf',
        initialPageFormat: PdfPageFormat.a4,
        loadingWidget: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
    );
  }
}
