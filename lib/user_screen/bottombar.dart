import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/ecomarketplace/homescreen.dart';

import 'package:flutter_application_1/user_screen/new_homepage.dart';

import 'package:flutter_application_1/user_screen/user_request_screen.dart';
import 'package:logger/web.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 1;
  final log = Logger();
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      UserRequestsScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),

      const HomePage(),
      const MarketHomeScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),

      body: screens[myIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: myIndex,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Pickup',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Market',
            ),
          ],
          onTap: (index) {
            setState(() {
              myIndex = index;
            });
          },
        ),
      ),
    );
  }
}
