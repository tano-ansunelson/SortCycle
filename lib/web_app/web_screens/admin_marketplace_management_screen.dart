import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../web_providers/admin_provider.dart';

class AdminMarketplaceManagementScreen extends StatefulWidget {
  const AdminMarketplaceManagementScreen({super.key});

  @override
  State<AdminMarketplaceManagementScreen> createState() => _AdminMarketplaceManagementScreenState();
}

class _AdminMarketplaceManagementScreenState extends State<AdminMarketplaceManagementScreen> {
  List<Map<String, dynamic>> _marketplaceItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketplaceItems();
  }

  Future<void> _loadMarketplaceItems() async {
    setState(() => _isLoading = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final items = await adminProvider.getMarketplaceItems();
    setState(() {
      _marketplaceItems = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarketplaceItems,
            tooltip: 'Refresh Items',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _marketplaceItems.isEmpty
              ? const Center(
                  child: Text(
                    'No marketplace items found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _marketplaceItems.length,
                  itemBuilder: (context, index) {
                    final item = _marketplaceItems[index];
                    final price = item['price']?.toString() ?? 'N/A';
                    final status = item['status']?.toString() ?? 'active';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: item['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                        title: Text(
                          item['title']?.toString() ?? 'Untitled Item',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price: \$$price'),
                            Text('Category: ${item['category'] ?? 'N/A'}'),
                            Text('Seller: ${item['sellerName'] ?? 'Unknown'}'),
                            Text('Status: $status'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') {
                              _viewItemDetails(item);
                            } else if (value == 'delete') {
                              _deleteItem(item['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Item'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _viewItemDetails(item),
                      ),
                    );
                  },
                ),
    );
  }

  void _viewItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Details: ${item['title']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['imageUrl'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['imageUrl'],
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow('Title', item['title']?.toString() ?? 'N/A'),
              _buildDetailRow('Description', item['description']?.toString() ?? 'N/A'),
              _buildDetailRow('Price', '\$${item['price'] ?? 'N/A'}'),
              _buildDetailRow('Category', item['category']?.toString() ?? 'N/A'),
              _buildDetailRow('Seller', item['sellerName']?.toString() ?? 'N/A'),
              _buildDetailRow('Status', item['status']?.toString() ?? 'N/A'),
              _buildDetailRow('Item ID', item['id']?.toString() ?? 'N/A'),
              if (item['createdAt'] != null)
                _buildDetailRow('Listed', (item['createdAt'] as dynamic).toDate().toString()),
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

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        await adminProvider.deleteMarketplaceItem(itemId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMarketplaceItems(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
