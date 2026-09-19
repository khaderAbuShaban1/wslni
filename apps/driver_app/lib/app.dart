part of 'main.dart';

class DriverRideApp extends StatelessWidget {
  const DriverRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wslni Driver',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: theme.colorScheme.surface,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.colorScheme.surface,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: _buildDriverTheme(),
      darkTheme: _buildDriverTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthPage(),
    );
  }
}
