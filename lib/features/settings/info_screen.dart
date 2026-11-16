import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ads/consent_service.dart';

class InfoScreen extends StatefulWidget {
  final int initialIndex;

  const InfoScreen({super.key, this.initialIndex = 0});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Information',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'About Us'),
            Tab(text: 'Help / FAQs'),
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Service'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutUsTab(),
          _buildFaqTab(),
          _buildPrivacyPolicyTab(),
          _buildTextTab('Terms of Service', _termsText),
        ],
      ),
    );
  }

  Widget _buildAboutUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/scorely_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scorely',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
          ),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'The Ultimate Cricket Scoring Experience',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scorely is designed to bring professional-grade cricket scoring to local leagues and passionate players. Built with precision and a sleek interface, we aim to make tracking every run, wicket, and over as seamless as possible.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(Icons.email_outlined, 'innomerce89@gmail.com'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.language, 'www.innomerce.in'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTab() {
    final faqs = [
      {
        'q': 'How do I create a new match?',
        'a':
            'Go to the Home tab and tap the large red "Bat & Ball" button in the bottom right corner, or select "New Match" from the dashboard.',
      },
      {
        'q': 'Can I edit a player\'s stats after the match?',
        'a':
            'Currently, match statistics are finalized once the match ends to ensure data integrity. However, you can edit player names and roles from the Teams tab.',
      },
      {
        'q': 'How does offline scoring work?',
        'a':
            'Scorely stores all data locally on your device. When you regain internet connection and sign in, your data will automatically sync to the cloud.',
      },
      {
        'q': 'How do I share my team profile?',
        'a':
            'Navigate to your Team Dashboard, tap on your team, and use the QR code or share icon at the top right to invite other players.',
      },
      {
        'q': 'How do I delete my Scorely account?',
        'a':
            'You can permanently delete your account and all associated match data at any time. Go to Settings > Danger Zone > Delete Account, and confirm the deletion. This will permanently remove your cloud profile, match records, and local data.',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: faqs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.lightTextSecondary,
              title: Text(
                faqs[index]['q']!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  faqs[index]['a']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPolicyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Policy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkSurface.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Privacy Policy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'innomerce.in/scorely-privacy-policy',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Scorely values your privacy and data security. You can review our full, official Privacy Policy online at any time.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://innomerce.in/scorely-privacy-policy');
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch Privacy Policy: $e');
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      'Open Privacy Policy',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ad Choices & Consent (Google UMP)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Users in the European Economic Area (EEA) and the UK can review or change their advertising consent preferences at any time.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final shown = await ConsentService.instance
                        .showPrivacyOptionsForm();
                    if (!shown && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Consent form is not required in your region. Standard Google Play compliant ads are served.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Manage Ad Consent'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(String title, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static const _termsText = '''
Last Updated: August 2026

1. Acceptance of Terms
By accessing and using the Scorely app, you agree to be bound by these Terms of Service.

2. User Accounts
You must provide accurate information when creating an account. You are responsible for safeguarding your password and for all activities that occur under your account.

3. Acceptable Use
You agree not to use the app to submit false match data intentionally or harass other players. We reserve the right to suspend accounts that violate these terms.

4. Intellectual Property
The app and its original content, features, and functionality are owned by Scorely and are protected by international copyright and trademark laws.

5. Limitation of Liability
Scorely shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the app.

6. Changes to Terms
We reserve the right to modify these terms at any time. We will notify users of any significant changes.
''';
}
