import 'package:flutter/material.dart';
import 'login_screen.dart';

// Concept: entry point of every Flutter app
void main() {
  runApp(const MyApp());
}

// Concept: StatelessWidget - root widget, doesn't change
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Concept: MaterialApp - wraps whole app, gives theme/navigation
    return MaterialApp(
      title: 'Resume App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Concept: home - first screen shown when app opens
      home: const LoginScreen(),
    );
  }
}