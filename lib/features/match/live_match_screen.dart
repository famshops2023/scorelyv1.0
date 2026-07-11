import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveMatchScreen extends StatelessWidget {
  const LiveMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFF7F9FC), size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scorely',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFBA0013).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA0013),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFBA0013),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildScoreCard(),
            const SizedBox(height: 16),
            _buildBattingBowlingCard(),
            const SizedBox(height: 16),
            _buildPartnershipAndOverCard(),
            const SizedBox(height: 16),
            _buildMatchInsights(),
            const SizedBox(height: 16),
            _buildLiveCommentary(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2138),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Logo - Info - Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    radius: 16,
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TIT',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006B1B), // Active Green
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '2ND INNINGS',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MATCH IN PROGRESS',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF006B1B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'STR',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    radius: 16,
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Main Score
          Text(
            '142/4',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '16.2 Ov',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          // Divider and Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatText('Target', '185'),
                    _buildStatText('Req. RR', '11.82'),
                    _buildStatText('CRR', '8.69'),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      height: 4,
                      width: 200, // Hardcoded for demo
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA0013),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Titans CC need 43 runs in 22 balls',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingBowlingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Batting Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeader('PLAYER')),
                    Expanded(child: _buildTableHeader('R', alignRight: true)),
                    Expanded(child: _buildTableHeader('B', alignRight: true)),
                    Expanded(child: _buildTableHeader('4S', alignRight: true)),
                    Expanded(child: _buildTableHeader('6S', alignRight: true)),
                    Expanded(
                      flex: 2,
                      child: _buildTableHeader('SR', alignRight: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBattingRow(
                  'Arun*',
                  '42',
                  '31',
                  '5',
                  '2',
                  '135.5',
                  isStriker: true,
                ),
                const SizedBox(height: 12),
                _buildBattingRow('Kumar', '18', '14', '2', '1', '128.6'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E3E6)),
          // Bowling Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeader('BOWLER')),
                    Expanded(child: _buildTableHeader('O', alignRight: true)),
                    Expanded(child: _buildTableHeader('M', alignRight: true)),
                    Expanded(child: _buildTableHeader('R', alignRight: true)),
                    Expanded(child: _buildTableHeader('W', alignRight: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBowlingRow('Ravi', '3.2', '0', '22', '2'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF575D78),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBattingRow(
    String name,
    String r,
    String b,
    String fours,
    String sixes,
    String sr, {
    bool isStriker = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              if (isStriker)
                Container(
                  width: 3,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA0013),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isStriker ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            r,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
        Expanded(
          child: Text(
            fours,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
        Expanded(
          child: Text(
            sixes,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            sr,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBowlingRow(String name, String o, String m, String r, String w) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            o,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            m,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
        Expanded(
          child: Text(
            r,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ),
        Expanded(
          child: Text(
            w,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBA0013),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnershipAndOverCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT PARTNERSHIP',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF575D78),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '60 ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFBA0013),
                        ),
                      ),
                      Text(
                        '(45 balls)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(
                Icons.handshake_outlined,
                color: Color(0xFFBFC5E4),
                size: 28,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E3E6)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS OVER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF575D78),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBallCircle('1', const Color(0xFF575D78)),
                  _buildBallCircle(
                    '0',
                    const Color(0xFFE0E3E6),
                    textColor: const Color(0xFF575D78),
                  ),
                  _buildBallCircle('4', const Color(0xFF78DC77)), // Green
                  _buildBallCircle('W', const Color(0xFFBA0013)),
                  _buildBallCircle(
                    '6',
                    const Color(0xFFFFB4AB),
                    textColor: const Color(0xFF93000D),
                  ),
                  _buildBallCircle('lb2', const Color(0xFF5B627C)),
                  _buildBallCircle(
                    '•',
                    const Color(0xFFF2F4F7),
                    textColor: const Color(0xFF575D78),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBallCircle(
    String text,
    Color bgColor, {
    Color textColor = Colors.white,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMatchInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFFBA0013), size: 20),
              const SizedBox(width: 8),
              Text(
                'Match Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TITANS 72%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFBA0013),
                ),
              ),
              Text(
                'STORM 28%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF575D78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 72,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA0013),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 28,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2138),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECTED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Current RR: '),
                            TextSpan(
                              text: '168\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1E),
                              ),
                            ),
                            const TextSpan(text: '@ 10 RPO: '),
                            TextSpan(
                              text: '185',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1E),
                              ),
                            ),
                          ],
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BEST STAND',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '54',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFBA0013),
                        ),
                      ),
                      Text(
                        'Kohli & Sharma',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCommentary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFFBA0013),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Commentary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF191C1E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBA0013),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBA0013),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCommentaryItem(
          '16.2',
          'Ravi to Arun',
          'runs 2.',
          '2',
          const Color(0xFF5B627C),
        ),
        _buildCommentaryItem(
          '16.1',
          'Ravi to Arun',
          'hits SIX!',
          '6',
          const Color(0xFFFFDAD6),
          isBoundary: true,
        ),
        _buildCommentaryItem(
          '16.0',
          'Ravi to Kumar',
          '1 run.',
          '1',
          const Color(0xFF5B627C),
        ),
        _buildCommentaryItem(
          '15.6',
          'Ravi to Kumar',
          'dot ball.',
          '•',
          const Color(0xFFF2F4F7),
          isDot: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE7BDB8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'VIEW FULL COMMENTARY',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBA0013),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentaryItem(
    String over,
    String players,
    String action,
    String ballText,
    Color ballColor, {
    bool isBoundary = false,
    bool isDot = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F4F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                over,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFBA0013),
                ),
              ),
              const SizedBox(width: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$players, ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    TextSpan(text: action),
                  ],
                ),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDot
                      ? const Color(0xFF575D78)
                      : const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: ballColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              ballText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isBoundary
                    ? const Color(0xFF93000D)
                    : (isDot ? const Color(0xFF575D78) : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
        top: 10,
        left: 14,
        right: 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => context.push('/home'),
            child: _buildNavItem(Icons.home_outlined, 'Home', false),
          ),
          _buildNavItem(Icons.play_circle_fill, 'Live', true),
          GestureDetector(
            onTap: () {},
            child: _buildNavItem(Icons.bar_chart, 'Scorecard', false),
          ),
          GestureDetector(
            onTap: () => context.push('/teams'),
            child: _buildNavItem(Icons.people_alt_outlined, 'Squad', false),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFBA0013), size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBA0013),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF575D78), size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF575D78),
            ),
          ),
        ],
      ),
    );
  }
}
