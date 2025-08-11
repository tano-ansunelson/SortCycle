import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? _currentUser;
  Map<String, dynamic>? _adminData;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get adminData => _adminData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadAdminData();
      } else {
        _adminData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadAdminData() async {
    if (_currentUser == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      final adminDoc = await _firestore
          .collection('admins')
          .doc(_currentUser!.uid)
          .get();

      if (adminDoc.exists) {
        _adminData = adminDoc.data();
        _error = null;
      } else {
        _error = 'Admin access not found';
        await _auth.signOut();
      }
    } catch (e) {
      _error = 'Error loading admin data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Verify admin access
      final adminDoc = await _firestore
          .collection('admins')
          .doc(_currentUser!.uid)
          .get();

      if (!adminDoc.exists) {
        _error = 'Access denied. Admin privileges required.';
        await _auth.signOut();
        return false;
      }

      return true;
    } catch (e) {
      _error = 'Sign in failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _adminData = null;
      _error = null;
    } catch (e) {
      _error = 'Sign out failed: $e';
    }
    notifyListeners();
  }

  // Admin Management Methods
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      _error = 'Error fetching users: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCollectors() async {
    try {
      final snapshot = await _firestore.collection('collectors').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      _error = 'Error fetching collectors: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPickupRequests() async {
    try {
      final snapshot = await _firestore
          .collection('pickup_requests')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      _error = 'Error fetching pickup requests: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMarketplaceItems() async {
    try {
      final snapshot = await _firestore
          .collection('marketplace_items')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      _error = 'Error fetching marketplace items: $e';
      notifyListeners();
      return [];
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = 'Error updating user status: $e';
      notifyListeners();
    }
  }

  Future<void> updateCollectorStatus(String collectorId, bool isActive) async {
    try {
      await _firestore.collection('collectors').doc(collectorId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = 'Error updating collector status: $e';
      notifyListeners();
    }
  }

  Future<void> deleteMarketplaceItem(String itemId) async {
    try {
      await _firestore.collection('marketplace_items').doc(itemId).delete();
    } catch (e) {
      _error = 'Error deleting marketplace item: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final collectorsSnapshot = await _firestore.collection('collectors').get();
      final requestsSnapshot = await _firestore.collection('pickup_requests').get();
      final itemsSnapshot = await _firestore.collection('marketplace_items').get();

      return {
        'totalUsers': usersSnapshot.size,
        'totalCollectors': collectorsSnapshot.size,
        'totalPickupRequests': requestsSnapshot.size,
        'totalMarketplaceItems': itemsSnapshot.size,
        'activeUsers': usersSnapshot.docs.where((doc) => doc.data()['isActive'] == true).length,
        'activeCollectors': collectorsSnapshot.docs.where((doc) => doc.data()['isActive'] == true).length,
        'pendingRequests': requestsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length,
        'completedRequests': requestsSnapshot.docs.where((doc) => doc.data()['status'] == 'completed').length,
      };
    } catch (e) {
      _error = 'Error fetching dashboard stats: $e';
      notifyListeners();
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
