import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/provider/provider.dart';
import 'package:flutter_application_1/routes/app_route.dart';
import 'package:flutter_application_1/user_screen/request_pickup.dart';
import 'package:flutter_application_1/waste_collector/collector_signup.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
//import 'routes/app_routes.dart';
import 'service/welcome_screen.dart';
import 'user_screen/home_screen.dart';
import 'user_screen/sign_in.dart';
import 'user_screen/sign_up.dart';
import 'user_screen/profile_screen.dart';
import 'user_screen/recent_screen.dart';
import 'user_screen/stats_screen.dart';
import 'user_screen/nearby_center_screen.dart';
import 'service/role_selection.dart';
import 'waste_collector/collector_homepage.dart';
import 'waste_collector/pickup.dart';
import 'waste_collector/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waste Classifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: user != null ? AppRoutes.home : AppRoutes.welcome,
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        switch (settings.name) {
          case AppRoutes.welcome:
            return _createRoute(const WelcomeScreen());

          case AppRoutes.signIn:
            return _createRoute(const SignInScreen());

          case AppRoutes.signUp:
            final role = args['role'] ?? 'user';
            return _createRoute(SignUpScreen(role: role));
          case AppRoutes.collectorSignup:
            final role = args['role'] ?? 'collector';
            return _createRoute(CollectorSignup(role: role));

          case AppRoutes.roleSelection:
            return _createRoute(const RoleSelectionScreen());

          case AppRoutes.home:
            return _createRoute(const HomeScreen());

          case AppRoutes.profile:
            return _createRoute(const ProfileScreen());

          case AppRoutes.recent:
            return _createRoute(const RecentScreen());

          case AppRoutes.stats:
            return _createRoute(const StatsScreen());

          case AppRoutes.recyclingCenters:
            return _createRoute(const NearbyCentersScreen());

          case AppRoutes.collectorHome:
            return _createRoute(const CollectorMainScreen());

          case AppRoutes.pickup:
            return _createRoute(const PickupManagementPage());

          case AppRoutes.collectorProfile:
            return _createRoute(const CollectorProfileScreen());
          case AppRoutes.requestpickup:
            return _createRoute(const WastePickupForm());

          default:
            return _createRoute(
              Scaffold(
                appBar: AppBar(title: const Text('404')),
                body: const Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }

  // Custom page transition
  static PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
