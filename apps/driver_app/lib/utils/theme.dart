part of '../main.dart';

ThemeData _buildDriverTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _emerald,
    brightness: brightness,
    primary: dark ? const Color(0xFF5EE9B5) : _emerald,
    secondary: dark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
    tertiary: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
    surface: dark ? const Color(0xFF111827) : Colors.white,
  );
  final text = ThemeData(brightness: brightness).textTheme
      .apply(
        fontFamily: 'Noto Sans Arabic',
        fontFamilyFallback: const ['Segoe UI', 'Tahoma', 'Arial'],
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      )
      .copyWith(
        headlineLarge: const TextStyle(
          fontSize: 30,
          height: 1.3,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: const TextStyle(
          fontSize: 26,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          height: 1.4,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.65,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: const TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      );
  final outline = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  final field = dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Noto Sans Arabic',
    fontFamilyFallback: const ['Segoe UI', 'Tahoma', 'Arial'],
    textTheme: text,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0B1120)
        : const Color(0xFFF6F8FB),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 17, 18, 17),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: field,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: outline),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: text.labelMedium,
    ),
    dialogTheme: DialogThemeData(
      elevation: 24,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      modalBackgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      backgroundColor: dark ? const Color(0xFFE2E8F0) : const Color(0xFF172033),
      contentTextStyle: text.bodyMedium?.copyWith(
        color: dark ? const Color(0xFF172033) : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _DriverPageTransitionBuilder(),
        TargetPlatform.iOS: _DriverPageTransitionBuilder(),
      },
    ),
  );
}

class _DriverPageTransitionBuilder extends PageTransitionsBuilder {
  const _DriverPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(-.025, .015),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }
}
