import 'package:flutter/material.dart';

import 'constants.dart';

const _fontFamily = 'Noto Sans Arabic';
const _fontFallback = <String>['Segoe UI', 'Tahoma', 'Arial'];

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final generatedScheme = ColorScheme.fromSeed(
    seedColor: emerald,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    primary: isDark ? const Color(0xFFF3C455) : emerald,
    secondary: isDark ? const Color(0xFFF4F4F6) : const Color(0xFF111214),
    tertiary: isDark ? const Color(0xFFA9B8CC) : const Color(0xFF30343A),
    error: isDark ? const Color(0xFFFFB4AB) : errorColor,
    surface: isDark ? const Color(0xFF151618) : const Color(0xFFFFFFFF),
  );
  final scheme = isDark
      ? generatedScheme.copyWith(
          primary: const Color(0xFFF3C455),
          onPrimary: const Color(0xFF211A00),
          primaryContainer: const Color(0xFF493A12),
          onPrimaryContainer: const Color(0xFFFFE8A6),
          secondary: const Color(0xFFF0F0F2),
          onSecondary: const Color(0xFF1B1B1D),
          secondaryContainer: const Color(0xFF2B2C30),
          onSecondaryContainer: const Color(0xFFE8E8EB),
          tertiary: const Color(0xFFAEB8C8),
          onTertiary: const Color(0xFF17202B),
          error: const Color(0xFFFFB4AB),
          onError: const Color(0xFF690005),
          surface: const Color(0xFF24262C),
          onSurface: const Color(0xFFF5F5F6),
          surfaceContainerLowest: const Color(0xFF17191E),
          surfaceContainerLow: const Color(0xFF292B32),
          surfaceContainer: const Color(0xFF2E3038),
          surfaceContainerHigh: const Color(0xFF353841),
          surfaceContainerHighest: const Color(0xFF3D404A),
          onSurfaceVariant: const Color(0xFFC3C6CE),
          outline: const Color(0xFF5A5D67),
          outlineVariant: const Color(0xFF41444D),
        )
      : generatedScheme;
  final textTheme = ThemeData(brightness: brightness).textTheme
      .apply(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      )
      .copyWith(
        displaySmall: const TextStyle(
          fontSize: 34,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
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
  final outline = isDark ? const Color(0xFF41444D) : borderGray;
  final fieldColor = isDark ? const Color(0xFF2D3037) : const Color(0xFFF5F5F7);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFallback,
    textTheme: textTheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF1A1C21)
        : const Color(0xFFFAFAFB),
    canvasColor: isDark ? const Color(0xFF1A1C21) : const Color(0xFFFAFAFB),
    shadowColor: isDark ? const Color(0xFF090A0C) : const Color(0xFF67635B),
    dividerTheme: DividerThemeData(
      color: outline.withValues(alpha: .8),
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: isDark ? 2 : 3,
      shadowColor: isDark ? const Color(0x66090A0C) : const Color(0x2667635B),
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: outline.withValues(alpha: .72)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldColor,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 17, 18, 17),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: .75),
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      minTileHeight: 68,
      minLeadingWidth: 52,
      horizontalTitleGap: 14,
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 4,
      shadowColor: const Color(0x2467635B),
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
          size: states.contains(WidgetState.selected) ? 25 : 23,
        ),
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
      backgroundColor: fieldColor,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: outline),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: textTheme.labelMedium,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 7,
      focusElevation: 10,
      hoverElevation: 10,
      highlightElevation: 4,
      backgroundColor: isDark ? scheme.primary : scheme.secondary,
      foregroundColor: isDark ? scheme.onPrimary : scheme.onSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      largeSize: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: scheme.primary,
      dividerColor: Colors.transparent,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    dialogTheme: DialogThemeData(
      elevation: 30,
      shadowColor: const Color(0x66000000),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyLarge?.copyWith(
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
      backgroundColor: isDark
          ? const Color(0xFFF2F4F7)
          : const Color(0xFF101828),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: isDark ? const Color(0xFF101828) : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _PremiumPageTransitionBuilder(),
        TargetPlatform.iOS: _PremiumPageTransitionBuilder(),
      },
    ),
  );
}

class _PremiumPageTransitionBuilder extends PageTransitionsBuilder {
  const _PremiumPageTransitionBuilder();

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
