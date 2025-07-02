import 'package:flutter/material.dart';

class PickupManagementPage extends StatefulWidget {
  const PickupManagementPage({super.key});
  @override
  State<PickupManagementPage> createState() => _PickupManagementPageState();
}

class _PickupManagementPageState extends State<PickupManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomingRequestsTab(), _buildYourPickupsTab()],
      ),
    );
  }

  Widget _buildIncomingRequestsTab() {
    final incomingRequests = [
      {
        'id': '#R001',
        'address': '123 Elm Street, Kumasi',
        'distance': '2.5 km',
        'items': ['Plastic bottles', 'Paper'],
        'requestTime': '10 minutes ago',
        'scheduledTime': 'Today, 2:00 PM',
        'estimatedEarning': 'GH₵ 35',
      },
      {
        'id': '#R002',
        'address': '456 Maple Ave, Kumasi',
        'distance': '1.8 km',
        'items': ['Electronics', 'Metal cans'],
        'requestTime': '25 minutes ago',
        'scheduledTime': 'Today, 3:30 PM',
        'estimatedEarning': 'GH₵ 50',
      },
      {
        'id': '#R003',
        'address': '789 Cedar Rd, Kumasi',
        'distance': '3.2 km',
        'items': ['Glass bottles', 'Cardboard'],
        'requestTime': '1 hour ago',
        'scheduledTime': 'Tomorrow, 9:00 AM',
        'estimatedEarning': 'GH₵ 25',
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: incomingRequests.length,
        itemBuilder: (context, index) {
          final request = incomingRequests[index];
          return _buildIncomingRequestCard(request);
        },
      ),
    );
  }

  Widget _buildYourPickupsTab() {
    final yourPickups = [
      {
        'id': '#P001',
        'address': '321 Oak Street, Kumasi',
        'distance': '1.2 km',
        'items': ['Plastic', 'Paper', 'Glass'],
        'status': 'In Progress',
        'acceptedTime': '2 hours ago',
        'scheduledTime': 'Today, 1:00 PM',
        'earning': 'GH₵ 40',
      },
      {
        'id': '#P002',
        'address': '654 Pine Ave, Kumasi',
        'distance': '2.1 km',
        'items': ['Electronics'],
        'status': 'Accepted',
        'acceptedTime': '1 hour ago',
        'scheduledTime': 'Today, 4:00 PM',
        'earning': 'GH₵ 60',
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: yourPickups.length,
        itemBuilder: (context, index) {
          final pickup = yourPickups[index];
          return _buildYourPickupCard(pickup);
        },
      ),
    );
  }

  Widget _buildIncomingRequestCard(Map<String, dynamic> request) {
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
                  request['id']!,
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                request['estimatedEarning']!,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request['address']!,
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
              Icon(Icons.directions, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['distance']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                request['scheduledTime']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Items: ${request['items'].join(', ')}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested ${request['requestTime']}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Decline request
                    _showDeclineDialog(request['id']!);
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
                child: ElevatedButton(
                  onPressed: () {
                    // Accept request
                    _showAcceptDialog(request['id']!);
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

  Widget _buildYourPickupCard(Map<String, dynamic> pickup) {
    final isInProgress = pickup['status'] == 'In Progress';
    final statusColor = isInProgress ? Colors.blue : Colors.orange;

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
                  pickup['id']!,
                  style: TextStyle(
                    color: statusColor[700],
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
                  pickup['status']!,
                  style: TextStyle(
                    color: statusColor[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                pickup['earning']!,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pickup['address']!,
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
              Icon(Icons.directions, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                pickup['distance']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(
                pickup['scheduledTime']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Items: ${pickup['items'].join(', ')}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Accepted ${pickup['acceptedTime']}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isInProgress) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Start pickup
                      _startPickup(pickup['id']!);
                    },
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
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate or complete
                    if (isInProgress) {
                      _completePickup(pickup['id']!);
                    } else {
                      _navigateToLocation(pickup['address']!);
                    }
                  },
                  icon: Icon(
                    isInProgress ? Icons.check : Icons.navigation,
                    size: 18,
                  ),
                  label: Text(isInProgress ? 'Complete' : 'Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInProgress ? Colors.green : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pickup request accepted!')),
              );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pickup request declined')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _startPickup(String pickupId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pickup $pickupId started!')));
  }

  void _completePickup(String pickupId) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pickup completed successfully!')),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _navigateToLocation(String address) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening navigation to $address')));
  }
}
