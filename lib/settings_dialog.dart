import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'services/credit_manager.dart';
import 'services/subscription_manager.dart';
import 'l10n/app_localizations.dart';
import 'utils/performance_monitor.dart';
import 'screens/ocr_history_screen.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback? onCreditsChanged;
  
  const SettingsDialog({
    super.key,
    this.onCreditsChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop(    );
  }


}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((255 * 0.4 * _fadeAnimation.value).toInt()),
            ),
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 600,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? (255 * 0.3).toInt() : (255 * 0.1).toInt()),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(isDark),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildThemeSection(isDark),
                                  const SizedBox(height: 32),
                                  _buildLanguageSection(isDark),
                                  const SizedBox(height: 32),
                                  _buildOCRHistorySection(isDark),
                                  const SizedBox(height: 32),
                                  _buildPerformanceSection(isDark),
                                  const SizedBox(height: 32),
                                  _buildCreditSection(isDark),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF).withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.settings_solid,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.settings,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  context.l10n.settingsSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _closeDialog,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha((255 * 0.1).toInt()) : Colors.black.withAlpha((255 * 0.05).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.theme,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    isDark: isDark,
                    title: context.l10n.lightTheme,
                    subtitle: context.l10n.lightThemeSubtitle,
                    icon: CupertinoIcons.sun_max_fill,
                    iconColor: const Color(0xFFFF9500),
                    mode: AppThemeMode.light,
                    isSelected: themeProvider.themeMode == AppThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.light),
                    isFirst: true,
                  ),
                  _buildDivider(isDark),
                  _buildThemeOption(
                    isDark: isDark,
                    title: context.l10n.darkTheme,
                    subtitle: context.l10n.darkThemeSubtitle,
                    icon: CupertinoIcons.moon_fill,
                    iconColor: const Color(0xFF5856D6),
                    mode: AppThemeMode.dark,
                    isSelected: themeProvider.themeMode == AppThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.dark),
                  ),
                  _buildDivider(isDark),
                  _buildThemeOption(
                    isDark: isDark,
                    title: context.l10n.systemTheme,
                    subtitle: context.l10n.systemThemeSubtitle,
                    icon: CupertinoIcons.device_phone_portrait,
                    iconColor: const Color(0xFF34C759),
                    mode: AppThemeMode.system,
                    isSelected: themeProvider.themeMode == AppThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.system),
                    isLast: true,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required AppThemeMode mode,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.language,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(
                    isDark: isDark,
                    title: context.l10n.turkish,
                    subtitle: 'Türkçe',
                    icon: CupertinoIcons.globe,
                    iconColor: const Color(0xFFE74C3C),
                    locale: const Locale('tr', 'TR'),
                    isSelected: themeProvider.locale.languageCode == 'tr',
                    onTap: () => themeProvider.setLocale(const Locale('tr', 'TR')),
                    isFirst: true,
                  ),
                  _buildDivider(isDark),
                  _buildLanguageOption(
                    isDark: isDark,
                    title: context.l10n.english,
                    subtitle: 'English',
                    icon: CupertinoIcons.globe,
                    iconColor: const Color(0xFF3498DB),
                    locale: const Locale('en', 'US'),
                    isSelected: themeProvider.locale.languageCode == 'en',
                    onTap: () => themeProvider.setLocale(const Locale('en', 'US')),
                    isLast: true,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                  color: iconColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: const Color(0xFF007AFF),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                          context.l10n.performanceStatistics,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<SessionStats>(
          future: PerformanceMonitor.instance.getCurrentSessionStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            
            final stats = snapshot.data ?? SessionStats.empty();
            
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPerformanceItem(
                    isDark: isDark,
                    title: context.l10n.totalOperationsLabel,
                    value: '${stats.totalOperations}',
                    icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
                    iconColor: const Color(0xFF007AFF),
                    isFirst: true,
                  ),
                  if (stats.totalOperations > 0) ...[
                    _buildDivider(isDark),
                    _buildPerformanceItem(
                      isDark: isDark,
                      title: context.l10n.successRateLabel,
                      value: '${(stats.successRate * 100).toStringAsFixed(1)}%',
                      icon: CupertinoIcons.checkmark_shield_fill,
                      iconColor: const Color(0xFF34C759),
                    ),
                    _buildDivider(isDark),
                    _buildPerformanceItem(
                      isDark: isDark,
                      title: context.l10n.averageTimeLabel,
                      value: '${stats.avgProcessingTime.inMilliseconds}ms',
                      icon: CupertinoIcons.timer,
                      iconColor: const Color(0xFFFF9500),
                    ),
                    _buildDivider(isDark),
                    _buildPerformanceItem(
                      isDark: isDark,
                      title: context.l10n.extractedTextTitle,
                      value: '${stats.totalTextExtracted} ${context.l10n.characters}',
                      icon: CupertinoIcons.textformat,
                      iconColor: const Color(0xFF8E44AD),
                      isLast: true,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildPerformanceActions(isDark),
      ],
    );
  }

  Widget _buildPerformanceItem({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceActions(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetailedStats(isDark),
                child: Center(
                  child: Text(
                    context.l10n.detailedReportButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFDC3545),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _clearPerformanceData(),
                child: Center(
                  child: Text(
                    context.l10n.clearData,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDetailedStats(bool isDark) async {
    final report = await PerformanceMonitor.instance.generatePerformanceReport(
      period: const Duration(days: 7),
    );
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
                        context.l10n.detailedReport,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                      _buildStatRow(isDark, '${context.l10n.totalOperations}:', '${report.totalOperations}'),
        _buildStatRow(isDark, '${context.l10n.successRate}:', '${(report.successRate * 100).toStringAsFixed(1)}%'),
        _buildStatRow(isDark, '${context.l10n.averageTime}:', '${report.avgProcessingTime.inMilliseconds}ms'),
        _buildStatRow(isDark, '${context.l10n.fastest}:', '${report.minProcessingTime.inMilliseconds}ms'),
        _buildStatRow(isDark, '${context.l10n.slowest}:', '${report.maxProcessingTime.inMilliseconds}ms'),
        _buildStatRow(isDark, '${context.l10n.extractedTextTitle}:', '${report.totalTextExtracted} ${context.l10n.characters}'),
              
              if (report.enginePerformance.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${context.l10n.enginePerformance}:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                ...report.enginePerformance.entries.map((entry) =>
                  _buildStatRow(
                    isDark,
                    '${entry.key.displayName}:',
                    context.l10n.enginePerformanceValue
                        .replaceAll('{count}', entry.value.totalOperations.toString())
                        .replaceAll('{rate}', (entry.value.successRate * 100).toStringAsFixed(1)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.close,
              style: TextStyle(
                color: isDark ? const Color(0xFF007AFF) : const Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearPerformanceData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearPerformanceData),
        content: Text(context.l10n.performanceDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.clear, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Performance data temizleme işlemi burada yapılacak
      setState(() {}); // Widget'ı yenile
    }
  }

  Widget _buildCreditSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.creditInfo,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<CreditManager>(
          builder: (context, creditManager, child) {
            return FutureBuilder<CreditStats>(
              future: creditManager.getCreditStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildLoadingCard(isDark);
                }

                final stats = snapshot.data!;
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCreditItem(
                        isDark: isDark,
                        title: context.l10n.currentCredits,
                        value: '${stats.currentCredits}',
                        icon: CupertinoIcons.creditcard_fill,
                        iconColor: const Color(0xFF007AFF),
                        isFirst: true,
                      ),
                      _buildDivider(isDark),
                      _buildCreditItem(
                        isDark: isDark,
                        title: context.l10n.totalUsed,
                        value: '${stats.totalUsed}',
                        icon: CupertinoIcons.chart_bar_fill,
                        iconColor: const Color(0xFF34C759),
                      ),
                      _buildDivider(isDark),
                      _buildCreditItem(
                        isDark: isDark,
                        title: context.l10n.subscription,
                        value: _getSubscriptionName(stats.subscription),
                        icon: CupertinoIcons.star_fill,
                        iconColor: const Color(0xFFFF9500),
                        isLast: true,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        _buildBuyCreditsButton(isDark),
        const SizedBox(height: 16),
        _buildSubscriptionSection(isDark),
      ],
    );
  }

  Widget _buildCreditItem({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyCreditsButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
                          color: const Color(0xFF007AFF).withAlpha((255 * 0.3).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCreditPurchaseDialog(context),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.buyCredits,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CupertinoActivityIndicator(
          color: isDark ? Colors.white : const Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 56),
              color: isDark ? Colors.white.withAlpha((255 * 0.1).toInt()) : Colors.black.withAlpha((255 * 0.1).toInt()),
    );
  }

  String _getSubscriptionName(SubscriptionType subscription) {
    switch (subscription) {
      case SubscriptionType.free:
        return context.l10n.freeSubscription;
      case SubscriptionType.pro:
        return context.l10n.proSubscription;
      case SubscriptionType.premium:
        return context.l10n.premiumSubscription;
    }
  }

  Widget _buildSubscriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            context.l10n.subscription.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(
              color: const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              _buildSubscriptionOption(
                isDark: isDark,
                title: '🚀 Pro Aylık',
                subtitle: '₺29.99/ay - Reklamsız + Sınırsız OCR',
                features: ['Reklamsız deneyim', 'Sınırsız OCR işlemi', 'Öncelikli destek'],
                onTap: () => _purchaseSubscription('pro_monthly_subscription'),
                isFirst: true,
              ),
              _buildDivider(isDark),
              _buildSubscriptionOption(
                isDark: isDark,
                title: '🔥 Pro Yıllık',
                subtitle: '₺299.99/yıl - 2 ay ücretsiz!',
                features: ['Reklamsız deneyim', 'Sınırsız OCR işlemi', 'Öncelikli destek', '2 ay bedava'],
                onTap: () => _purchaseSubscription('pro_yearly_subscription'),
              ),
              _buildDivider(isDark),
              _buildSubscriptionOption(
                isDark: isDark,
                title: '💎 Premium Aylık',
                subtitle: '₺49.99/ay - Tüm özellikler',
                features: ['Tüm Pro özellikler', 'Toplu işleme', 'API erişimi', 'Öncelik desteği'],
                onTap: () => _purchaseSubscription('premium_monthly_subscription'),
              ),
              _buildDivider(isDark),
              _buildSubscriptionOption(
                isDark: isDark,
                title: '👑 Premium Yıllık',
                subtitle: '₺499.99/yıl - En iyi değer!',
                features: ['Tüm Pro özellikler', 'Toplu işleme', 'API erişimi', 'Öncelik desteği', '2 ay bedava'],
                onTap: () => _purchaseSubscription('premium_yearly_subscription'),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildRestorePurchasesButton(isDark),
      ],
    );
    }

  Widget _buildSubscriptionOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required List<String> features,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: features.map((feature) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestorePurchasesButton(bool isDark) {
    return Container(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: _restorePurchases,
        padding: EdgeInsets.zero,
        child: Text(
          'Satın Alımları Geri Yükle',
          style: TextStyle(
            color: const Color(0xFF007AFF),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseSubscription(String productId) async {
    try {
      final subscriptionManager = SubscriptionManager.instance;
      
      if (!subscriptionManager.isInitialized) {
        _showMessage('Abonelik sistemi henüz hazır değil. Lütfen tekrar deneyin.');
        return;
      }

      if (!subscriptionManager.isAvailable) {
        _showMessage('Bu cihazda satın alma mevcut değil.');
        return;
      }

      _showMessage('Satın alma işlemi başlatılıyor...');
      
      final success = await subscriptionManager.purchaseSubscription(productId);
      
      if (success) {
        _showMessage('Satın alma işlemi başarıyla başlatıldı.');
      } else {
        _showMessage('Satın alma işlemi başlatılamadı.');
      }
    } catch (e) {
      _showMessage('Hata: $e');
    }
  }

  Future<void> _restorePurchases() async {
    try {
      _showMessage('Satın alımlar geri yükleniyor...');
      
      final subscriptionManager = SubscriptionManager.instance;
      await subscriptionManager.initialize(); // This includes restoring purchases
      
      _showMessage('Satın alımlar kontrol edildi.');
      
      // Refresh credit info to reflect any restored subscriptions
      if (widget.onCreditsChanged != null) {
        widget.onCreditsChanged!();
      }
    } catch (e) {
      _showMessage('Geri yükleme sırasında hata: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreditPurchaseDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(context.l10n.buyCredits),
        message: Text(context.l10n.selectCreditPackage),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _purchaseCredits(50);
            },
            child: Text(context.l10n.buy50Credits),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _purchaseCredits(100);
            },
            child: Text(context.l10n.buy100Credits),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _purchaseCredits(250);
            },
            child: Text(context.l10n.buy250Credits),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ),
    );
  }

  void _purchaseCredits(int amount) {
    // Mock purchase implementation
    final creditManager = Provider.of<CreditManager>(context, listen: false);
    creditManager.addCredits(amount);
    widget.onCreditsChanged?.call();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$amount ${context.l10n.creditsAddedSuccess}'),
        backgroundColor: const Color(0xFF34C759),
      ),
    );
  }



  Widget _buildOCRHistorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF8E44AD).withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.time_solid,
                color: Color(0xFF8E44AD),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.ocrHistoryTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(context); // Close settings first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OCRHistoryScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E44AD).withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.clock_fill,
                        color: Color(0xFF8E44AD),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.viewOcrHistory,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.viewOcrHistorySubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
