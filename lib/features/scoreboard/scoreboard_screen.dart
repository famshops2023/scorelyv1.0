import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('MATCH SCOREBOARD', style: AppTypography.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInningsTab(),
            const SizedBox(height: 24),
            _buildBattingTable(),
            const SizedBox(height: 32),
            _buildBowlingTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildInningsTab() {
    return Row(
      children: [
        _tabItem('INNINGS 1', true),
        const SizedBox(width: 12),
        _tabItem('INNINGS 2', false),
      ],
    );
  }

  Widget _tabItem(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTypography.labelCaps.copyWith(
            color: isActive ? AppColors.onPrimary : AppColors.onBackground,
          )),
    );
  }

  Widget _buildBattingTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BATTING', style: AppTypography.labelCaps.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          _tableHeader(['PLAYER', 'R', 'B', '4s', '6s', 'SR']),
          const Divider(color: Colors.white10),
          _playerRow('Player 1*', '42', '28', '4', '2', '150.0'),
          _playerRow('Player 2', '15', '12', '1', '1', '125.0'),
        ],
      ),
    );
  }

  Widget _buildBowlingTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOWLING', style: AppTypography.labelCaps.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          _tableHeader(['BOWLER', 'O', 'M', 'R', 'W', 'ECON']),
          const Divider(color: Colors.white10),
          _playerRow('Bowler 1', '2.0', '0', '14', '1', '7.0'),
          _playerRow('Bowler 2', '2.0', '0', '18', '0', '9.0'),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> labels) {
    return Row(
      children: labels
          .map((l) => Expanded(
                flex: labels.indexOf(l) == 0 ? 3 : 1,
                child: Text(l, style: AppTypography.labelCaps.copyWith(fontSize: 10, color: Colors.white38)),
              ))
          .toList(),
    );
  }

  Widget _playerRow(String name, String r, String b, String f, String s, String sr) {
    List<String> values = [r, b, f, s, sr];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
          ...values.map((v) => Expanded(flex: 1, child: Text(v, style: AppTypography.bodyMedium))),
        ],
      ),
    );
  }
}
