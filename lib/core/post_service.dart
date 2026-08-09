import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postServiceProvider = Provider<PostService>((ref) => PostService());

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadPost(String userId, File imageFile, String caption) async {
    final bytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(bytes);

    await _firestore.collection('posts').add({
      'uploaderId': userId,
      'imageBase64': base64Image,
      'caption': caption,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  Stream<QuerySnapshot> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
