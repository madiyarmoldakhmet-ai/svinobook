import 'dart:ui';
import 'package:flutter/material.dart';

/// Shared visual tokens for Svinobook's messaging surfaces.

class AppColors {
  AppColors._();

  // ── DESIGN.md surfaces ──
  static const canvas = Color(0xFFFAF9F5);
  static const surfaceSoft = Color(0xFFF5F0E8);
  static const surfaceCard = Color(0xFFEFE9DE);
  static const surfaceCreamStrong = Color(0xFFE8E0D2);
  static const surfaceDark = Color(0xFF181715);
  static const surfaceDarkElevated = Color(0xFF252320);
  static const surfaceDarkSoft = Color(0xFF1F1E1B);
  static const bgDarkest = canvas;
  static const bgDark = surfaceSoft;
  static const bgMid = canvas;
  static const bgLight = surfaceSoft;

  // ── Warm coral primary ──
  static const primary = Color(0xFFCC785C);
  static const primaryActive = Color(0xFFA9583E);
  static const primaryDisabled = Color(0xFFE6DFD8);
  static const primaryDeep = Color(0xFF252523);
  static const primaryPress = primaryActive;
  static const primaryTint = Color(0xFFE8A55A);
  static const onDark = Color(0xFFFAF9F5);
  static const neonCyan = primary;
  static const neonBlue = primaryTint;
  static const neonPurple = primaryTint;
  static const neonGreen = Color(0xFF5DB8A6);

  // ── Glassmorphism ──
  static const glassBg = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFE6DFD8);
  static const glassHighlight = Color(0xFFEBE6DF);

  // ── Semantic ──
  static const textPrimary = Color(0xFF141413);
  static const textStrong = Color(0xFF252523);
  static const textSecondary = Color(0xFF3D3D3A);
  static const textMuted = Color(0xFF6C6A64);
  static const textMutedSoft = Color(0xFF8E8B82);
  static const danger = Color(0xFFC64545);
  static const success = Color(0xFF5DB872);
  static const warning = Color(0xFFD4A017);

  // ── Gradients ──
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryActive],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryActive],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [canvas, surfaceSoft, canvas],
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
        fontFamily: 'Copernicus',
        fontFamilyFallback: ['Tiempos Headline', 'Cormorant Garamond', 'serif'],
        color: AppColors.textPrimary,
        fontSize: 48,
        height: 1.1,
        letterSpacing: -1,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Copernicus',
        fontFamilyFallback: ['Tiempos Headline', 'Cormorant Garamond', 'serif'],
        color: AppColors.textPrimary,
        fontSize: 36,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        fontFamily: 'StyreneB',
        fontFamilyFallback: ['Inter', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'StyreneB',
        fontFamilyFallback: ['Inter', 'sans-serif'],
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'StyreneB',
        fontFamilyFallback: ['Inter', 'sans-serif'],
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.55,
      ),
      labelLarge: TextStyle(
        fontFamily: 'StyreneB',
        fontFamilyFallback: ['Inter', 'sans-serif'],
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1,
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
          fontFamily: 'StyreneB',
          fontFamilyFallback: ['Inter', 'sans-serif'],
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'StyreneB',
            fontFamilyFallback: ['Inter', 'sans-serif'],
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
    final br = BorderRadius.circular(borderRadius);
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
