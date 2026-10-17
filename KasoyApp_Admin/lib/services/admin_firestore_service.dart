import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_user.dart';

class AdminFirestoreService {
  AdminFirestoreService._();
  static final AdminFirestoreService instance = AdminFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get adminUsers =>
      _db.collection('admin_users');

  CollectionReference<Map<String, dynamic>> get quotes =>
      _db.collection('quotes');

  Future<void> saveAdminUser(AdminUser admin) async {
    await adminUsers.doc(admin.uid).set(
          admin.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<AdminUser?> getAdminUser(String uid) async {
    final snap = await adminUsers.doc(uid).get();
    if (!snap.exists) return null;
    return AdminUser.fromDoc(snap);
  }

  Stream<int> watchTotalRequests() {
    return quotes.snapshots().map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> watchRecentQuotes({int limit = 5}) {
    return quotes
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}