import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

part 'app.dart';
part 'models/driver_user.dart';
part 'models/ride_request_item.dart';
part 'screens/active_ride_page.dart';
part 'screens/auth_page.dart';
part 'screens/driver_home_page.dart';
part 'screens/earnings_page.dart';
part 'screens/profile_screen.dart';
part 'screens/requests_page.dart';
part 'screens/trips_page.dart';
part 'services/api_client.dart';
part 'services/realtime_driver_service.dart';
part 'utils/constants.dart';
part 'utils/firebase_runtime.dart';
part 'utils/theme.dart';
part 'widgets/empty_state_card.dart';
part 'widgets/ride_request_card.dart';
part 'widgets/skeleton_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseRuntime.initialize();
  runApp(const DriverRideApp());
}
