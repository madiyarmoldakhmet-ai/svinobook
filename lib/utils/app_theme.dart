import 'dart:ui';
import 'package:flutter/material.dart';

/// Shared visual tokens for Svinobook's messaging surfaces.

class AppColors {
  AppColors._();

  // ── DESIGN.md surfaces ──
  static const bgDarkest = Color(0xFFF4EDE4);
  static const bgDark = Color(0xFFF9F0FF);
  static const bgMid = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFF9F0FF);

  // ── Aubergine primary ──
  static const primary = Color(0xFF4A154B);
  static const primaryDeep = Color(0xFF481A54);
  static const primaryPress = Color(0xFF611F69);
  static const primaryTint = Color(0xFF592466);
  static const neonCyan = primary;
  static const neonBlue = primaryTint;
  static const neonPurple = primaryTint;
  static const neonGreen = Color(0xFF007A5A);

  // ── Glassmorphism ──
  static const glassBg = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFE6E6E6);
  static const glassHighlight = Color(0xFFF9F0FF);

  // ── Semantic ──
  static const textPrimary = Color(0xFF1D1D1D);
  static const textSecondary = Color(0xFF696969);
  static const textMuted = Color(0xFF696969);
  static const danger = Color(0xFFCC4117);
  static const success = Color(0xFF007A5A);

  // ── Gradients ──
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryTint, primary],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTint, primary],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9F0FF), Colors.white, Color(0xFFF4EDE4)],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Light theme for the entire app.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryTint,
      onSecondary: Colors.white,
      tertiary: AppColors.primaryDeep,
      surface: AppColors.bgMid,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    );

    const base = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Salesforce-Avant-Garde',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Salesforce-Avant-Garde',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Salesforce-Avant-Garde',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 22,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Salesforce-Sans',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 18,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Salesforce-Sans',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.55,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Salesforce-Sans',
        fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.38,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDarkest,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Salesforce-Avant-Garde',
          fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.bgDarkest,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(90),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Salesforce-Sans',
            fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Salesforce-Sans',
            fontFamilyFallback: ['system-ui', '-apple-system', 'sans-serif'],
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}

/// A reusable flat panel used throughout the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 12,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius > 3 ? 4 : borderRadius);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppColors.glassBg,
              borderRadius: br,
              border:
                  border ?? Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow:
                  boxShadow ??
                  const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A gradient avatar with the first letter of a name.
class GradientAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final ImageProvider? backgroundImage;
  final List<Color>? gradientColors;

  const GradientAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.backgroundImage,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppColors.primaryGradient.colors;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundImage == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        image: backgroundImage != null
            ? DecorationImage(image: backgroundImage!, fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: backgroundImage == null
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.8,
                ),
              ),
            )
          : null,
    );
  }
}
