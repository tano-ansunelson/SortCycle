import 'package:firebase_app_check/firebase_app_check.dart'
    show FirebaseAppCheck, AndroidProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_application_1/chat_page/chat_page.dart';
import 'package:flutter_application_1/chat_page/chatlist_page.dart';
import 'package:flutter_application_1/ecomarketplace/homescreen.dart';
import 'package:flutter_application_1/provider/provider.dart';
import 'package:flutter_application_1/routes/app_route.dart';
import 'package:flutter_application_1/service/component/leaderboard.dart';
import 'package:flutter_application_1/user_screen/about_screen.dart';
import 'package:flutter_application_1/user_screen/edit_profile.dart';
import 'package:flutter_application_1/user_screen/sign_in_screen.dart';
import 'package:flutter_application_1/user_screen/userclassify.dart';
import 'package:flutter_application_1/user_screen/waste_form.dart';
import 'package:flutter_application_1/waste_collector/collectorMapScreen.dart';
import 'package:flutter_application_1/waste_collector/collector_about.dart';
import 'package:flutter_application_1/waste_collector/collector_signup.dart';
import 'package:flutter_application_1/waste_collector/editing_page.dart';
import 'package:flutter_application_1/waste_collector/collector_homepage.dart';
import 'package:flutter_application_1/waste_collector/pickup.dart';
import 'package:flutter_application_1/waste_collector/profile_screen.dart';
import 'package:flutter_application_1/service/welcome_screen.dart';
import 'package:flutter_application_1/user_screen/bottombar.dart';
import 'package:flutter_application_1/user_screen/sign_up.dart';
import 'package:flutter_application_1/user_screen/profile_screen.dart';
import 'package:flutter_application_1/service/role_selection.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔕 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CollectorProvider()),
        ChangeNotifierProvider(
          create: (_) => SortScoreProvider()..fetchSortScore(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget _initialScreen;

  @override
  void initState() {
    super.initState();
    _setupFCM();
    final user = FirebaseAuth.instance.currentUser;
    _initialScreen = user != null ? const HomeScreen() : const WelcomeScreen();
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted.');

      String? token = await messaging.getToken();
      print('🔑 FCM Token: $token');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (userDoc.exists) {
          // It's a normal user
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmToken': token,
          });
        } else {
          // Assume it's a collector
          await FirebaseFirestore.instance
              .collection('collectors')
              .doc(uid)
              .update({'fcmToken': token});
        }
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        '🔔 Foreground notification: ${message.notification?.title} - ${message.notification?.body}',
      );
      // You can use flutter_local_notifications here to show custom local popup if needed
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification');
      // Navigate to chat or pickup screen if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waste Classification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _initialScreen,
      onGenerateRoute: _generateRoute,
    );
  }

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

  Route<dynamic>? _generateRoute(RouteSettings settings) {
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
      case AppRoutes.leaderboard:
        return _createRoute(const LeaderboardScreen());
      case AppRoutes.profile:
        return _createRoute(const ProfileScreen());
      case AppRoutes.wastepickupformupdated:
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return _createRoute(WastePickupFormUpdated(userId: userId));
      case AppRoutes.chatpage:
        return _createRoute(
          ChatPage(
            collectorName: args['collectorName'],
            collectorId: args['collectorId'],
            requestId: args['requestId'],
          ),
        );
      case AppRoutes.collectorHome:
        return _createRoute(const CollectorMainScreen());
      case AppRoutes.pickup:
        final collectorId = args['collectorId'] as String?;
        if (collectorId != null) {
          return _createRoute(
            PickupManagementPage(collectorId: collectorId, collectorName: ''),
          );
        } else {
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('Collector ID is missing')),
            ),
          );
        }
      case AppRoutes.collectorProfile:
        return _createRoute(const CollectorProfileScreen());
      case AppRoutes.collectorProfileEditPage:
        return _createRoute(const CollectorProfileEditPage());
      case AppRoutes.userProfileEditPage:
        return _createRoute(const UserProfileEditPage());
      case AppRoutes.aboutus:
        return _createRoute(const AboutPage());
      case AppRoutes.markethomescreen:
        return _createRoute(const MarketHomeScreen());
      case AppRoutes.chatlistpage:
        return _createRoute(const ChatListPage());
      case AppRoutes.collectorabout:
        return _createRoute(const CollectorAboutPage());
      case AppRoutes.classifywaste:
        return _createRoute(const Classifywaste());
      case AppRoutes.collectormapscreen:
        final collectorId = args['collectorId'];
        return _createRoute(CollectorMapScreen(collectorId: collectorId));
      default:
        return _createRoute(
          Scaffold(
            appBar: AppBar(title: const Text('404')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

// import 'package:firebase_app_check/firebase_app_check.dart'
//     show FirebaseAppCheck, AndroidProvider;
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_application_1/chat_page/chat_page.dart';
// import 'package:flutter_application_1/chat_page/chatlist_page.dart';
// //import 'package:flutter_application_1/ecomarketplace/add_items.dart';
// import 'package:flutter_application_1/ecomarketplace/homescreen.dart';
// import 'package:flutter_application_1/provider/provider.dart';
// import 'package:flutter_application_1/routes/app_route.dart';
// import 'package:flutter_application_1/service/component/leaderboard.dart';
// import 'package:flutter_application_1/user_screen/about_screen.dart';
// import 'package:flutter_application_1/user_screen/edit_profile.dart';
// //import 'package:flutter_application_1/user_screen/recent_screen.dart';
// import 'package:flutter_application_1/user_screen/sign_in_screen.dart';
// import 'package:flutter_application_1/user_screen/userclassify.dart';
// import 'package:flutter_application_1/user_screen/waste_form.dart';
// import 'package:flutter_application_1/waste_collector/collectorMapScreen.dart';
// import 'package:flutter_application_1/waste_collector/collector_about.dart';
// import 'package:flutter_application_1/waste_collector/collector_signup.dart';
// import 'package:flutter_application_1/waste_collector/editing_page.dart';
// import 'package:provider/provider.dart';
// import 'firebase_options.dart';
// import 'service/welcome_screen.dart';
// import 'user_screen/bottombar.dart';
// import 'user_screen/sign_up.dart';
// import 'user_screen/profile_screen.dart';
// //import 'user_screen/stats_screen.dart';
// import 'service/role_selection.dart';
// import 'waste_collector/collector_homepage.dart';
// import 'waste_collector/pickup.dart';
// import 'waste_collector/profile_screen.dart';
// //import 'package:firebase_app_chec k /firebase_app_check.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // Activate App Check with debug provider
//   await FirebaseAppCheck.instance.activate(
//     androidProvider: AndroidProvider.debug,
//     //webRecaptchaSiteKey: 'your-web-key-if-any', // optional for web
//   );
//   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//     ),
//   );

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => CollectorProvider()),
//         ChangeNotifierProvider(
//           create: (_) => SortScoreProvider()..fetchSortScore(),
//         ),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late Widget _initialScreen;

//   @override
//   void initState() {
//     super.initState();
//     final user = FirebaseAuth.instance.currentUser;
//     _initialScreen = user != null ? const HomeScreen() : const WelcomeScreen();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Waste Classifier',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: _initialScreen,
//       onGenerateRoute: (settings) {
//         final args = settings.arguments as Map<String, dynamic>? ?? {};

//         switch (settings.name) {
//           case AppRoutes.welcome:
//             return _createRoute(const WelcomeScreen());
//           case AppRoutes.signIn:
//             return _createRoute(const SignInScreen());
//           case AppRoutes.signUp:
//             final role = args['role'] ?? 'user';
//             return _createRoute(SignUpScreen(role: role));
//           case AppRoutes.collectorSignup:
//             final role = args['role'] ?? 'collector';

//             return _createRoute(CollectorSignup(role: role));
//           case AppRoutes.roleSelection:
//             return _createRoute(const RoleSelectionScreen());
//           case AppRoutes.home:
//             return _createRoute(const HomeScreen());
//           case AppRoutes.leaderboard:
//             return _createRoute(const LeaderboardScreen());

//           case AppRoutes.profile:
//             return _createRoute(const ProfileScreen());
//           case AppRoutes.wastepickupformupdated:
//             // print('Navigating to WastePickupFormUpdated');
//             final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
//             return _createRoute(WastePickupFormUpdated(userId: userId));

//           case AppRoutes.chatpage:
//             final args = settings.arguments as Map<String, dynamic>;
//             return _createRoute(
//               ChatPage(
//                 collectorName: args['collectorName'],
//                 collectorId: args['collectorId'],
//                 requestId: args['requestId'],
//               ),
//             );
//           case AppRoutes.collectorHome:
//             return _createRoute(const CollectorMainScreen());
//           case AppRoutes.pickup:
//             final collectorId = args['collectorId'] as String?;
//             if (collectorId != null) {
//               return _createRoute(
//                 PickupManagementPage(
//                   collectorId: collectorId,
//                   collectorName: '',
//                 ),
//               );
//             } else {
//               return _createRoute(
//                 const Scaffold(
//                   body: Center(child: Text('Collector ID is missing')),
//                 ),
//               );
//             }
//           case AppRoutes.collectorProfile:
//             return _createRoute(const CollectorProfileScreen());
//           case AppRoutes.collectorProfileEditPage:
//             return _createRoute(const CollectorProfileEditPage());
//           case AppRoutes.userProfileEditPage:
//             return _createRoute(const UserProfileEditPage());
//           case AppRoutes.aboutus:
//             return _createRoute(const AboutPage());
//           case AppRoutes.markethomescreen:
//             return _createRoute(const MarketHomeScreen());
//           case AppRoutes.chatlistpage:
//             return _createRoute(const ChatListPage());
//           case AppRoutes.collectorabout:
//             return _createRoute(const CollectorAboutPage());
//           case AppRoutes.classifywaste:
//             return _createRoute(const Classifywaste());
//           case AppRoutes.collectormapscreen:
//             final collectorId = args['collectorId'];
//             return _createRoute(CollectorMapScreen(collectorId: collectorId));

//           // case AppRoutes.requestpickup:
//           //   final userId = args['userId'] as String?;
//           //   return _createRoute(WastePickupFormUpdated(userId: userId!));
//           default:
//             return _createRoute(
//               Scaffold(
//                 appBar: AppBar(title: const Text('404')),
//                 body: const Center(child: Text('Page not found')),
//               ),
//             );
//         }
//       },
//     );
//   }

//   static PageRouteBuilder _createRoute(Widget page) {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const begin = Offset(1.0, 0.0);
//         const end = Offset.zero;
//         const curve = Curves.easeInOut;

//         var tween = Tween(
//           begin: begin,
//           end: end,
//         ).chain(CurveTween(curve: curve));
//         return SlideTransition(position: animation.drive(tween), child: child);
//       },
//       transitionDuration: const Duration(milliseconds: 300),
//     );
//   }
// }
