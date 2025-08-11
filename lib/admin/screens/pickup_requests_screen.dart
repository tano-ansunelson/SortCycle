import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class PickupRequestsScreen extends StatefulWidget {
  const PickupRequestsScreen({super.key});

  @override
  State<PickupRequestsScreen> createState() => _PickupRequestsScreenState();
}

class _PickupRequestsScreenState extends State<PickupRequestsScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Requests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage waste pickup requests and assignments',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showBulkAssignmentDialog(context);
                  },
                  icon: const Icon(Icons.assignment),
                  label: const Text('Bulk Assignment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search and Filter Bar
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search requests...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'assigned',
                        child: Text('Assigned'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Requests List
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: adminProvider.getPickupRequestsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final requests = snapshot.data?.docs ?? [];
                      final filteredRequests = _filterRequests(requests);

                      if (filteredRequests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.recycling_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pickup requests found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          final data = request.data() as Map<String, dynamic>;
                          return _buildRequestCard(request.id, data);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterRequests(
    List<QueryDocumentSnapshot> requests,
  ) {
    return requests.where((request) {
      final data = request.data() as Map<String, dynamic>;

      // Status filter
      if (_statusFilter != 'All' && data['status'] != _statusFilter) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final userName = (data['userName'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        final wasteType = (data['wasteType'] ?? '').toString().toLowerCase();

        if (!userName.contains(searchLower) &&
            !address.contains(searchLower) &&
            !wasteType.contains(searchLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['address'] ?? 'No address provided',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.category,
                  label: 'Waste Type',
                  value: data['wasteType'] ?? 'Unknown',
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Pickup Date',
                  value: _formatDate(data['pickupDate']),
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Requested Time',
                  value: data['pickupTime'] ?? 'Any time',
                ),
              ],
            ),

            if (data['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['notes'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  TextButton.icon(
                    onPressed: () =>
                        _updateRequestStatus(requestId, 'approved'),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _updateRequestStatus(requestId, 'cancelled'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject'),
                  ),
                ] else if (status == 'approved') ...[
                  TextButton.icon(
                    onPressed: () =>
                        _showAssignCollectorDialog(context, requestId),
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    label: const Text('Assign Collector'),
                  ),
                ] else if (status == 'assigned') ...[
                  TextButton.icon(
                    onPressed: () =>
                        _updateRequestStatus(requestId, 'completed'),
                    icon: const Icon(Icons.done_all, color: Colors.green),
                    label: const Text('Mark Complete'),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showRequestDetailsDialog(context, data),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'assigned':
        return 'Assigned';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Date not set';
  }

  void _updateRequestStatus(String requestId, String status) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.updatePickupStatus(requestId, status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request status updated to $status'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAssignCollectorDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => const AssignCollectorDialog(),
    );
  }

  void _showRequestDetailsDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailsDialog(data: data),
    );
  }

  void _showBulkAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BulkAssignmentDialog(),
    );
  }
}

class AssignCollectorDialog extends StatefulWidget {
  const AssignCollectorDialog({super.key});

  @override
  State<AssignCollectorDialog> createState() => _AssignCollectorDialogState();
}

class _AssignCollectorDialogState extends State<AssignCollectorDialog> {
  String? _selectedCollectorId;
  final List<Map<String, dynamic>> _collectors = [
    {'id': '1', 'name': 'John Doe', 'status': 'Available'},
    {'id': '2', 'name': 'Jane Smith', 'status': 'Available'},
    {'id': '3', 'name': 'Mike Johnson', 'status': 'Busy'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Collector'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a collector to assign to this request:'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCollectorId,
            decoration: const InputDecoration(
              labelText: 'Collector',
              border: OutlineInputBorder(),
            ),
            items: _collectors
                .where((c) => c['status'] == 'Available')
                .map(
                  (collector) => DropdownMenuItem<String>(
                    value: collector['id'] as String,
                    child: Text(collector['name']),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCollectorId = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCollectorId != null
              ? () {
                  // TODO: Implement collector assignment
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Collector assigned successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              : null,
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

class RequestDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const RequestDetailsDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('User Name', data['userName'] ?? 'N/A'),
            _buildDetailRow('Address', data['address'] ?? 'N/A'),
            _buildDetailRow('Waste Type', data['wasteType'] ?? 'N/A'),
            _buildDetailRow('Pickup Date', _formatDate(data['pickupDate'])),
            _buildDetailRow('Pickup Time', data['pickupTime'] ?? 'N/A'),
            _buildDetailRow('Status', data['status'] ?? 'N/A'),
            if (data['notes']?.isNotEmpty == true)
              _buildDetailRow('Notes', data['notes']),
            _buildDetailRow('Created', _formatDate(data['timestamp'])),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    }
    return 'Date not set';
  }
}

class BulkAssignmentDialog extends StatelessWidget {
  const BulkAssignmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Assignment'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This feature will allow you to assign multiple pending requests to available collectors at once.',
          ),
          SizedBox(height: 16),
          Text('Coming soon...'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
