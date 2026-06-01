import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('SETTINGS', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('PREFERENCES'),
          _buildToggleTile(Icons.notifications, 'Notifications', true),
          _buildToggleTile(Icons.volume_up, 'Sound Effects', true),
          _buildToggleTile(Icons.dark_mode, 'Dark Mode', true),
          const SizedBox(height: 32),
          _buildSection('DATA MANAGEMENT'),
          _buildActionTile(
            Icons.cloud_off,
            'Offline Storage',
            'Active (Using Isar)',
            () {},
          ),
          _buildActionTile(
            Icons.delete,
            'Clear All History',
            '5 matches stored',
            () {},
          ),
          const SizedBox(height: 32),
          _buildSection('ABOUT'),
          _buildActionTile(
            Icons.info,
            'Version',
            '1.0.0 (Neon Velocity)',
            () {},
          ),
          _buildActionTile(Icons.description, 'Terms of Service', '', () {}),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16, top: 16),
      child: Text(
        title,
        style: AppTypography.labelCaps.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onBackground),
      title: Text(title, style: AppTypography.bodyLarge),
      trailing: Switch(
        value: value,
        onChanged: (val) {},
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.onBackground),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onBackground.withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}
