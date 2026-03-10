import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_page.dart';  
import 'screens/auth/signup_page.dart'; 
import 'screens/auth/auth_wrapper.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init failed: $e");
  }

  runApp(const SkillTrackerApp());
}

class SkillTrackerApp extends StatelessWidget {
  const SkillTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Skill Tracker',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        // remove initialRoute so home takes precedence
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/dashboard': (context) => const DashboardPage(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}
