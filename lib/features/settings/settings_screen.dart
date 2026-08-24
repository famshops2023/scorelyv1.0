import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../providers/history_provider.dart';
import '../../providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _soundEffects = true;
  bool _keepAwake = true;
  int _defaultOvers = 20;
  int _storageLimit = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('settings_notifications') ?? true;
      _soundEffects = prefs.getBool('settings_sound_effects') ?? true;
      _keepAwake = prefs.getBool('settings_keep_awake') ?? true;
      _defaultOvers = prefs.getInt('settings_default_overs') ?? 20;
      _storageLimit = prefs.getInt('settings_storage_limit') ?? 5;
      _isLoading = false;
    });
  }

  Future<void> _updateBoolSetting(String key, bool value, ValueChanged<bool> updateState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      updateState(value);
    });
  }

  Future<void> _updateIntSetting(String key, int value, ValueChanged<int> updateState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    setState(() {
      updateState(value);
    });
  }

  void _showClearHistoryConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x1AFF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever, color: Color(0xFFFF4444), size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Clear Match History?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action will permanently delete all stored matches and statistics from this device. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.onBackground.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(matchHistoryProvider.notifier).clearAllMatches();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'All match history cleared successfully.',
                                  style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4444),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'DELETE ALL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x1AFF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_remove_outlined, color: Color(0xFFFF4444), size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Account?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you really want to delete your account? The entire data will get lost permanently and this cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(profileProvider.notifier).signOut();
                          if (context.mounted) {
                            Navigator.pop(context);
                            context.go('/');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStorageLimitSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Keep Match History Limit',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          children: [5, 10, 25, 50].map((limit) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _updateIntSetting('settings_storage_limit', limit, (v) => _storageLimit = v);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$limit Matches',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: _storageLimit == limit ? FontWeight.bold : FontWeight.normal,
                        color: _storageLimit == limit ? AppColors.primary : AppColors.onBackground,
                      ),
                    ),
                    if (_storageLimit == limit)
                      const Icon(Icons.check, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionTitle('PREFERENCES'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildToggleTile(
                    Icons.notifications_none_outlined,
                    'Notification Alerts',
                    'Get alerts for matches and sync events',
                    _notifications,
                    (val) => _updateBoolSetting('settings_notifications', val, (v) => _notifications = v),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _buildToggleTile(
                    Icons.volume_up_outlined,
                    'Sound Effects',
                    'Play sounds for boundaries and wickets',
                    _soundEffects,
                    (val) => _updateBoolSetting('settings_sound_effects', val, (v) => _soundEffects = v),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _buildToggleTile(
                    Icons.phone_android_outlined,
                    'Keep Screen Awake',
                    'Prevent device screen from sleeping during scoring',
                    _keepAwake,
                    (val) => _updateBoolSetting('settings_keep_awake', val, (v) => _keepAwake = v),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('MATCH CONFIGURATION'),
                const SizedBox(height: 8),
                _buildCard([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Default Over Limit',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_defaultOvers Overs',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pre-fill overs parameter in new match setup screen',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.secondary.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                            valueIndicatorColor: AppColors.surface,
                            valueIndicatorTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          child: Slider(
                            value: _defaultOvers.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '$_defaultOvers',
                            onChanged: (val) {
                              _updateIntSetting('settings_default_overs', val.round(), (v) => _defaultOvers = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('DATA & STORAGE'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildActionTile(
                    Icons.storage_outlined,
                    'Storage Optimizer',
                    'Limit offline matches to $_storageLimit',
                    onTap: () => _showStorageLimitSelector(context),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _buildActionTile(
                    Icons.cloud_done_outlined,
                    'Offline Database',
                    'Active (Drift SQLite Storage)',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  _buildActionTile(
                    Icons.delete_outline,
                    'Clear Match History',
                    '${matches.length} matches stored locally',
                    color: const Color(0xFFFF4444),
                    onTap: () => _showClearHistoryConfirmation(context),
                  ),
                ]),
                const SizedBox(height: 24),
                if (ref.watch(profileProvider).isLoggedIn) ...[
                  _buildSectionTitle('ACCOUNT'),
                  const SizedBox(height: 8),
                  _buildCard([
                    _buildActionTile(
                      Icons.person_remove_outlined,
                      'Delete Account',
                      'Permanently delete your profile and data',
                      color: const Color(0xFFFF4444),
                      onTap: () => _showDeleteAccountConfirmation(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle('ABOUT'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildActionTile(
                    Icons.info_outline,
                    'Version',
                    '1.0.0 (Elite Pitch Edition)',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.labelCaps,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.onBackground, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.secondary.withValues(alpha: 0.7)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.white10,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle, {
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.onBackground, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.onBackground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.secondary.withValues(alpha: 0.7)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
    );
  }
}
