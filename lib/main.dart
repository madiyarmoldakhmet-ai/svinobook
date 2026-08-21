import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/system_health_service.dart';
import 'views/auth_screen.dart';
import 'views/home_screen.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: const SvinobookApp(),
    ),
  );
}

class SvinobookApp extends StatelessWidget {
  const SvinobookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svinobook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}