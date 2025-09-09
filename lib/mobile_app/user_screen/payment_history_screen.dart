import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/mobile_app/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String userId;

  const PaymentHistoryScreen({super.key, required this.userId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  String _selectedFilter = 'all'; // all, pickup, marketplace
  double _totalSpent = 0.0;
  int _totalTransactions = 0;
  List<Map<String, dynamic>> _allPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get from dedicated payment_history collection first
      final payments = await PaymentService.getPaymentHistory(widget.userId);

      // If no dedicated payment history, fall back to combined method
      if (payments.isEmpty) {
        final combinedPayments = await PaymentService.getCombinedPaymentHistory(
          widget.userId,
        );
        setState(() {
          _allPayments = combinedPayments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allPayments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading payments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildFilterTabs(),
          Expanded(child: _buildPaymentList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Spent',
              'GHS ${_totalSpent.toStringAsFixed(2)}',
              Icons.account_balance_wallet_rounded,
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Transactions',
              _totalTransactions.toString(),
              Icons.receipt_long_rounded,
              const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('All', 'all'),
          _buildFilterTab('Pickups', 'pickup'),
          _buildFilterTab('Marketplace', 'marketplace'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          _calculateTotals(_allPayments);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      );
    }

    final filteredPayments = _getFilteredPayments();

    if (filteredPayments.isEmpty) {
      return Center(
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No payments yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment history will appear here once you start using our services.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    _calculateTotals(filteredPayments);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = filteredPayments[index];

        return SlideTransition(
          position: _animationController.drive(
            Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: _buildPaymentCard(payment, payment['id']),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredPayments() {
    if (_selectedFilter == 'all') {
      return _allPayments;
    } else if (_selectedFilter == 'pickup') {
      return _allPayments
          .where((payment) => payment['type'] == 'pickup')
          .toList();
    } else if (_selectedFilter == 'marketplace') {
      return _allPayments
          .where((payment) => payment['type'] == 'marketplace')
          .toList();
    }
    return _allPayments;
  }

  void _calculateTotals(List<Map<String, dynamic>> payments) {
    double total = 0.0;
    int count = 0;

    for (var payment in payments) {
      if (payment['type'] == 'pickup') {
        // Handle both old and new payment structure
        final amount = (payment['amount'] ?? payment['totalAmount'] ?? 0.0)
            .toDouble();
        total += amount;
        count++;
      } else if (payment['type'] == 'marketplace') {
        // Handle both old and new payment structure
        final transactionDetails =
            payment['transactionDetails'] as Map<String, dynamic>?;
        final amount =
            (payment['amount'] ?? transactionDetails?['totalAmount'] ?? 0.0)
                .toDouble();
        total += amount;
        count++;
      }
    }

    if (mounted) {
      setState(() {
        _totalSpent = total;
        _totalTransactions = count;
      });
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> data, String paymentId) {
    String title;
    String subtitle;
    double amount;
    String status;
    Timestamp? timestamp;
    IconData icon;
    Color iconColor;

    if (data['type'] == 'pickup') {
      title = 'Waste Pickup';
      // Handle both old and new structure
      final metadata = data['metadata'] as Map<String, dynamic>?;
      subtitle =
          metadata?['userTown'] ?? data['userTown'] ?? 'Unknown Location';
      amount = (data['amount'] ?? data['totalAmount'] ?? 0.0).toDouble();
      status = data['status'] ?? 'Unknown';
      timestamp = data['createdAt'] as Timestamp?;
      icon = Icons.local_shipping_rounded;
      iconColor = const Color(0xFF2196F3);
    } else {
      // Handle both old and new structure
      final metadata = data['metadata'] as Map<String, dynamic>?;
      final itemDetails = data['itemDetails'] as Map<String, dynamic>?;
      title =
          metadata?['itemName'] ?? itemDetails?['name'] ?? 'Marketplace Item';
      subtitle = 'EcoMarketplace Purchase';
      final transactionDetails =
          data['transactionDetails'] as Map<String, dynamic>?;
      amount = (data['amount'] ?? transactionDetails?['totalAmount'] ?? 0.0)
          .toDouble();
      status = data['status'] ?? 'Unknown';
      timestamp = data['createdAt'] as Timestamp?;
      icon = Icons.shopping_bag_rounded;
      iconColor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'GHS ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(status),
                  ],
                ),
              ],
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(timestamp.toDate()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${paymentId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
      case 'pending_confirmation':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
