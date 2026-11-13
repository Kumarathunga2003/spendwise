import 'package:material_ui/material_ui.dart';

/// SpendWise's visual tokens. There are no additional font or UI dependencies.
class SpendColors {
  static const teal = Color(0xFF0B8B7E);
  static const darkTeal = Color(0xFF07635B);
  static const deep = Color(0xFF103D38);
  static const mint = Color(0xFF9FE7D8);
  static const green = Color(0xFF16865D);
  static const orange = Color(0xFFEF9862);
  static const red = Color(0xFFD35B55);
  static const ink = Color(0xFF19332F);
  static const lightBackground = Color(0xFFF4F8F6);
  static const darkBackground = Color(0xFF0D1918);
  static const darkSurface = Color(0xFF192A27);
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
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Explicit typography avoids following unusual manufacturer fonts.
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      scaffoldBackgroundColor:
          dark ? SpendColors.darkBackground : SpendColors.lightBackground,
      textTheme: base.textTheme.apply(fontFamily: 'Roboto').copyWith(
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.45,
              letterSpacing: 0,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 12.5,
              height: 1.4,
              letterSpacing: 0,
            ),
            labelSmall: base.textTheme.labelSmall?.copyWith(
              fontFamily: 'Roboto',
              letterSpacing: 0.1,
            ),
          ),
      appBarTheme: AppBarThemeData(
        backgroundColor:
            dark ? SpendColors.darkBackground : SpendColors.lightBackground,
        foregroundColor: dark ? Colors.white : SpendColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 58,
        titleTextStyle: TextStyle(
          fontSize: 20,
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
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(color: stroke),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor:
            dark ? const Color(0xFF28574B) : const Color(0xFFD6F0E7),
        elevation: 0,
        height: 69,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              fontSize: 11,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : SpendColors.ink),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor:
            dark ? const Color(0xFF28574B) : const Color(0xFFD6F0E7),
        selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedColor: dark ? const Color(0xFF28574B) : const Color(0xFFD8F3EA),
      ),
      dividerTheme: DividerThemeData(color: stroke),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
