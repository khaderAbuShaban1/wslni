part of 'main.dart';

class DriverRideApp extends StatelessWidget {
  const DriverRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وصلني للسائق',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: _buildDriverTheme(),
      darkTheme: _buildDriverTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthPage(),
    );
  }
}
