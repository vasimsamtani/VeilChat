import 'package:flutter/material.dart';

class VeilTheme {
  // Official Stitch Liquid Glass Palette Tokens
  static const Color background = Color(0xFF111319);
  static const Color backgroundDeep = Color(0xFF0C0E14);
  static const Color surface = Color(0xFF111319);
  static const Color surfaceDim = Color(0xFF111319);
  static const Color surfaceBright = Color(0xFF373940);
  static const Color surfaceContainerLowest = Color(0xFF0C0E14);
  static const Color surfaceContainerLow = Color(0xFF191B22);
  static const Color surfaceContainer = Color(0xFF1E1F26);
  static const Color surfaceContainerHigh = Color(0xFF282A30);
  static const Color surfaceContainerHighest = Color(0xFF33343B);

  // Aliases for compatibility
  static const Color surfaceDark = surface;
  static const Color surfaceCard = surfaceContainer;
  static const Color surfaceBorder = Color(0xFF282A30);
  static const Color surfaceBorderBright = Color(0xFF494454);

  // Stitch Primary Violet Tokens
  static const Color primary = Color(0xFFD0BCFF);
  static const Color primaryContainer = Color(0xFFA078FF);
  static const Color onPrimary = Color(0xFF3C0091);
  static const Color onPrimaryContainer = Color(0xFF340080);
  static const Color inversePrimary = Color(0xFF6D3BD7);
  static const Color primaryViolet = primary;

  // Stitch Secondary Cyan Tokens
  static const Color secondary = Color(0xFF4CD7F6);
  static const Color secondaryContainer = Color(0xFF03B5D3);
  static const Color onSecondary = Color(0xFF003640);
  static const Color onSecondaryContainer = Color(0xFF00424E);
  static const Color cyberCyan = secondary;

  // Stitch Tertiary Emerald Tokens (Tactical Enclave / Armed Shield)
  static const Color tertiary = Color(0xFF4EDEA3);
  static const Color tertiaryContainer = Color(0xFF00A572);
  static const Color onTertiary = Color(0xFF003824);
  static const Color emeraldNeon = tertiary;

  // Stitch Locked Amber & Error Tokens
  static const Color lockedAmber = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color errorRed = error;

  // Text & Outline Tokens
  static const Color onSurface = Color(0xFFE2E2EB);
  static const Color onSurfaceVariant = Color(0xFFCBC3D7);
  static const Color outline = Color(0xFF958EA0);
  static const Color outlineVariant = Color(0xFF494454);
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textDim = outline;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryContainer, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidGlassAura = LinearGradient(
    colors: [
      Color(0x33A078FF),
      Color(0x1A4CD7F6),
      Color(0x000C0E14),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      canvasColor: surfaceContainerLow,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        error: error,
        errorContainer: errorContainer,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
    );
  }
}
