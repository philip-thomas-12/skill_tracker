import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_page.dart';  
import 'screens/auth/signup_page.dart'; 
import 'screens/auth/auth_wrapper.dart';
import 'screens/dashboard/dashboard_page.dart';
// import 'firebase_options.dart'; // User needs to provide this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Uncomment this when user adds firebase_options.dart or google-services.json
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // For now, we will try to init, but catch error if config is missing to avoid crash during dev
  try {
     await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init failed (expected if no config): $e");
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
