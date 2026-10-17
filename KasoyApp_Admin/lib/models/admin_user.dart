import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin account record stored in Firestore at:
///   admin_users/{uid}
///
/// The Admin's email/password live in Firebase Auth. This document holds
/// only the profile data + role flag.
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String role; // 'admin' | 'super_admin'
  final DateTime? createdAt;

  factory AdminUser.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminUser(
      uid: doc.id,
      email: (d['email'] as String?) ?? '',
      fullName: (d['fullName'] as String?) ?? 'Admin',
      role: (d['role'] as String?) ?? 'admin',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'fullName': fullName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };
}