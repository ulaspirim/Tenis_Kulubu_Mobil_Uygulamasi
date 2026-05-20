import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tenis_kulubu/shared/models/models.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Tüm üyeleri getir
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  // Yeni üye ekle (Admin Firebase Auth + Firestore)
  Future<void> addMember({
    required String firstName,
    required String lastName,
    required String email,
    required String membershipType,
    required String membershipNumber,
    String? phone,
    required DateTime membershipExpiry,
  }) async {
    // Firebase Auth'da kullanıcı oluştur (geçici şifre)
    final tempPassword = 'Atik${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: tempPassword,
    );

    final uid = credential.user!.uid;

    // Firestore'a kaydet
    final user = UserModel(
      id: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      membershipType: membershipType,
      membershipStatus: 'active',
      membershipExpiry: membershipExpiry,
      membershipNumber: membershipNumber,
      createdAt: DateTime.now(),
      isFirstLogin: true,
    );

    await _firestore.collection('users').doc(uid).set(user.toFirestore());

    // Şifre sıfırlama e-postası gönder
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Üyelik durumunu güncelle
  Future<void> updateMembershipStatus({
    required String userId,
    required String status,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'membershipStatus': status,
    });
  }

  // Üyelik süresini uzat
  Future<void> extendMembership({
    required String userId,
    required DateTime newExpiry,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'membershipExpiry': Timestamp.fromDate(newExpiry),
      'membershipStatus': 'active',
    });
  }

  // Üye sil
  Future<void> deleteMember(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Üye düzenle
  Future<void> updateMember({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? membershipType,
    String? membershipNumber,
    DateTime? membershipExpiry,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (membershipType != null) updates['membershipType'] = membershipType;
    if (membershipNumber != null) updates['membershipNumber'] = membershipNumber;
    if (membershipExpiry != null) updates['membershipExpiry'] = Timestamp.fromDate(membershipExpiry);

    await _firestore.collection('users').doc(userId).update(updates);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});