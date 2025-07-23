import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // you need to create this
import 'services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  await NotificationService.init();

  // Initialize Workmanager for background tasks
  Workmanager().initialize(
    NotificationService.callbackDispatcher,
    isInDebugMode: true, // set false for production
  );

  // Register periodic background task for notifications
  NotificationService.registerBackgroundTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: AuthWrapper(),
    );
  }
}

// Widget that listens to auth state and shows login or home accordingly
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in, show HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Else show LoginScreen
        return const LoginScreen();
      },
    );
  }
}
