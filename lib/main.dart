import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

// Concept: entry point of every Flutter app
void main() {
  // App khulte hi soye hue server ko jaga do (fire-and-forget).
  // Jab tak user login screen dekhta/type karta hai, server ready ho jaata hai.
  ApiService.wakeUpServer();
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Concept: FutureBuilder - decides start screen based on saved login token
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  // Concept: reading a previously saved value from device storage
  Future<String?> _getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSavedToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return DashboardScreen(token: token);
        }
        return const LoginScreen();
      },
    );
  }
}
