import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatefulWidget {
  final int initialIndex;
  
  const InfoScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
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
          indicatorColor: const Color(0xFFBA0013),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
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
          _buildTextTab('Privacy Policy', _privacyText),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBA0013), Color(0xFF7B000D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBA0013).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Scorely',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'The Ultimate Cricket Scoring Experience',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scorely is designed to bring professional-grade cricket scoring to local leagues and passionate players. Built with precision and a sleek interface, we aim to make tracking every run, wicket, and over as seamless as possible.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: const Color(0xFF575D78),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(Icons.email_outlined, 'support@scorely.app'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.language, 'www.scorely.app'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFBA0013), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTab() {
    final faqs = [
      {
        'q': 'How do I create a new match?',
        'a': 'Go to the Home tab and tap the large red "+" button in the bottom right corner, or select "New Match" from the dashboard.'
      },
      {
        'q': 'Can I edit a player\'s stats after the match?',
        'a': 'Currently, match statistics are finalized once the match ends to ensure data integrity. However, you can edit player names and roles from the Teams tab.'
      },
      {
        'q': 'How does offline scoring work?',
        'a': 'Scorely stores all data locally on your device. When you regain internet connection and sign in, your data will automatically sync to the cloud.'
      },
      {
        'q': 'How do I share my team profile?',
        'a': 'Navigate to your Team Dashboard, tap on your team, and use the QR code or share icon at the top right to invite other players.'
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
                color: const Color(0xFF1A2138).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: const Color(0xFFBA0013),
              collapsedIconColor: const Color(0xFF575D78),
              title: Text(
                faqs[index]['q']!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF191C1E),
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  faqs[index]['a']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFF575D78),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF575D78),
            ),
          ),
        ],
      ),
    );
  }

  static const _privacyText = '''
Last Updated: August 2026

1. Information We Collect
We collect information you provide directly to us when you create an account, build a profile, or use our scoring features. This includes your name, email address, and cricket statistics.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services, including calculating player statistics and syncing your match data across devices.

3. Data Storage
Your match data is stored locally on your device for offline capabilities. If you sign in, data is synced securely to our cloud infrastructure.

4. Information Sharing
We do not share your personal information with third parties except as necessary to provide our services or as required by law.

5. Security
We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.
''';

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
