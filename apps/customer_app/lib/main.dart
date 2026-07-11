import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'utils/firebase_runtime.dart';
import 'utils/theme_mode_controller.dart';
export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemeMode();
  await FirebaseRuntime.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CustomerRideApp());
}
