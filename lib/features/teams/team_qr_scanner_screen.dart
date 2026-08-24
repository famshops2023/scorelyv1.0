import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamQRScannerScreen extends StatefulWidget {
  const TeamQRScannerScreen({super.key});

  @override
  State<TeamQRScannerScreen> createState() => _TeamQRScannerScreenState();
}

class _TeamQRScannerScreenState extends State<TeamQRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SCAN QR',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF191C1E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            iconSize: 28.0,
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: (capture) {
          if (!_isScanning) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first;
            final String? rawValue = barcode.rawValue;
            if (rawValue != null) {
              setState(() => _isScanning = false);
              
              // Depending on what is in the QR code:
              // For Scorely teams, we generated QR codes in _buildQRBottomSheet like 'team.id'.
              context.pop(rawValue);
            }
          }
        },
      ),
    );
  }
}
