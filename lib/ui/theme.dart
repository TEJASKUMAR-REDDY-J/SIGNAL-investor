
import 'package:flutter/material.dart';

import '../db/open_db.dart';

const _seed = Color(0xFF14A37F);

/// App-wide theme mode, persisted (layout preference only, not financial data).
final themeMode = ValueNotifier(ThemeMode.system);

Future<void> loadThemeMode() async {
  final v = await storage.read(key: 'theme_mode');
  themeMode.value = ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
}

Future<void> setThemeMode(ThemeMode m) async {
  themeMode.value = m;
  await storage.write(key: 'theme_mode', value: m.name);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  var cs = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  if (dark) {
    // Deep, low-glare neutrals with a hint of green; OLED-friendly.
    cs = cs.copyWith(
      surface: const Color(0xFF0B0F0E),
      surfaceContainerLowest: const Color(0xFF080B0A),
      surfaceContainerLow: const Color(0xFF101614),
      surfaceContainer: const Color(0xFF141B19),
      surfaceContainerHigh: const Color(0xFF1A2220),
      surfaceContainerHighest: const Color(0xFF212B28),
      outlineVariant: const Color(0xFF2A3532),
    );
  }
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? cs.surfaceContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: dark ? 0.6 : 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: dark ? cs.surfaceContainerLow : cs.surfaceContainer,
      indicatorColor: cs.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52), shape: shape,
          textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: shape),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? cs.surfaceContainerLow : cs.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(backgroundColor: dark ? cs.surfaceContainerHigh : cs.surface),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    }),
  );
}

/// Figures line up in columns.
const tabular = [FontFeature.tabularFigures()];

extension AppColors on ColorScheme {
  bool get isDark => brightness == Brightness.dark;
  Color get gain => isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  Color get loss => isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
  Color get warn => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
  Color signed(int v) => v > 0 ? gain : (v < 0 ? loss : onSurfaceVariant);

  /// Categorical series colours that hold up in both themes.
  List<Color> get series => isDark
      ? const [Color(0xFF34D399), Color(0xFF60A5FA), Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA), Color(0xFF94A3B8)]
      : const [Color(0xFF059669), Color(0xFF2563EB), Color(0xFFD97706), Color(0xFFDB2777), Color(0xFF7C3AED), Color(0xFF64748B)];
}

Color avatarColor(String seed) {
  const c = [Color(0xFF14A37F), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF06B6D4)];
  return c[seed.codeUnits.fold(0, (a, b) => a + b) % c.length];
}
