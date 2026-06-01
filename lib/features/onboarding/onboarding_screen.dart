import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'PRECISION\nSCORING',
      subtitle: 'Track every ball with professional-grade accuracy and speed.',
      icon: Icons.bolt,
    ),
    OnboardingData(
      title: 'LIVE\nANALYTICS',
      subtitle: 'Real-time insights into run rates, partnerships, and win probability.',
      icon: Icons.analytics,
    ),
    OnboardingData(
      title: 'OFFLINE\nFIRST',
      subtitle: 'Score matches anywhere, anytime. No internet required.',
      icon: Icons.flash_on,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPageWidget(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 4,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : AppColors.onBackground.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Text(_currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 64,
            right: 24,
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                'SKIP',
                style: AppTypography.labelCaps.copyWith(color: AppColors.onBackground.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingData({required this.title, required this.subtitle, required this.icon});
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPageWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 48),
          Text(data.title, style: AppTypography.displayLarge),
          const SizedBox(height: 16),
          Text(data.subtitle, style: AppTypography.bodyLarge.copyWith(color: AppColors.onBackground.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
