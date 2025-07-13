// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/user_screen/waste_form.dart';
// import 'package:intl/intl.dart';

// class PickupRequestsTab extends StatefulWidget {
//   final String? userPhone; // To filter requests by user

//   const PickupRequestsTab({super.key, this.userPhone});

//   @override
//   State<PickupRequestsTab> createState() => _PickupRequestsTabState();
// }

// class _PickupRequestsTabState extends State<PickupRequestsTab> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FFFE),
//       appBar: AppBar(
//         title: const Text('My Pickup Requests'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: widget.userPhone != null
//           ? StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('pickup_requests')
//                   .where('userPhone', isEqualTo: widget.userPhone)
//                   .orderBy('createdAt', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.inbox_outlined,
//                           size: 64,
//                           color: Colors.grey,
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'No pickup requests yet',
//                           style: TextStyle(fontSize: 18, color: Colors.grey),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Submit a pickup request to see it here',
//                           style: TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final request = doc.data() as Map<String, dynamic>;
//                     return PickupRequestCard(
//                       requestId: doc.id,
//                       request: request,
//                     );
//                   },
//                 );
//               },
//             )
//           : const Center(
//               child: Text('Please provide user phone to view requests'),
//             ),
//     );
//   }
// }

// class PickupRequestCard extends StatelessWidget {
//   final String requestId;
//   final Map<String, dynamic> request;

//   const PickupRequestCard({
//     super.key,
//     required this.requestId,
//     required this.request,
//   });

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'accepted':
//         return Colors.blue;
//       case 'completed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Icons.schedule;
//       case 'accepted':
//         return Icons.check_circle_outline;
//       case 'completed':
//         return Icons.check_circle;
//       case 'cancelled':
//         return Icons.cancel_outlined;
//       default:
//         return Icons.help_outline;
//     }
//   }

//   String _formatDateTime(dynamic timestamp) {
//     if (timestamp == null) return 'Not set';

//     DateTime dateTime;
//     if (timestamp is Timestamp) {
//       dateTime = timestamp.toDate();
//     } else if (timestamp is DateTime) {
//       dateTime = timestamp;
//     } else {
//       return 'Invalid date';
//     }

//     return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
//   }

//   String _formatCategories(List<dynamic>? categories) {
//     if (categories == null || categories.isEmpty) return 'No categories';
//     return categories.join(', ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final status = request['status'] ?? 'pending';
//     final pickupDate = request['pickupDate'];
//     final createdAt = request['createdAt'];
//     final wasteCategories = request['wasteCategories'] as List<dynamic>?;
//     final collectorId = request['collectorId'];

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       color: Colors.white,
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status and Date Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(status).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: _getStatusColor(status),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         _getStatusIcon(status),
//                         size: 16,
//                         color: _getStatusColor(status),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         status.toUpperCase(),
//                         style: TextStyle(
//                           color: _getStatusColor(status),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   'ID: ${requestId.substring(0, 8)}...',
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // Pickup Date and Time
//             Row(
//               children: [
//                 const Icon(Icons.schedule, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Pickup: ${_formatDateTime(pickupDate)}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Waste Categories
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Items: ${_formatCategories(wasteCategories)}',
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Location
//             Row(
//               children: [
//                 const Icon(
//                   Icons.location_on_outlined,
//                   size: 16,
//                   color: Colors.grey,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Location: ${request['userTown'] ?? 'Not specified'}',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Request Created Date
//             Row(
//               children: [
//                 const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Requested: ${_formatDateTime(createdAt)}',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),

//             // Collector Info (if available)
//             if (collectorId != null) ...[
//               const SizedBox(height: 12),
//               const Divider(),
//               const SizedBox(height: 8),
//               FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection('collectors')
//                     .doc(collectorId)
//                     .get(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Text(
//                       'Loading collector info...',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     );
//                   }

//                   if (snapshot.hasError ||
//                       !snapshot.hasData ||
//                       !snapshot.data!.exists) {
//                     return const Text(
//                       'Collector info not available',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     );
//                   }

//                   final collector =
//                       snapshot.data!.data() as Map<String, dynamic>;
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Collector: ${collector['name'] ?? 'Unknown'}',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 14,
//                         ),
//                       ),
//                       if (collector['phone'] != null)
//                         Text(
//                           'Phone: ${collector['phone']}',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//             ],

//             // Action Buttons (if needed)
//             if (status == 'pending') ...[
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   OutlinedButton(
//                     onPressed: () => _showCancelDialog(context),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.red,
//                       side: const BorderSide(color: Colors.red),
//                     ),
//                     child: const Text('Cancel Request'),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   void _showCancelDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Cancel Request'),
//         content: const Text(
//           'Are you sure you want to cancel this pickup request?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _cancelRequest(context);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Yes, Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _cancelRequest(BuildContext context) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('pickup_requests')
//           .doc(requestId)
//           .update({
//             'status': 'cancelled',
//             'updatedAt': FieldValue.serverTimestamp(),
//           });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Request cancelled successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to cancel request: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

// // Helper widget for main navigation
// class MainTabView extends StatefulWidget {
//   final String? userPhone;

//   const MainTabView({super.key, this.userPhone});

//   @override
//   State<MainTabView> createState() => _MainTabViewState();
// }

// class _MainTabViewState extends State<MainTabView> {
//   int _selectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> pages = [
//       const WastePickupForm(), // Your existing form
//       PickupRequestsTab(userPhone: widget.userPhone),
//     ];

//     return Scaffold(
//       body: pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_circle_outline),
//             label: 'New Request',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list_alt),
//             label: 'My Requests',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Collector Dashboard (for collectors to accept requests)
// class CollectorDashboard extends StatelessWidget {
//   final String collectorId;

//   const CollectorDashboard({super.key, required this.collectorId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FFFE),
//       appBar: AppBar(
//         title: const Text('Pickup Requests'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('pickup_requests')
//             .where('collectorId', isEqualTo: collectorId)
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'No pickup requests assigned',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final request = doc.data() as Map<String, dynamic>;
//               return CollectorRequestCard(requestId: doc.id, request: request);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class CollectorRequestCard extends StatelessWidget {
//   final String requestId;
//   final Map<String, dynamic> request;

//   const CollectorRequestCard({
//     super.key,
//     required this.requestId,
//     required this.request,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final status = request['status'] ?? 'pending';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       color: Colors.white,
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Customer Info
//             Row(
//               children: [
//                 const Icon(Icons.person, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(
//                   request['userName'] ?? 'Unknown',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Phone
//             Row(
//               children: [
//                 const Icon(Icons.phone, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(request['userPhone'] ?? 'No phone'),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Location
//             Row(
//               children: [
//                 const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(request['userTown'] ?? 'No location'),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // Waste Categories
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Items: ${(request['wasteCategories'] as List<dynamic>?)?.join(', ') ?? 'None'}',
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // Action Buttons
//             if (status == 'pending') ...[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () =>
//                           _updateRequestStatus(context, 'cancelled'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: const BorderSide(color: Colors.red),
//                       ),
//                       child: const Text('Decline'),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () =>
//                           _updateRequestStatus(context, 'accepted'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: const Text('Accept'),
//                     ),
//                   ),
//                 ],
//               ),
//             ] else if (status == 'accepted') ...[
//               ElevatedButton(
//                 onPressed: () => _updateRequestStatus(context, 'completed'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Mark as Completed'),
//               ),
//             ] else ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: status == 'completed'
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.grey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   'Status: ${status.toUpperCase()}',
//                   style: TextStyle(
//                     color: status == 'completed' ? Colors.green : Colors.grey,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _updateRequestStatus(
//     BuildContext context,
//     String newStatus,
//   ) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('pickup_requests')
//           .doc(requestId)
//           .update({
//             'status': newStatus,
//             'updatedAt': FieldValue.serverTimestamp(),
//           });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Request ${newStatus} successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update request: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }
