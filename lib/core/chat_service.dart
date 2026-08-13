import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> updateChatTheme(
    String userId1,
    String userId2,
    String themeKey,
  ) async {
    final String chatRoomId = _getChatRoomId(userId1, userId2);
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'theme': themeKey,
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage(
    String receiverId,
    String message,
    DateTime? unlockTime,
    String senderId, {
    bool isVaultMessage = false,
  }) async {
    final String chatRoomId = _getChatRoomId(senderId, receiverId);

    final roomDoc = _firestore.collection('chat_rooms').doc(chatRoomId);
    final roomSnapshot = await roomDoc.get();

    // Check if this is the first message (establishing the room metadata)
    if (!roomSnapshot.exists) {
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final isPrivate = receiverDoc.data()?['isPrivate'] ?? false;

      await roomDoc.set({
        'users': [senderId, receiverId],
        'status': isPrivate ? 'requested' : 'accepted',
        'initiator': senderId,
      });
    }

    final newMessage = {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'unlockTime': unlockTime?.millisecondsSinceEpoch,
      if (isVaultMessage) 'isVaultMessage': true,
    };

    await roomDoc.collection('messages').add(newMessage);

    await roomDoc.set({
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendImageMessage(
    String receiverId,
    File imageFile,
    DateTime? unlockTime,
    String senderId,
    int? viewLimit,
  ) async {
    final String chatRoomId = _getChatRoomId(senderId, receiverId);

    // 1. Convert to Base64 String (Bypassing Firebase Storage entirely)
    final bytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(bytes);

    // 2. Setup room if new (metadata injection check)
    final roomDoc = _firestore.collection('chat_rooms').doc(chatRoomId);
    final roomSnapshot = await roomDoc.get();
    if (!roomSnapshot.exists) {
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final isPrivate = receiverDoc.data()?['isPrivate'] ?? false;
      await roomDoc.set({
        'users': [senderId, receiverId],
        'status': isPrivate ? 'requested' : 'accepted',
        'initiator': senderId,
      });
    }

    // 3. Save Message explicitly containing base64 encoded string
    final newMessage = {
      'senderId': senderId,
      'receiverId': receiverId,
      'imageBase64': base64Image,
      'timestamp': FieldValue.serverTimestamp(),
      'unlockTime': unlockTime?.millisecondsSinceEpoch,
    };

    if (viewLimit != null) {
      newMessage['viewLimit'] = viewLimit;
      newMessage['timesViewed'] = 0;
    }

    await roomDoc.collection('messages').add(newMessage);

    await roomDoc.set({
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String userId1, String userId2) {
    final String chatRoomId = _getChatRoomId(userId1, userId2);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getRoomStatus(String userId1, String userId2) {
    final String chatRoomId = _getChatRoomId(userId1, userId2);
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }

  Future<void> acceptRequest(String userId1, String userId2) async {
    final String chatRoomId = _getChatRoomId(userId1, userId2);
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'status': 'accepted',
    }, SetOptions(merge: true));
  }

  Future<void> deleteEntireChat(String userId1, String userId2) async {
    final String chatRoomId = _getChatRoomId(userId1, userId2);
    final roomDoc = _firestore.collection('chat_rooms').doc(chatRoomId);

    final messages = await roomDoc.collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await roomDoc.delete();
  }
}
