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

  Future<void> sendMessage(
    String receiverId,
    String message,
    DateTime? unlockTime,
    String senderId,
  ) async {
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
    };

    await roomDoc.collection('messages').add(newMessage);
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
}
