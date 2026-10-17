import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_user.dart';
import 'admin_firestore_service.dart';

class AdminAuthService {
  AdminAuthService._();
  static final AdminAuthService instance = AdminAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<bool> hasAnyAdmin() async {
    try {
      final snap =
          await AdminFirestoreService.instance.adminUsers.limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('hasAnyAdmin failed: $e');
      return false;
    }
  }

  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final uid = cred.user!.uid;
    final profile = await AdminFirestoreService.instance.getAdminUser(uid);
    if (profile == null) {
      await _auth.signOut();
      throw AdminAuthException(
        'This account is not registered as an admin.',
      );
    }
    return profile;
  }

  Future<AdminUser> registerFirstAdmin({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final anyAdmin = await hasAnyAdmin();
    if (anyAdmin) {
      throw AdminAuthException(
        'An admin account already exists. Only one admin can register.',
      );
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(fullName);
    final admin = AdminUser(
      uid: uid,
      email: email.trim(),
      fullName: fullName.trim(),
      role: 'super_admin',
      createdAt: DateTime.now(),
    );
    await AdminFirestoreService.instance.saveAdminUser(admin);
    return admin;
  }

  Future<void> signOut() => _auth.signOut();
}

class AdminAuthException implements Exception {
  AdminAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}