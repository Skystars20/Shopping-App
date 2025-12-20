import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  DocumentSnapshot? _userData;

  DocumentSnapshot? get userData => _userData;

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      notifyListeners();
    }
  }
}
