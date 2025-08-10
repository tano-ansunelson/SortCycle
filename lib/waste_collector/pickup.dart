// ignore: unused_import
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/chat_page/chat_page.dart';
// ignore: unused_import
import 'package:flutter_application_1/chat_page/chatlist_page.dart';
import 'package:flutter_application_1/routes/app_route.dart';
import 'package:intl/intl.dart';

class PickupManagementPage extends StatefulWidget {
  final String collectorId;
  final String collectorName;
  //final int initialTabIndex;

  const PickupManagementPage({
    super.key,
    required this.collectorId,
    required this.collectorName,
    //this.initialTabIndex=0,
  });

  @override
  State<PickupManagementPage> createState() => _PickupManagementPageState();
}

class _PickupManagementPageState extends State<PickupManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      //initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Pickup Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Incoming Requests'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Your Pickups'),
            //Tab(icon: Icon(Icons.chat), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingRequestsTab(),
          _buildYourPickupsTab(),

          //const ChatListPage(),
        ],
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

  Widget _buildIncomingRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('status', isEqualTo: 'pending')
          .where('collectorId', isEqualTo: null) // Unassigned requests
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No incoming requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'New pickup requests will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // The stream will automatically refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final request = doc.data() as Map<String, dynamic>;
              return _buildIncomingRequestCard(doc.id, request);
            },
          ),
        );
      },
    );
  }

  Widget _buildYourPickupsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('collectorId', isEqualTo: widget.collectorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No accepted pickups yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Accepted pickup requests will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // The stream will automatically refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final request = doc.data() as Map<String, dynamic>;
              return _buildYourPickupCard(doc.id, request);
            },
          ),
        );
      },
    );
  }

  Widget _buildIncomingRequestCard(
    String requestId,
    Map<String, dynamic> request,
  ) {
    final wasteCategories = request['wasteCategories'] as List<dynamic>? ?? [];
    final pickupDate = request['pickupDate'];
    final createdAt = request['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${requestId.substring(0, 6)}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'GH₵ ${_calculateEarning(wasteCategories)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Info
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['userName'] ?? 'Unknown User',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request['userTown'] ?? 'Location not specified',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Phone
          Row(
            children: [
              Icon(Icons.phone, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['userPhone'] ?? 'No phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(pickupDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          Text(
            'Items: ${wasteCategories.join(', ')}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested ${_getTimeAgo(createdAt)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDeclineDialog(requestId);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          collectorId: widget.collectorId,
                          requestId: requestId,
                          collectorName:
                              request['collectorName'] ?? 'Collector',
                          userName: request['userName'] ?? 'User',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showAcceptDialog(requestId);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourPickupCard(String requestId, Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final wasteCategories = request['wasteCategories'] as List<dynamic>? ?? [];
    final pickupDate = request['pickupDate'];
    final updatedAt = request['updatedAt'];

    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${requestId.substring(0, 6)}',
                  style: const TextStyle(
                    //color: statusColor[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    // color: statusColor[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'GH₵ ${_calculateEarning(wasteCategories)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Info
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['userName'] ?? 'Unknown User',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location and Phone
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request['userTown'] ?? 'Location not specified',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.phone, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['userPhone'] ?? 'No phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(pickupDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          Text(
            'Items: ${wasteCategories.join(', ')}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated ${_getTimeAgo(updatedAt)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(requestId, status, request),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    String requestId,
    String status,
    Map<String, dynamic> request,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateRequestStatus(requestId, 'in_progress'),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Pickup'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        collectorId: widget.collectorId,
                        requestId: requestId,
                        collectorName: request['collectorName'] ?? 'Collector',
                        userName: request['userName'] ?? 'User',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ElevatedButton.icon(
                onPressed: () => _showCompleteDialog(requestId),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Flexible(
            //   fit: FlexFit.tight,
            //   child: ElevatedButton.icon(
            //     onPressed: () => _navigateToLocation(requestId),
            //     // _navigateToLocation(requestId, data),
            //     //_showRequestDetails(doc.id, data),
            //     icon: const Icon(Icons.navigation, size: 18),
            //     label: const Text('Navigate'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue,
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 4,
            //         vertical: 12,
            //       ),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.tight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        collectorId: widget.collectorId,
                        requestId: requestId,
                        collectorName: request['collectorName'] ?? 'Collector',
                        userName: request['userName'] ?? 'User',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 91, 3, 244),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'PICKUP COMPLETED',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Status: ${status.toUpperCase()}',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

  // Helper Methods
  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Not set';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Invalid date';
    }

    return DateFormat('MMM dd, hh:mm a').format(dateTime);
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'some time ago';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'some time ago';
    }

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

  String _calculateEarning(List<dynamic> wasteCategories) {
    // Simple earning calculation based on waste categories
    int baseEarning = 0;
    for (var category in wasteCategories) {
      switch (category.toString().toLowerCase()) {
        case 'electronics':
          baseEarning += 60;
          break;
        case 'metal':
          baseEarning += 40;
          break;
        case 'plastic':
          baseEarning += 25;
          break;
        case 'paper':
          baseEarning += 20;
          break;
        case 'glass':
          baseEarning += 15;
          break;
        default:
          baseEarning += 10;
      }
    }
    return baseEarning.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Firebase Operations
  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        if (newStatus == 'completed') ...{
          'updatedAt': FieldValue.serverTimestamp(),
          'collectorId': widget.collectorId,
        },
      };

      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .doc(requestId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${newStatus.replaceAll('_', ' ')} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog Methods
  void _showAcceptDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Pickup Request'),
        content: const Text(
          'Are you sure you want to accept this pickup request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(requestId, 'accepted');
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Pickup Request'),
        content: const Text(
          'Are you sure you want to decline this pickup request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(requestId, 'cancelled');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Pickup'),
        content: const Text('Mark this pickup as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(requestId, 'completed');
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  // void _navigateToLocation(String requestId) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text('Opening navigation...')));
  //   // Here you would integrate with maps/navigation
  //   // For example: launch Google Maps or Apple Maps
  // }
}
