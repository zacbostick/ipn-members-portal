import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;

  UserProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (userSnapshot.exists) {
        userData = userSnapshot.data() as Map<String, dynamic>?;
        notifyListeners();
      } else {
        userData = null;
        notifyListeners();
      }
    } else {
      userData = null;
      notifyListeners();
    }
  }

  String? getFirstName() {
    return userData?['first_name'];
  }

  String? getAvatarUrl() {
    return userData?['avatarUrl'];
  }
}
