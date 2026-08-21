import 'dart:ui';
import 'package:flutter/material.dart';

/// Svinobook's compact early-social-network visual system.

class AppColors {
  AppColors._();

  // ── VK-era blue and gray surfaces ──
  static const bgDarkest = Color(0xFFE7EEF5);
  static const bgDark = Color(0xFFD7E3EE);
  static const bgMid = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFF3F6F9);

  // ── Classic interface blue ──
  static const neonCyan = Color(0xFF4A76A8);
  static const neonBlue = Color(0xFF527DA8);
  static const neonPurple = Color(0xFF527DA8);
  static const neonGreen = Color(0xFF4D9B6A);

  // ── Glassmorphism ──
  static const glassBg = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFC7D5E0);
  static const glassHighlight = Color(0xFFF8FAFC);

  // ── Semantic ──
  static const textPrimary = Color(0xFF2B4053);
  static const textSecondary = Color(0xFF607D94);
  static const textMuted = Color(0xFF91A4B4);
  static const danger = Color(0xFFD45B5B);
  static const success = Color(0xFF4D9B6A);

  // ── Gradients ──
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5C89B5), Color(0xFF426C9A)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C89B5), Color(0xFF426C9A)],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDDE9F3), Color(0xFFF7F9FB), Color(0xFFE2ECF4)],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Compact light theme for the entire app.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const scheme = ColorScheme.light(
      primary: AppColors.neonCyan,
      onPrimary: Colors.white,
      secondary: AppColors.neonBlue,
      onSecondary: Colors.white,
      tertiary: AppColors.neonPurple,
      surface: AppColors.bgMid,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    );

    const base = TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, height: 1.35),
        bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.35),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      );

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDarkest,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          borderSide: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
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
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neonCyan,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.neonCyan),
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.neonCyan,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
              border: border ??
                  Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: boxShadow ?? const [
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