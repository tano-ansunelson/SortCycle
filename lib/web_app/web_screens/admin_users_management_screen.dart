import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../web_providers/admin_provider.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  const AdminUsersManagementScreen({super.key});

  @override
  State<AdminUsersManagementScreen> createState() => _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState extends State<AdminUsersManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final users = await adminProvider.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final phone = user['phone']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
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
                      hintText: 'Search users by name, email, or phone...',
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
                  '${_filteredUsers.length} users',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Users Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
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
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Joined')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredUsers.map((user) {
                            final isActive = user['isActive'] ?? true;
                            final joinedDate = user['createdAt'] != null
                                ? (user['createdAt'] as dynamic).toDate()
                                : null;
                            
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    user['name']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                DataCell(Text(user['email']?.toString() ?? 'N/A')),
                                DataCell(Text(user['phone']?.toString() ?? 'N/A')),
                                DataCell(Text(user['location']?.toString() ?? 'N/A')),
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
                                        onPressed: () => _toggleUserStatus(user['id'], !isActive),
                                        tooltip: isActive ? 'Deactivate User' : 'Activate User',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.blue),
                                        onPressed: () => _viewUserDetails(user),
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

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.updateUserStatus(userId, isActive);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${isActive ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user['name']?.toString() ?? 'N/A'),
              _buildDetailRow('Email', user['email']?.toString() ?? 'N/A'),
              _buildDetailRow('Phone', user['phone']?.toString() ?? 'N/A'),
              _buildDetailRow('Location', user['location']?.toString() ?? 'N/A'),
              _buildDetailRow('Status', user['isActive'] == true ? 'Active' : 'Inactive'),
              _buildDetailRow('User ID', user['id']?.toString() ?? 'N/A'),
              if (user['createdAt'] != null)
                _buildDetailRow('Joined', (user['createdAt'] as dynamic).toDate().toString()),
              if (user['lastLogin'] != null)
                _buildDetailRow('Last Login', (user['lastLogin'] as dynamic).toDate().toString()),
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
}
