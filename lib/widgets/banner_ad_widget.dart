import 'package:flutter/material.dart';
import '../services/admob_service.dart';
import '../l10n/app_localizations.dart';

/// Banner reklam ve Pro teşvik widget'ı
/// Pro kullanıcılar için reklam göstermez, free kullanıcılar için banner + upgrade butonu gösterir
class BannerAdWidget extends StatefulWidget {
  final VoidCallback? onUpgradePressed;
  final bool showUpgradeButton;
  
  const BannerAdWidget({
    super.key,
    this.onUpgradePressed,
    this.showUpgradeButton = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdMobService _adMobService = AdMobService.instance;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdIfNeeded();
  }

  /// Gerekirse reklam yükler
  Future<void> _loadAdIfNeeded() async {
    if (_adMobService.shouldShowAds && !_adMobService.isBannerAdLoaded) {
      setState(() => _isAdLoading = true);
      
      await _adMobService.loadBannerAd();
      
      if (mounted) {
        setState(() => _isAdLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    // Pro kullanıcıysa hiçbir şey gösterme
    if (_adMobService.isProUser) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reklam alanı
          if (_isAdLoading)
            Container(
              height: 50,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
          else if (_adMobService.isBannerAdLoaded)
            _adMobService.getBannerAdWidget() ?? const SizedBox.shrink()
          else
            // Reklam yüklenemezse Pro upgrade alanı göster
            _buildUpgradePrompt(context, l10n),
          
          // Upgrade butonu (opsiyonel)
          if (widget.showUpgradeButton)
            _buildUpgradeButton(context, l10n),
        ],
      ),
    );
  }

  /// Pro upgrade prompt'u oluşturur
  Widget _buildUpgradePrompt(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diamond,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                             '${l10n.adFree} ${l10n.appTitle} ${l10n.premium}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Pro upgrade butonu oluşturur
  Widget _buildUpgradeButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ElevatedButton.icon(
        onPressed: widget.onUpgradePressed,
        icon: const Icon(Icons.star, size: 18),
        label: Text('🚫 ${l10n.removeAds}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Widget dispose edildiğinde reklam temizleme
    super.dispose();
  }
} 