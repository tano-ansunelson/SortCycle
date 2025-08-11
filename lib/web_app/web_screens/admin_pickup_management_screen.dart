import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../web_providers/admin_provider.dart';

class AdminPickupManagementScreen extends StatefulWidget {
  const AdminPickupManagementScreen({super.key});

  @override
  State<AdminPickupManagementScreen> createState() => _AdminPickupManagementScreenState();
}

class _AdminPickupManagementScreenState extends State<AdminPickupManagementScreen> {
  List<Map<String, dynamic>> _pickupRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPickupRequests();
  }

  Future<void> _loadPickupRequests() async {
    setState(() => _isLoading = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final requests = await adminProvider.getPickupRequests();
    setState(() {
      _pickupRequests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPickupRequests,
            tooltip: 'Refresh Requests',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pickupRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No pickup requests found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _pickupRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pickupRequests[index];
                    final status = request['status']?.toString() ?? 'pending';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(request['userName']?.toString() ?? 'Unknown User'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Location: ${request['location'] ?? 'N/A'}'),
                            Text('Waste Type: ${request['wasteType'] ?? 'N/A'}'),
                            Text('Status: $status'),
                            if (request['collectorName'] != null)
                              Text('Collector: ${request['collectorName']}'),
                          ],
                        ),
                        trailing: Icon(
                          Icons.recycling,
                          color: _getStatusColor(status),
                        ),
                        onTap: () => _viewRequestDetails(request),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
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

  void _viewRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pickup Request Details'),
        content: Text('Request ID: ${request['id']}\nUser: ${request['userName']}\nLocation: ${request['location']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
