import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../web_providers/admin_provider.dart';

class AdminCollectorManagementScreen extends StatefulWidget {
  const AdminCollectorManagementScreen({super.key});

  @override
  State<AdminCollectorManagementScreen> createState() => _AdminCollectorManagementScreenState();
}

class _AdminCollectorManagementScreenState extends State<AdminCollectorManagementScreen> {
  List<Map<String, dynamic>> _collectors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCollectors();
  }

  Future<void> _loadCollectors() async {
    setState(() => _isLoading = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final collectors = await adminProvider.getCollectors();
    setState(() {
      _collectors = collectors;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredCollectors {
    if (_searchQuery.isEmpty) return _collectors;
    return _collectors.where((collector) {
      final name = collector['name']?.toString().toLowerCase() ?? '';
      final email = collector['email']?.toString().toLowerCase() ?? '';
      final phone = collector['phone']?.toString().toLowerCase() ?? '';
      final vehicleType = collector['vehicleType']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || 
             email.contains(query) || 
             phone.contains(query) || 
             vehicleType.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCollectors,
            tooltip: 'Refresh Collectors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Actions Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search collectors by name, email, phone, or vehicle type...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                Text(
                  '${_filteredCollectors.length} collectors',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Collectors Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCollectors.isEmpty
                    ? const Center(
                        child: Text(
                          'No collectors found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Vehicle Type')),
                            DataColumn(label: Text('License Plate')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Joined')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredCollectors.map((collector) {
                            final isActive = collector['isActive'] ?? true;
                            final joinedDate = collector['createdAt'] != null
                                ? (collector['createdAt'] as dynamic).toDate()
                                : null;
                            
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    collector['name']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                DataCell(Text(collector['email']?.toString() ?? 'N/A')),
                                DataCell(Text(collector['phone']?.toString() ?? 'N/A')),
                                DataCell(Text(collector['vehicleType']?.toString() ?? 'N/A')),
                                DataCell(Text(collector['licensePlate']?.toString() ?? 'N/A')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green[100] : Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: isActive ? Colors.green[700] : Colors.red[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    joinedDate != null
                                        ? '${joinedDate.day}/${joinedDate.month}/${joinedDate.year}'
                                        : 'N/A',
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isActive ? Icons.block : Icons.check_circle,
                                          color: isActive ? Colors.red : Colors.green,
                                        ),
                                        onPressed: () => _toggleCollectorStatus(collector['id'], !isActive),
                                        tooltip: isActive ? 'Deactivate Collector' : 'Activate Collector',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.blue),
                                        onPressed: () => _viewCollectorDetails(collector),
                                        tooltip: 'View Details',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCollectorStatus(String collectorId, bool isActive) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.updateCollectorStatus(collectorId, isActive);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collector ${isActive ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCollectors(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating collector status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewCollectorDetails(Map<String, dynamic> collector) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Collector Details: ${collector['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', collector['name']?.toString() ?? 'N/A'),
              _buildDetailRow('Email', collector['email']?.toString() ?? 'N/A'),
              _buildDetailRow('Phone', collector['phone']?.toString() ?? 'N/A'),
              _buildDetailRow('Vehicle Type', collector['vehicleType']?.toString() ?? 'N/A'),
              _buildDetailRow('License Plate', collector['licensePlate']?.toString() ?? 'N/A'),
              _buildDetailRow('Location', collector['location']?.toString() ?? 'N/A'),
              _buildDetailRow('Status', collector['isActive'] == true ? 'Active' : 'Inactive'),
              _buildDetailRow('Collector ID', collector['id']?.toString() ?? 'N/A'),
              if (collector['createdAt'] != null)
                _buildDetailRow('Joined', (collector['createdAt'] as dynamic).toDate().toString()),
              if (collector['lastLogin'] != null)
                _buildDetailRow('Last Login', (collector['lastLogin'] as dynamic).toDate().toString()),
              if (collector['totalPickups'] != null)
                _buildDetailRow('Total Pickups', collector['totalPickups'].toString()),
              if (collector['rating'] != null)
                _buildDetailRow('Rating', '${collector['rating']}/5'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}
