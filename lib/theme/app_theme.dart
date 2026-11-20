import 'package:material_ui/material_ui.dart';

/// FocusForge look: a warm deep-orange seed, Material 3, light and dark.
/// Focus phases read orange; breaks read teal so the state is obvious
/// at a glance.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFFEF6C00);
  static const Color breakSeed = Color(0xFF00838F);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
    );
  }

  /// Accent for the current phase: orange while focusing, teal on breaks.
  static Color phaseColor(bool isFocus, Brightness brightness) {
    if (isFocus) return seed;
    return brightness == Brightness.dark
        ? const Color(0xFF4DD0E1)
        : breakSeed;
  }
}
