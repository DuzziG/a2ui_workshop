// lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'home_page.dart';

// Your App Check debug token, from the Firebase console:
// App Check > Apps > ⋮ next to your app > Manage debug tokens > Add debug token.
// Keep it private: anyone who has it can use your Gemini quota.
const appCheckDebugToken = 'PASTE-YOUR-DEBUG-TOKEN-HERE';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // App Check proves that requests to Gemini come from your app.
  // While you develop, the debug providers use your debug token.
  await FirebaseAppCheck.instance.activate(
    providerWeb: WebDebugProvider(debugToken: appCheckDebugToken),
    providerAndroid: const AndroidDebugProvider(debugToken: appCheckDebugToken),
    providerApple: const AppleDebugProvider(debugToken: appCheckDebugToken),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My A2UI App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomePage(title: 'My A2UI App'),
    );
  }
}
