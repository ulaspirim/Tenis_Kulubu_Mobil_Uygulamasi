import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tenis_kulubu/shared/models/models.dart';
import 'package:tenis_kulubu/core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Mevcut kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut Firebase kullanıcısı
  User? get currentUser => _auth.currentUser;

  // E-posta ile giriş
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Giriş başarısız');

    return _getUserModel(user.uid);
  }

  // Kayıt ol
  Future<UserModel> registerWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    required String membershipNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Kayıt başarısız');

    // Kullanıcı adını güncelle
    await user.updateDisplayName('$firstName $lastName');

    // Firestore'a kullanıcı kaydı oluştur
    final userModel = UserModel(
      id: user.uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      membershipType: AppConstants.membershipStandard,
      membershipStatus: AppConstants.membershipActive,
      membershipExpiry: DateTime.now().add(const Duration(days: 365)),
      membershipNumber: membershipNumber,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kullanıcı profilini getir
  Future<UserModel> _getUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) throw Exception('Kullanıcı bulunamadı');
    return UserModel.fromFirestore(doc);
  }

  // Kullanıcı profilini stream ile dinle
  Stream<UserModel?> userStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Profil güncelle
  Future<void> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }

  // Şifre değiştir
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı bulunamadı');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Mevcut kullanıcı model provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return repo.userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
