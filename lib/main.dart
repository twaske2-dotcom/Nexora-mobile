import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'nexora_theme.dart';
import 'notification_service.dart';

// Concept: entry point of every Flutter app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.init();
  // Wake the sleeping server as soon as the app opens (fire-and-forget),
  // so it is ready by the time the user finishes the login screen.
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
      theme: NexoraTheme.dark,
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
