import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storyServiceProvider = Provider<StoryService>((ref) => StoryService());

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadStory(
    String userId,
    File imageFile,
    String caption,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(bytes);

    await _firestore.collection('stories').add({
      'uploaderId': userId,
      'imageBase64': base64Image,
      'caption': caption,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getActiveStories() {
    // Only return stories from the last 24 hours
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('stories')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(oneDayAgo),
        )
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
