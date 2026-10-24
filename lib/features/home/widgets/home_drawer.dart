import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scorely/core/theme/colors.dart';
import '../../../providers/profile_provider.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightTextSecondary),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isLoggedIn = profile.isLoggedIn;
    final userName = isLoggedIn && profile.name.isNotEmpty
        ? profile.name
        : 'Guest User';
    final userEmail = isLoggedIn ? profile.email : 'Sign in to sync your data';

    return Drawer(
      backgroundColor: AppColors.lightBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.lightTextPrimary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isLoggedIn) {
                      Navigator.pop(context);
                      context.push('/login');
                    }
                  },
                  child: Text(
                    userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isLoggedIn ? Colors.white70 : Colors.blue[300],
                      decoration: isLoggedIn
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics_outlined,
            title: 'My performance',
            onTap: () {
              Navigator.pop(context);
              context.push('/performance');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.star_outline,
            title: 'Rate us',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            title: 'About us',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 0);
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help/FAQs',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 1);
            },
          ),
          _buildDrawerItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 2);
            },
          ),
          _buildDrawerItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 3);
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          _buildDrawerItem(
            icon: Icons.share_outlined,
            title: 'Share app',
            onTap: () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Check out Scorely! The ultimate cricket scoring app for live match updates and team management. Download it now: https://scorely.app',
                  subject: 'Scorely Cricket App',
                ),
              );
            },
          ),
          if (isLoggedIn) ...[
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Sign out',
              onTap: () async {
                Navigator.pop(context);
                await ref.read(profileProvider.notifier).signOut();
              },
            ),
          ],
        ],
      ),
    );
  }
}
