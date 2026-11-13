// lib/main.dart
import 'package:flutter/material.dart';
import 'api_key.dart';
import 'home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasKey = geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('PASTE');
    return MaterialApp(
      title: 'My A2UI App',
      debugShowCheckedModeBanner: false, // The DEBUG banner would cover the app bar's buttons.
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: hasKey
          ? const HomePage(title: 'My A2UI App')
          : const Scaffold(body: Center(child: Text('Paste your Gemini API key into lib/api_key.dart, then restart the app.'))),
    );
  }
}
