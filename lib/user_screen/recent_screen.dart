import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/user_screen/user_request_screen.dart';
import 'package:flutter_application_1/user_screen/waste_form.dart';

class WasteForm extends StatelessWidget {
  const WasteForm({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF2E7D32),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'New Request', icon: Icon(Icons.add)),
                      Tab(text: 'My Requests', icon: Icon(Icons.list)),
                    ],
                    indicatorColor: Color.fromARGB(255, 243, 245, 243),
                    labelColor: Color.fromARGB(255, 240, 242, 240),
                    unselectedLabelColor: Color.fromARGB(255, 5, 5, 5),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      WastePickupFormUpdated(userId: currentUserId),
                      UserRequestsScreen(userId: currentUserId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
