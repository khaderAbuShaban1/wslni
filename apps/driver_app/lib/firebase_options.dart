import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRs-Z8vvQOkhpMP81XmUAXTrgSHRpx76o',
    appId: '1:507815627313:android:752fec5a724f48ddfce310',
    messagingSenderId: '507815627313',
    projectId: 'wslni-527a2',
    databaseURL: 'https://wslni-527a2-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'wslni-527a2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQ8EdN8SOlxBzPedZC4UGbvf1a-sElDBs',
    appId: '1:507815627313:ios:891e2c30d4fd3975fce310',
    messagingSenderId: '507815627313',
    projectId: 'wslni-527a2',
    databaseURL: 'https://wslni-527a2-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'wslni-527a2.firebasestorage.app',
    iosBundleId: 'com.wslni.driver',
  );
}
