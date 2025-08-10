import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/provider.dart';
import 'package:flutter_application_1/routes/app_route.dart';
//import 'package:flutter_application_1/routes/app_route.dart';
import 'package:flutter_application_1/service/greetings.dart';
import 'package:flutter_application_1/waste_collector/pending_summary.dart';
//import 'package:flutter_application_1/user_screen/profile_screen.dart';
import 'package:flutter_application_1/waste_collector/pickup.dart';
import 'package:flutter_application_1/waste_collector/profile_screen.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class CollectorMainScreen extends StatefulWidget {
  const CollectorMainScreen({super.key});

  @override
  State<CollectorMainScreen> createState() => _CollectorMainScreenState();
}

class _CollectorMainScreenState extends State<CollectorMainScreen> {
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<CollectorProvider>(
        context,
        listen: false,
      ).fetchCollectorData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final collectorId = currentUser?.uid;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PickupManagementPage(collectorId: collectorId!, collectorName: ''),
          const CollectorHomePage(),
          const CollectorProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
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
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});
  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
  final collectorId = FirebaseAuth.instance.currentUser!.uid;
  bool isActive = false;

  @override
  void initState() {
    _loadActiveStatus();
    super.initState();
  }

  Future<void> _loadActiveStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('collectors')
          .doc(collectorId)
          .get();

      if (doc.exists) {
        setState(() {
          isActive = doc.data()?['isActive'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading active status: $e');
    }
  }

  Future<void> _updateActiveStatus(bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('collectors')
          .doc(collectorId)
          .update({
            'isActive': value,
            'lastActiveUpdate': FieldValue.serverTimestamp(),
          });

      setState(() {
        isActive = value;
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'You are now active and available for pickups'
                : 'You are now inactive',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating active status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectorName = context.watch<CollectorProvider>().name;
    //final username = context.watch<UserProvider>().username;
    //final greeting = getGreeting();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi,',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              " ${collectorName ?? 'Guest'}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Active Status Switch
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isActive,
                    onChanged: _updateActiveStatus,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withOpacity(0.3),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () {
                  // Navigate to notifications
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards Row
              SummaryCardsRow(collectorId: collectorId),

              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildSummaryCard(
              //         title: 'Today\'s Pickups',
              //         count: '8',
              //         icon: Icons.local_shipping,
              //         color: Colors.blue,
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     const Expanded(child: PendingSummaryCard()),
              //   ],
              // ),
              const SizedBox(height: 16),

              // Earnings Card
              _buildEarningsCard(),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),

              // Recent Pickups
              const Text(
                'Recent Pickups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentPickupsList(collectorId),
              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
      // Floating Action Button for Quick Scan
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF42A5F5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF26A69A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.chatlistpage),
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat, color: Colors.white),
              SizedBox(width: 3),
              Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildSummaryCard({
  //   required String title,
  //   required String count,
  //   required IconData icon,
  //   required Color color,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.1),
  //           spreadRadius: 1,
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: color.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, color: color, size: 24),
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           count,
  //           style: const TextStyle(
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Earnings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.monetization_on, color: Colors.white),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'GH₵ 245.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'GH₵ 1,240',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'This Month',
              //         style: TextStyle(color: Colors.white70, fontSize: 12),
              //       ),
              //       Text(
              //         'GH₵ 4,890',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildQuickActionItem(
          title: 'View Requests',
          icon: Icons.inbox,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickupManagementPage(
                  collectorId: collectorId,
                  collectorName: '',
                ),
              ),
            );
          },
        ),
        _buildQuickActionItem(
          title: 'Start Route',
          icon: Icons.navigation,
          color: Colors.green,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.collectormapscreen,
              arguments: {
                'collectorId': FirebaseAuth.instance.currentUser?.uid,
              },
            );

            // Start navigation route
          },
        ),
        _buildQuickActionItem(
          title: 'EcoMarket',
          icon: Icons.history,
          color: Colors.purple,
          onTap: () {
            // _buildIncomingRequestsTab(),
            Navigator.pushNamed(context, AppRoutes.markethomescreen);
          },
        ),
        _buildQuickActionItem(
          title: 'Settings',
          icon: Icons.settings,
          color: Colors.grey,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.collectorProfile);
            // Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPickupsList(String collectorId) {
    //final now = Timestamp.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('collectorId', isEqualTo: collectorId)
          .where('status', isEqualTo: 'completed')
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recent pickups found."));
        }

        final recentPickups = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentPickups.length,
          itemBuilder: (context, index) {
            final pickup = recentPickups[index].data() as Map<String, dynamic>;
            final timestamp = pickup['pickupDate'] as Timestamp?;
            final pickupTime = timestamp?.toDate();
            final formattedTime = pickupTime != null
                ? timeAgo(pickupTime)
                : 'Unknown time';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pickup['userName'] ?? 'Unknown user',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            // Text(
                            //   '#${recentPickups[index].id}',
                            //   style: const TextStyle(
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.black87,
                            //   ),
                            // ),
                            const Spacer(),
                            Text(
                              pickup['earning'] != null
                                  ? 'GH₵ ${pickup['earning']}'
                                  : '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickup['userTown'] ?? 'Unknown location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${(pickup['wasteCategories'] is List ? pickup['wasteCategories'].length : 0)} items',

                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
