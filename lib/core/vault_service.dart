import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vaultServiceProvider = Provider((ref) => VaultService());

class VaultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setupMasterPin(String uid, String pin) async {
    await _firestore.collection('users').doc(uid).set({
      'vaultPin': pin,
    }, SetOptions(merge: true));

    // Auto-initialize standard vaults on setup
    await createVault(uid, 'Classified intel');
    await createVault(uid, 'Private Passwords');
  }

  Future<bool> verifyPin(String uid, String inputPin) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['vaultPin'] == null) return false;
    return data['vaultPin'] == inputPin;
  }

  Future<bool> hasPinSetup(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    return data != null && data['vaultPin'] != null;
  }

  Stream<QuerySnapshot> getUserVaults(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vaults')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createVault(String uid, String name) async {
    await _firestore.collection('users').doc(uid).collection('vaults').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getVaultItems(String uid, String vaultId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vaults')
        .doc(vaultId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addVaultItem(
    String uid,
    String vaultId, {
    String? text,
    String? imageBase64,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('vaults')
        .doc(vaultId)
        .collection('items')
        .add({
          if (text != null && text.isNotEmpty) 'text': text,
          if (imageBase64 != null) 'imageBase64': imageBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
