import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';
import '../../services/ads/banner_ad_service.dart';

/// Policy-compliant, non-intrusive Banner Ad widget for Scorely.
///
/// Features:
/// - Adaptive sizing based on available width.
/// - Gracefully collapses to `SizedBox.shrink()` if ads are disabled,
///   configuration is missing, or loading fails.
/// - Prevents duplicate ad requests and memory leaks.
/// - Safe lifecycle handling and automatic ad resource disposal.
class ScorelyBannerAd extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final bool showCloseButton;

  const ScorelyBannerAd({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.showCloseButton = true,
  });

  @override
  State<ScorelyBannerAd> createState() => _ScorelyBannerAdState();
}

class _ScorelyBannerAdState extends State<ScorelyBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _hasFailed = false;
  bool _isDismissed = false;
  int _lastWidth = 0;

  void _dismissAd() {
    setState(() {
      _isDismissed = true;
    });
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAdIfNeeded();
  }

  void _loadAdIfNeeded() {
    if (_isDismissed) return;
    if (kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isBannerEnabled) return;
    if (AdConfig.bannerAdUnitId == null) return;

    final screenWidth = MediaQuery.of(context).size.width.truncate();
    if (screenWidth <= 0 || screenWidth == _lastWidth) return;
    _lastWidth = screenWidth;

    _loadBanner(screenWidth);
  }

  Future<void> _loadBanner(int width) async {
    if (_isDismissed || _isLoading) return;
    _isLoading = true;

    // Dispose any previous instance
    _bannerAd?.dispose();
    _bannerAd = null;

    try {
      final ad = await BannerAdService.instance.loadBannerAd(
        width: width,
        onAdLoaded: (BannerAd loadedAd) {
          if (!mounted || _isDismissed) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _bannerAd = loadedAd;
            _isLoaded = true;
            _isLoading = false;
            _hasFailed = false;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _isLoading = false;
            _hasFailed = true;
          });
        },
      );

      if (ad == null && mounted) {
        setState(() {
          _isLoading = false;
          _hasFailed = true;
        });
      }
    } catch (e) {
      debugPrint('[ScorelyBannerAd] Exception during banner load: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isBannerEnabled) {
      return const SizedBox.shrink();
    }

    if (_hasFailed || !_isLoaded || _bannerAd == null) {
      // Clean fallback: no layout shift, no fake placeholder
      return const SizedBox.shrink();
    }

    final adWidth = _bannerAd!.size.width.toDouble();
    final adHeight = _bannerAd!.size.height.toDouble();

    return SafeArea(
      top: false,
      child: Padding(
        padding: widget.padding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.showCloseButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, right: 4),
                  child: InkWell(
                    onTap: _dismissAd,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ad',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: adWidth,
                height: adHeight,
                child: AdWidget(ad: _bannerAd!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
