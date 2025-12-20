import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  static User? _currentUser;
  static DocumentSnapshot? _userData;
  static final Map<String, DocumentSnapshot> _userCache = {};

  static Future<void> initialize() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();
    }
  }

  static Future<DocumentSnapshot> getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    _userCache[userId] = userData;
    return userData;
  }

  static DocumentSnapshot? get userData => _userData;
  static User? get currentUser => _currentUser;

  static Future<void> refreshUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();
    }
  }

  static void clearCache() {
    _userCache.clear();
    _userData = null;
    _currentUser = null;
  }
}
