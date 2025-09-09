import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all payment transactions for a user
  static Stream<List<Map<String, dynamic>>> getUserPayments(String userId) {
    return _firestore
        .collection('pickup_requests')
        .where('userId', isEqualTo: userId)
        .where('paymentStatus', isEqualTo: 'paid')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'pickup';
        return data;
      }).toList();
    });
  }

  /// Get marketplace purchases for a user
  static Stream<List<Map<String, dynamic>>> getUserMarketplacePurchases(String userId) {
    return _firestore
        .collection('purchases')
        .where('buyerId', isEqualTo: userId)
        .where('paymentStatus', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'marketplace';
        return data;
      }).toList();
    });
  }

  /// Get combined payment history (both pickup and marketplace)
  static Future<List<Map<String, dynamic>>> getCombinedPaymentHistory(String userId) async {
    try {
      // Get pickup payments
      final pickupQuery = await _firestore
          .collection('pickup_requests')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'paid')
          .orderBy('createdAt', descending: true)
          .get();

      // Get marketplace purchases
      final marketplaceQuery = await _firestore
          .collection('purchases')
          .where('buyerId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      // Combine and sort by date
      List<Map<String, dynamic>> allPayments = [];

      // Add pickup payments
      for (var doc in pickupQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'pickup';
        allPayments.add(data);
      }

      // Add marketplace purchases
      for (var doc in marketplaceQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'marketplace';
        allPayments.add(data);
      }

      // Sort by creation date (newest first)
      allPayments.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        return bDate.compareTo(aDate);
      });

      return allPayments;
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  /// Calculate total spent by user
  static Future<Map<String, dynamic>> getPaymentSummary(String userId) async {
    try {
      final payments = await getCombinedPaymentHistory(userId);
      
      double totalSpent = 0.0;
      int pickupCount = 0;
      int marketplaceCount = 0;

      for (var payment in payments) {
        if (payment['type'] == 'pickup') {
          final amount = (payment['totalAmount'] ?? 0.0).toDouble();
          totalSpent += amount;
          pickupCount++;
        } else if (payment['type'] == 'marketplace') {
          final transactionDetails = payment['transactionDetails'] as Map<String, dynamic>?;
          final amount = (transactionDetails?['totalAmount'] ?? 0.0).toDouble();
          totalSpent += amount;
          marketplaceCount++;
        }
      }

      return {
        'totalSpent': totalSpent,
        'totalTransactions': payments.length,
        'pickupCount': pickupCount,
        'marketplaceCount': marketplaceCount,
        'averageTransaction': payments.isNotEmpty ? totalSpent / payments.length : 0.0,
      };
    } catch (e) {
      print('Error calculating payment summary: $e');
      return {
        'totalSpent': 0.0,
        'totalTransactions': 0,
        'pickupCount': 0,
        'marketplaceCount': 0,
        'averageTransaction': 0.0,
      };
    }
  }

  /// Get payment details for a specific transaction
  static Future<Map<String, dynamic>?> getPaymentDetails(String paymentId, String type) async {
    try {
      String collection = type == 'pickup' ? 'pickup_requests' : 'purchases';
      
      final doc = await _firestore.collection(collection).doc(paymentId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['type'] = type;
        return data;
      }
      
      return null;
    } catch (e) {
      print('Error fetching payment details: $e');
      return null;
    }
  }

  /// Format payment amount for display
  static String formatAmount(double amount) {
    return 'GHS ${amount.toStringAsFixed(2)}';
  }

  /// Get payment status color
  static int getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'paid':
        return 0xFF4CAF50; // Green
      case 'pending':
      case 'pending_confirmation':
        return 0xFFFF9800; // Orange
      case 'cancelled':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Get payment type icon
  static String getPaymentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pickup':
        return 'local_shipping_rounded';
      case 'marketplace':
        return 'shopping_bag_rounded';
      default:
        return 'payment_rounded';
    }
  }

  /// Get payment history from dedicated collection
  static Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final query = await _firestore
          .collection('payment_history')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  /// Create payment history record for pickup
  static Future<void> createPickupPaymentRecord({
    required String requestId,
    required String userId,
    required double amount,
    required String status,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      await _firestore.collection('payment_history').add({
        'type': 'pickup',
        'requestId': requestId,
        'userId': userId,
        'amount': amount,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'requestData': requestData,
        'description': 'Waste pickup service',
      });
    } catch (e) {
      print('Error creating pickup payment record: $e');
    }
  }

  /// Create payment history record for marketplace
  static Future<void> createMarketplacePaymentRecord({
    required String purchaseId,
    required String userId,
    required double amount,
    required String status,
    required Map<String, dynamic> purchaseData,
  }) async {
    try {
      await _firestore.collection('payment_history').add({
        'type': 'marketplace',
        'purchaseId': purchaseId,
        'userId': userId,
        'amount': amount,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'purchaseData': purchaseData,
        'description': 'EcoMarketplace purchase',
      });
    } catch (e) {
      print('Error creating marketplace payment record: $e');
    }
  }

  /// Update payment history record status
  static Future<void> updatePaymentHistoryStatus({
    required String paymentId,
    required String newStatus,
  }) async {
    try {
      await _firestore.collection('payment_history').doc(paymentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating payment history status: $e');
    }
  }
}
