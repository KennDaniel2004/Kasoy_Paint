import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized wrapper around all Cloud Firestore reads/writes for this app.
///
/// Firestore layout used:
///   users/{uid} : {
///     fullName, email, phone, createdAt,
///     biometricEnabled, biometricUpdatedAt
///   }
///
/// NOTE: The actual fingerprint template never touches Firebase. Fingerprint
/// scanning is handled entirely on-device by the phone's OS (via the
/// `local_auth` package). All this service stores is a flag that says
/// "this account has fingerprint login turned on", which is useful for
/// showing the right UI and for any admin dashboard you build later.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveRegisteredUser({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _users.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'biometricEnabled': false,
    }, SetOptions(merge: true));
  }

  /// Records whether this account has fingerprint / biometric login enabled.
  Future<void> setBiometricEnabled(String uid, bool enabled) async {
    await _users.doc(uid).set({
      'biometricEnabled': enabled,
      'biometricUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isBiometricEnabled(String uid) async {
    final snap = await _users.doc(uid).get();
    return (snap.data()?['biometricEnabled'] as bool?) ?? false;
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data();
  }
}