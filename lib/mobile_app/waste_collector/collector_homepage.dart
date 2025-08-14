// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/mobile_app/provider/provider.dart';
import 'package:flutter_application_1/mobile_app/provider/notification_provider.dart';
//import 'package:flutter_application_1/mobile_app/provider/sort_score_provider.dart';
import 'package:flutter_application_1/mobile_app/routes/app_route.dart';
//import 'package:flutter_application_1/routes/app_route.dart';
import 'package:flutter_application_1/mobile_app/service/greetings.dart';
import 'package:flutter_application_1/mobile_app/waste_collector/pending_summary.dart';
//import 'package:flutter_application_1/user_screen/profile_screen.dart';
import 'package:flutter_application_1/mobile_app/waste_collector/pickup.dart';
import 'package:flutter_application_1/mobile_app/waste_collector/profile_screen.dart';
import 'package:flutter_application_1/mobile_app/waste_collector/notification_page.dart';
//import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    _fetchCollectorData();
  }

  void _fetchCollectorData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CollectorProvider>(
          context,
          listen: false,
        ).fetchCollectorData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final collectorId = currentUser?.uid;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PickupManagementPage(
            collectorId: collectorId!,
            collectorName: '',
            collectorTown: context.watch<CollectorProvider>().town ?? '',
          ),
          const CollectorHomePage(),
          const CollectorProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
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

    // Initialize notification provider for collector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.initialize(collectorId, 'collector');
      }
    });
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
      debugPrint('Error loading active status: $e');
    }
  }

  Future<void> _updateActiveStatus(bool value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('collectors')
          .doc(collectorId)
          .update({
            'isActive': value,
            'lastActiveUpdate': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          isActive = value;
        });

        // Show feedback to user
        scaffoldMessenger.showSnackBar(
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
      }
    } catch (e) {
      debugPrint('Error updating active status: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            // Text(
            //   'Hi,',
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey[600],
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
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
                    activeTrackColor: Colors.green.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/collector-notifications');
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
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
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            notificationProvider.unreadCount > 99
                                ? '99+'
                                : notificationProvider.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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

              const SizedBox(height: 16),

              // Calendar Widget
              _buildCalendarWidget(collectorId),
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
              color: const Color(0xFF26A69A).withValues(alpha: 0.3),
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

  Widget _buildCalendarWidget(String collectorId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Pickup Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                DateFormat('MMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeeklyCalendar(collectorId),
          const SizedBox(height: 16),
          _buildTodaySummary(collectorId),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(String collectorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('collectorId', isEqualTo: collectorId)
          .where(
            'status',
            whereIn: ['pending_confirmation', 'confirmed', 'completed'],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data?.docs ?? [];
        final weeklyData = _getWeeklyPickupData(allRequests);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weeklyData.map((dayData) {
            final isToday = dayData['date'].isAtSameMomentAs(
              DateTime.now().copyWith(
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 0,
                microsecond: 0,
              ),
            );
            final hasPickups = dayData['count'] > 0;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.blue.shade50
                      : hasPickups
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday
                        ? Colors.blue.shade300
                        : hasPickups
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayData['dayName'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayData['dayNumber'].toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Colors.blue.shade700
                            : hasPickups
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasPickups)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.blue.shade200
                              : Colors.green.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${dayData['count']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Colors.blue.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTodaySummary(String collectorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('collectorId', isEqualTo: collectorId)
          .where(
            'status',
            whereIn: ['pending_confirmation', 'confirmed', 'completed'],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endOfToday = startOfToday
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));

        // Calculate counts for today's activities
        int pendingCount = 0;
        // int confirmedCount = 0;
        int completedCount = 0;

        // Debug: Print total requests found
        //print('DEBUG: Total requests found: ${allRequests.length}');

        // Simple approach: Count all requests by status first
        for (final doc in allRequests) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final status = data['status'] as String?;
            if (status == 'pending_confirmation') {
              pendingCount++;
            } else if (status == 'completed') {
              completedCount++;
            }
          }
        }

        // Reset counts for detailed approach
        pendingCount = 0;
        //confirmedCount = 0;
        completedCount = 0;

        for (final doc in allRequests) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final status = data['status'] as String?;
            final pickupDate = data['pickupDate'] as Timestamp?;
            final userConfirmedAt = data['userConfirmedAt'] as Timestamp?;

            // Debug: Print each request details

            // Check if this request is relevant for today
            bool isRelevantForToday = false;

            // Check pickup date - if pickup is scheduled for today
            if (pickupDate != null) {
              final pickupDateTime = pickupDate.toDate();
              if (pickupDateTime.isAfter(startOfToday) &&
                  pickupDateTime.isBefore(endOfToday)) {
                isRelevantForToday = true;
                // print('DEBUG: Pickup scheduled for today: $pickupDateTime');
              }
            }

            // Check if it was completed today
            if (status == 'completed' && userConfirmedAt != null) {
              final completedDateTime = userConfirmedAt.toDate();
              if (completedDateTime.isAfter(startOfToday) &&
                  completedDateTime.isBefore(endOfToday)) {
                isRelevantForToday = true;
                // print('DEBUG: Completed today: $completedDateTime');
              }
            }

            if (isRelevantForToday) {
              // print('DEBUG: Request is relevant for today, status: $status');
              if (status == 'pending') {
                pendingCount++;
              } else if (status == 'completed') {
                completedCount++;
              }
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem('Pending', pendingCount, Colors.orange),
                  // _buildStatusItem('Confirmed', confirmedCount, Colors.blue),
                  _buildStatusItem('Completed', completedCount, Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeeklyPickupData(
    List<QueryDocumentSnapshot> requests,
  ) {
    final List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();

    // Add null safety check
    if (requests.isEmpty) {
      // Return empty weekly data if no requests
      for (int i = -3; i <= 3; i++) {
        final date = now.add(Duration(days: i));
        final startOfDay = date.copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );

        weeklyData.add({
          'date': startOfDay,
          'dayName': DateFormat('E').format(date),
          'dayNumber': date.day,
          'count': 0,
        });
      }
      return weeklyData;
    }

    for (int i = -3; i <= 3; i++) {
      final date = now.add(Duration(days: i));
      final startOfDay = date.copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
      final endOfDay = date.copyWith(
        hour: 23,
        minute: 59,
        second: 59,
        millisecond: 999,
        microsecond: 999,
      );

      final dayRequests = requests.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final pickupDate = data['pickupDate']?.toDate();
        final userConfirmedAt = data['userConfirmedAt']?.toDate();

        // Check if this request is relevant for this day
        bool isRelevantForDay = false;

        // Check pickup date - if pickup is scheduled for this day
        if (pickupDate != null) {
          if (pickupDate.isAfter(startOfDay) && pickupDate.isBefore(endOfDay)) {
            isRelevantForDay = true;
          }
        }

        // Check if it was completed on this day
        if (data['status'] == 'completed' && userConfirmedAt != null) {
          if (userConfirmedAt.isAfter(startOfDay) &&
              userConfirmedAt.isBefore(endOfDay)) {
            isRelevantForDay = true;
          }
        }

        return isRelevantForDay;
      }).toList();

      weeklyData.add({
        'date': startOfDay,
        'dayName': DateFormat('E').format(date),
        'dayNumber': date.day,
        'count': dayRequests.length,
      });
    }

    return weeklyData;
  }

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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickup_requests')
            .where('collectorId', isEqualTo: collectorId)
            .where(
              'status',
              whereIn: [
                'pending',
                'in_progress',
                'completed',
                'pending_confirmation',
              ],
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Error loading earnings',
              style: TextStyle(color: Colors.white),
            );
          }

          if (!snapshot.hasData) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Earnings',
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
                  'GH₵ 0.00',
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
                            'This Month',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'GH₵ 0.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Calculate earnings
          double totalEarnings = 0.0;
          double monthEarnings = 0.0;
          double pendingAmount = 0.0;
          double pendingConfirmationAmount = 0.0;

          final now = DateTime.now();

          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
            final status = data['status'] ?? '';
            final createdAt = data['createdAt'] as Timestamp?;
            final userConfirmedAt = data['userConfirmedAt'] as Timestamp?;

            if (createdAt != null) {
              final createdDate = createdAt.toDate();

              // For completed requests, check when they were actually completed
              DateTime? completionDate;
              if (status == 'completed' && userConfirmedAt != null) {
                completionDate = userConfirmedAt.toDate();
              }

              // Total earnings (all completed requests)
              if (status == 'completed') {
                totalEarnings += totalAmount;
              } else if (status == 'pending' || status == 'in_progress') {
                pendingAmount += totalAmount;
              } else if (status == 'pending_confirmation') {
                pendingConfirmationAmount += totalAmount;
              }

              // This month's earnings (from requests completed this month)
              if (status == 'completed' &&
                  completionDate != null &&
                  completionDate.month == now.month &&
                  completionDate.year == now.year) {
                monthEarnings += totalAmount;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.monetization_on, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'GH₵ ${totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pendingAmount > 0 || pendingConfirmationAmount > 0) ...[
                const SizedBox(height: 8),
                if (pendingAmount > 0)
                  Text(
                    'Pending: GH₵ ${pendingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (pendingConfirmationAmount > 0)
                  Text(
                    'Awaiting Confirmation: GH₵ ${pendingConfirmationAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Month',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'GH₵ ${monthEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Pending Release',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'GH₵ ${(pendingAmount + pendingConfirmationAmount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (pendingConfirmationAmount > 0)
                          Text(
                            '(${pendingConfirmationAmount.toStringAsFixed(2)} awaiting)',
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
            Navigator.pushNamed(
              context,
              AppRoutes.pickup,
              arguments: {'collectorId': collectorId},
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.1),
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
          .where('status', whereIn: ['completed', 'pending_confirmation'])
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
                    color: Colors.grey.withValues(alpha: 0.1),
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
                      color: Colors.green.withValues(alpha: 0.1),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  pickup['totalAmount'] != null
                                      ? 'GH₵ ${pickup['totalAmount']}'
                                      : '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                                if (pickup['status'] == 'pending_confirmation')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Awaiting Confirmation',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
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

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
