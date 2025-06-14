import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authgate.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/sign_in.dart';
import 'package:flutter_application_1/screens/nearby_center_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/recent_screen.dart';
import 'package:flutter_application_1/screens/sign_up.dart';
import 'package:flutter_application_1/screens/stats_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:flutter/services.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Show system UI overlays (status bar + navigation bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Optional: Set status bar color and brightness
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make it transparent or set a color
      statusBarIconBrightness:
          Brightness.dark, // or Brightness.light depending on background
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'waste classifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //initialRoute: '/',
      initialRoute: user != null ? '/classifier' : '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const SignInScreen(),
        '/signup': (context) => const SignupScreen(),
        '/classifier': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/recent': (context) => const RecentScreen(),
        '/stats': (context) => const StatsScreen(),
        '/recycling-centers': (context) => const NearbyCentersScreen(),
      },
    );
  }
}
