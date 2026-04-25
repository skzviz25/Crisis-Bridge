import 'package:crisis_bridge/app.dart';
import 'package:crisis_bridge/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*if (kDebugMode) {
    // ✅ Replace with YOUR PC's IPv4 from ipconfig
    const emulatorHost = '10.250.15.1'; // ← YOUR PC IP HERE

    try {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      debugPrint('✅ Connected to Firebase emulators at $emulatorHost');
    } catch (e) {
      debugPrint('⚠ Emulator connection failed: $e');
    }
  }*/


  runApp(const CrisisBridgeApp());
}