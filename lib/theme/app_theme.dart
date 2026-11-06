import 'package:flutter/material.dart';

/// SpendWise's visual tokens. There are no additional font or UI dependencies.
class SpendColors {
  static const teal = Color(0xFF087E73);
  static const darkTeal = Color(0xFF075B55);
  static const deep = Color(0xFF0D3733);
  static const mint = Color(0xFFA8EBDD);
  static const green = Color(0xFF16865D);
  static const orange = Color(0xFFE67B43);
  static const red = Color(0xFFD35B55);
  static const ink = Color(0xFF19332F);
  static const lightBackground = Color(0xFFF5F8F7);
  static const darkBackground = Color(0xFF0E1B1A);
  static const darkSurface = Color(0xFF192725);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? SpendColors.darkSurface : Colors.white;
    final stroke = dark ? const Color(0xFF2C403B) : const Color(0xFFE4EEEA);
    final scheme = ColorScheme.fromSeed(
      seedColor: SpendColors.teal,
      brightness: brightness,
    ).copyWith(
      primary: dark ? SpendColors.mint : SpendColors.teal,
      onPrimary: dark ? SpendColors.deep : Colors.white,
      surface: surface,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? SpendColors.darkBackground
          : SpendColors.lightBackground,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -0.7,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800, letterSpacing: -0.3,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: dark
            ? SpendColors.darkBackground
            : SpendColors.lightBackground,
        foregroundColor: dark ? Colors.white : SpendColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 66,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: dark ? Colors.white : SpendColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: stroke),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark ? const Color(0xFF28574B) : const Color(0xFFD6F0E7),
        elevation: 0,
        height: 77,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: dark ? Colors.white : SpendColors.ink),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: dark ? const Color(0xFF28574B) : const Color(0xFFD6F0E7),
        selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedColor: dark ? const Color(0xFF28574B) : const Color(0xFFD8F3EA),
      ),
      dividerTheme: DividerThemeData(color: stroke),
    );
  }
}
