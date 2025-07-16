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
