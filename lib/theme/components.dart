import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'animations.dart';
import 'theme_provider.dart';

/// Lensify OCR Scanner için modern UI bileşenleri
class AppComponents {
  
  /// Modern gradient button
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    double height = 56,
    Gradient? gradient,
    bool enabled = true,
  }) {
    return AnimatedHoverCard(
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled 
                ? (gradient ?? AppTheme.primaryGradient)
                : const LinearGradient(
                    colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
                  ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              alignment: Alignment.center,
              child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
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
      ),
    );
  }

  /// Modern outline button
  static Widget outlineButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    double height = 56,
    Color? borderColor,
    Color? textColor,
    bool enabled = true,
  }) {
    return AnimatedHoverCard(
      child: SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: enabled
                ? (borderColor ?? AppTheme.primaryColor)
                : const Color(0xFFE2E8F0),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    borderColor ?? AppTheme.primaryColor,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: enabled
                        ? (textColor ?? AppTheme.primaryColor)
                        : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: enabled
                        ? (textColor ?? AppTheme.primaryColor)
                        : const Color(0xFF94A3B8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  /// Glass morphism card
  static Widget glassCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double borderRadius = 16,
    double blur = 10,
    double opacity = 0.1,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  /// Modern text field
  static Widget textField({
    required BuildContext context,
    required String label,
    String? hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    int? maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode 
              ? Colors.white.withValues(alpha: 0.9)
              : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                                 color: context.isDarkMode 
                   ? Colors.white.withValues(alpha: 0.3) 
                   : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            filled: true,
                         fillColor: enabled 
               ? (context.isDarkMode 
                 ? Colors.white.withValues(alpha: 0.05) 
                 : Colors.white)
               : (context.isDarkMode 
                 ? Colors.white.withValues(alpha: 0.02) 
                 : const Color(0xFFF8FAFC)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Modern dialog
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: AppAnimations.medium,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            width: width ?? MediaQuery.of(context).size.width * 0.9,
            height: height,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.scaleIn,
            )),
            child: child,
          ),
        );
      },
    );
  }

  /// Modern bottom sheet
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Modern chip
  static Widget chip({
    required BuildContext context,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
    IconData? icon,
    Color? selectedColor,
    Color? unselectedColor,
    Color? textColor,
    double? fontSize,
  }) {
    final isDark = context.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
            ? (selectedColor ?? AppTheme.primaryColor.withValues(alpha: 0.1))
            : (unselectedColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9))),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
              ? (selectedColor ?? AppTheme.primaryColor)
              : (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                  ? (textColor ?? AppTheme.primaryColor)
                  : (isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w500,
                color: selected
                  ? (textColor ?? AppTheme.primaryColor)
                  : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern toggle switch
  static Widget toggleSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? label,
    Color? activeColor,
    bool enabled = true,
  }) {
    final isDark = context.isDarkMode;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: enabled
                ? (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151))
                : (isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        GestureDetector(
          onTap: enabled ? () => onChanged(!value) : null,
          child: Container(
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              color: value
                  ? (activeColor ?? AppTheme.primaryColor)
                  : (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: AppAnimations.fast,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
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

  /// Modern progress indicator
  static Widget progressIndicator({
    required BuildContext context,
    required double value,
    String? label,
    Color? color,
    Color? backgroundColor,
    double height = 8,
    bool showPercentage = false,
  }) {
    final isDark = context.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B),
                  ),
                ),
              if (showPercentage)
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color ?? AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Modern selection tile
  static Widget selectionTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    bool selected = false,
    VoidCallback? onTap,
    IconData? leadingIcon,
    Widget? trailing,
    Color? selectedColor,
    Color? unselectedColor,
  }) {
    final isDark = context.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                color: selected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B)),
                size: 24,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937)),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ] else if (selected) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 