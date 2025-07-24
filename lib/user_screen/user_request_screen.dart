import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/chat_page/chat_page.dart';
import 'package:intl/intl.dart';

class UserRequestsScreen extends StatefulWidget {
  final String userId; // Pass the current user's ID

  const UserRequestsScreen({super.key, required this.userId});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('My Pickups'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('pickup_requests')
            .where('userId', isEqualTo: widget.userId)
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pickup requests yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your pickup requests will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return RequestCard(
                requestId: request.id,
                requestData: data,
                onCancel: () => _cancelRequest(request.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      // Show confirmation dialog
      bool? shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
            'Are you sure you want to cancel this pickup request?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        await _firestore.collection('pickup_requests').doc(requestId).update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final VoidCallback onCancel;

  const RequestCard({
    super.key,
    required this.requestId,
    required this.requestData,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = requestData['status'] as String;
    final pickupDate = (requestData['pickupDate'] as Timestamp).toDate();
    final wasteCategories = List<String>.from(
      requestData['wasteCategories'] ?? [],
    );
    final collectorId = requestData['collectorId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(status),
                Text(
                  DateFormat('MMM dd, yyyy').format(pickupDate),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pickup Details
            _buildInfoRow(
              Icons.schedule,
              'Pickup Time',
              DateFormat('MMM dd, yyyy - hh:mm a').format(pickupDate),
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              Icons.location_on,
              'Location',
              '${requestData['userTown']}',
            ),

            const SizedBox(height: 8),

            // Waste Categories
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waste Categories',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: wasteCategories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Collector Info (if assigned)
            if (collectorId != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('collectors')
                    .doc(collectorId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final collectorData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return _buildInfoRow(
                      Icons.person,
                      'Collector',
                      '${collectorData['name']} - ${collectorData['phone']}',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 12),

            // Action Buttons
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending')
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                const SizedBox(width: 8),

                TextButton(
                  onPressed: () => _showRequestDetails(context),
                  child: const Text('View Details'),
                ),

                const SizedBox(width: 8),

                if (collectorId != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            collectorId: collectorId,
                            collectorName:
                                requestData['collectorName'] ?? 'Collector',
                            requestId: requestId,
                            userName: requestData['userName'] ?? 'User',
                          ),
                        ),
                      );
                    },
                    child: const Text('Chat'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        break;
      case 'accepted':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRequestDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Request ID', requestId),
              _buildDetailRow('Name', requestData['userName'] ?? 'N/A'),
              _buildDetailRow('Phone', requestData['userPhone'] ?? 'N/A'),
              _buildDetailRow('Town', requestData['userTown'] ?? 'N/A'),
              _buildDetailRow('Status', requestData['status'] ?? 'N/A'),
              _buildDetailRow(
                'Created At',
                requestData['createdAt'] != null
                    ? DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format((requestData['createdAt'] as Timestamp).toDate())
                    : 'N/A',
              ),
              if (requestData['updatedAt'] != null)
                _buildDetailRow(
                  'Updated At',
                  DateFormat(
                    'MMM dd, yyyy - hh:mm a',
                  ).format((requestData['updatedAt'] as Timestamp).toDate()),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
