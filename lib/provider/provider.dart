import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// }
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  String? _email;

  String? get username => _username;
  String? get email => _email;

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        _username = doc.data()?['name'];
        _email = doc.data()?['email'];
        notifyListeners();
      }
    }
  }
}

class CollectorProvider with ChangeNotifier {
  String? _email;
  String? _phone;
  String? _town;
  String? _username;
  //final bool _isLoading = false;

  String? get email => _email;
  String? get phone => _phone;
  String? get town => _town;
  String? get name => _username;
  //bool get isLoading => _isLoading;

  Future<void> fetchCollectorData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('collectors')
          .doc(uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _email = data['email'];
        _phone = data['phone'];
        _town = data['town'];
        _username = data['name'];
        notifyListeners();
      }
    }
  }
}

class SortScoreProvider with ChangeNotifier {
  int _totalPickups = 0;
  int _monthlyPickups = 0;
  int _rank = 0;
  bool _isLoading = false;

  int get totalPickups => _totalPickups;
  int get monthlyPickups => _monthlyPickups;
  int get rank => _rank;
  bool get isLoading => _isLoading;

  SortScoreProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await calculatePickupStats(userId);
    }
  }

  Future<void> calculatePickupStats(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final snapshot = await FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('userId', isEqualTo: userId)
          .get();

      int completed = 0;
      int completedThisMonth = 0;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final status = doc['status'];
        final timestamp = (doc['createdAt'] as Timestamp?)?.toDate();

        if (status == 'completed' && timestamp != null) {
          completed++;

          if (timestamp.month == now.month && timestamp.year == now.year) {
            completedThisMonth++;
          }
        }
      }

      _totalPickups = completed;
      _monthlyPickups = completedThisMonth;

      await fetchUserRank(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error calculating pickups: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserRank(String userId) async {
    try {
      final users = await FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('status', isEqualTo: 'completed')
          .get();

      final Map<String, int> userCompletionCounts = {};

      for (var doc in users.docs) {
        final uid = doc['userId'];
        userCompletionCounts[uid] = (userCompletionCounts[uid] ?? 0) + 1;
      }

      final sorted = userCompletionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (int i = 0; i < sorted.length; i++) {
        if (sorted[i].key == userId) {
          _rank = i + 1;
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching rank: $e");
    }
  }
}
