import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Admin data
  Map<String, dynamic>? _adminData;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Statistics
  int _totalUsers = 0;
  int _totalCollectors = 0;
  int _totalPickupRequests = 0;
  int _totalMarketplaceItems = 0;
  int _todayPickups = 0;
  int _pendingPickups = 0;
  
  // Getters
  Map<String, dynamic>? get adminData => _adminData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _totalUsers;
  int get totalCollectors => _totalCollectors;
  int get totalPickupRequests => _totalPickupRequests;
  int get totalMarketplaceItems => _totalMarketplaceItems;
  int get todayPickups => _todayPickups;
  int get pendingPickups => _pendingPickups;

  // Initialize admin data
  Future<void> initializeAdmin() async {
    try {
      _setLoading(true);
      final user = _auth.currentUser;
      if (user != null) {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get();
        
        if (adminDoc.exists) {
          _adminData = adminDoc.data();
          await _loadStatistics();
        }
      }
    } catch (e) {
      _setError('Failed to initialize admin: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load dashboard statistics
  Future<void> _loadStatistics() async {
    try {
      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;
      
      // Get total collectors
      final collectorsSnapshot = await _firestore.collection('collectors').get();
      _totalCollectors = collectorsSnapshot.docs.length;
      
      // Get total pickup requests
      final requestsSnapshot = await _firestore.collection('pickup_requests').get();
      _totalPickupRequests = requestsSnapshot.docs.length;
      
      // Get total marketplace items
      final itemsSnapshot = await _firestore.collection('marketplace_items').get();
      _totalMarketplaceItems = itemsSnapshot.docs.length;
      
      // Get today's pickups
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final todaySnapshot = await _firestore
          .collection('pickup_requests')
          .where('pickupDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('pickupDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      _todayPickups = todaySnapshot.docs.length;
      
      // Get pending pickups
      final pendingSnapshot = await _firestore
          .collection('pickup_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingPickups = pendingSnapshot.docs.length;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load statistics: $e');
    }
  }

  // Refresh statistics
  Future<void> refreshStatistics() async {
    await _loadStatistics();
  }

  // Get users list
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get collectors list
  Stream<QuerySnapshot> getCollectorsStream() {
    return _firestore
        .collection('collectors')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get pickup requests stream
  Stream<QuerySnapshot> getPickupRequestsStream() {
    return _firestore
        .collection('pickup_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get marketplace items stream
  Stream<QuerySnapshot> getMarketplaceItemsStream() {
    return _firestore
        .collection('marketplace_items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'status': status});
      notifyListeners();
    } catch (e) {
      _setError('Failed to update user status: $e');
    }
  }

  // Update collector status
  Future<void> updateCollectorStatus(String collectorId, String status) async {
    try {
      await _firestore
          .collection('collectors')
          .doc(collectorId)
          .update({'status': status});
      notifyListeners();
    } catch (e) {
      _setError('Failed to update collector status: $e');
    }
  }

  // Update pickup request status
  Future<void> updatePickupStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .update({'status': status});
      notifyListeners();
    } catch (e) {
      _setError('Failed to update pickup status: $e');
    }
  }

  // Update marketplace item status
  Future<void> updateMarketplaceItemStatus(String itemId, String status) async {
    try {
      await _firestore
          .collection('marketplace_items')
          .doc(itemId)
          .update({'isActive': status == 'active'});
      notifyListeners();
    } catch (e) {
      _setError('Failed to update marketplace item status: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      await _loadStatistics();
    } catch (e) {
      _setError('Failed to delete user: $e');
    }
  }

  // Delete collector
  Future<void> deleteCollector(String collectorId) async {
    try {
      await _firestore.collection('collectors').doc(collectorId).delete();
      await _loadStatistics();
    } catch (e) {
      _setError('Failed to delete collector: $e');
    }
  }

  // Delete pickup request
  Future<void> deletePickupRequest(String requestId) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).delete();
      await _loadStatistics();
    } catch (e) {
      _setError('Failed to delete pickup request: $e');
    }
  }

  // Delete marketplace item
  Future<void> deleteMarketplaceItem(String itemId) async {
    try {
      await _firestore.collection('marketplace_items').doc(itemId).delete();
      await _loadStatistics();
    } catch (e) {
      _setError('Failed to delete marketplace item: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _adminData = null;
      _resetStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    }
  }

  void _resetStatistics() {
    _totalUsers = 0;
    _totalCollectors = 0;
    _totalPickupRequests = 0;
    _totalMarketplaceItems = 0;
    _todayPickups = 0;
    _pendingPickups = 0;
  }
}
