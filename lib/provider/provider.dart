import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  String? get email => _email;
  String? get phone => _phone;
  String? get town => _town;
  String? get name => _username;

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
  int _sortScore = 0;

  int get sortScore => _sortScore;

  Future<void> fetchSortScore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = doc.data();
      if (data != null && data['sortScore'] is int) {
        _sortScore = data['sortScore'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch sortScore: $e");
    }
  }

  Future<void> addPoints(int points) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final currentScore = (snapshot.data()?['sortScore'] ?? 0) as int;
        final newScore = currentScore + points;

        transaction.update(userRef, {'sortScore': newScore});
        _sortScore = newScore;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Error updating sortScore: $e");
    }
  }

  int _rank = 0;
  int get rank => _rank;

  Future<void> fetchUserRank() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('sortScore', descending: true)
          .get();

      int currentIndex = 0;
      for (var doc in querySnapshot.docs) {
        currentIndex++;
        if (doc.id == userId) {
          _rank = currentIndex;
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      debugPrint("Error fetching rank: $e");
    }
  }
}
