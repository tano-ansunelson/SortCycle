import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class CollectorsManagementScreen extends StatefulWidget {
  const CollectorsManagementScreen({super.key});

  @override
  State<CollectorsManagementScreen> createState() => _CollectorsManagementScreenState();
}

class _CollectorsManagementScreenState extends State<CollectorsManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
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
                      'Collectors Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage waste collector accounts and permissions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddCollectorDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Collector'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                      hintText: 'Search collectors...',
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
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
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

            // Collectors List
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: adminProvider.getCollectorsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
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
                                'No collectors found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      var collectors = snapshot.data!.docs;

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        collectors = collectors.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString().toLowerCase();
                          final email = (data['email'] ?? '').toString().toLowerCase();
                          final phone = (data['phone'] ?? '').toString().toLowerCase();
                          final vehicleNumber = (data['vehicleNumber'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery.toLowerCase()) ||
                              email.contains(_searchQuery.toLowerCase()) ||
                              phone.contains(_searchQuery.toLowerCase()) ||
                              vehicleNumber.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      // Apply status filter
                      if (_statusFilter != 'All') {
                        collectors = collectors.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return (data['status'] ?? 'active') == _statusFilter;
                        }).toList();
                      }

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Collector')),
                              DataColumn(label: Text('Contact')),
                              DataColumn(label: Text('Vehicle')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Joined')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: collectors.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.orange.shade100,
                                          child: Text(
                                            (data['name'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              data['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${doc.id.substring(0, 8)}...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(data['email'] ?? 'No email'),
                                        Text(
                                          data['phone'] ?? 'No phone',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          data['vehicleNumber'] ?? 'No vehicle',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          data['vehicleType'] ?? 'Unknown type',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    _buildStatusChip(data['status'] ?? 'active'),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatDate(data['createdAt']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _showCollectorDetails(context, doc);
                                          },
                                          icon: const Icon(Icons.visibility),
                                          tooltip: 'View Details',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _showEditCollectorDialog(context, doc);
                                          },
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit Collector',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _showDeleteConfirmation(context, doc.id, data['name'] ?? 'Collector');
                                          },
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Delete Collector',
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Inactive';
        break;
      case 'suspended':
        color = Colors.red;
        label = 'Suspended';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Invalid date';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showAddCollectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Collector'),
        content: const Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditCollectorDialog(BuildContext context, DocumentSnapshot collectorDoc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Collector'),
        content: const Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCollectorDetails(BuildContext context, DocumentSnapshot collectorDoc) {
    final data = collectorDoc.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Collector Details: ${data['name'] ?? 'Unknown'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', data['name'] ?? 'N/A'),
              _buildDetailRow('Email', data['email'] ?? 'N/A'),
              _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
              _buildDetailRow('Status', data['status'] ?? 'active'),
              _buildDetailRow('Vehicle Number', data['vehicleNumber'] ?? 'N/A'),
              _buildDetailRow('Vehicle Type', data['vehicleType'] ?? 'N/A'),
              _buildDetailRow('Joined', _formatDate(data['createdAt'])),
              _buildDetailRow('Collector ID', collectorDoc.id),
              if (data['address'] != null) _buildDetailRow('Address', data['address']),
              if (data['profileImage'] != null) _buildDetailRow('Profile Image', 'Available'),
              if (data['licenseNumber'] != null) _buildDetailRow('License Number', data['licenseNumber']),
              if (data['insuranceNumber'] != null) _buildDetailRow('Insurance Number', data['insuranceNumber']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String collectorId, String collectorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collector'),
        content: Text('Are you sure you want to delete collector "$collectorName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              adminProvider.deleteCollector(collectorId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Collector "$collectorName" has been deleted.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
