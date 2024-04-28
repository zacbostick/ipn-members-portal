import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ipn_mobile_app/models/chat_room.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ChatRoom>> fetchChatRooms() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('chats').get();

      return querySnapshot.docs.map((doc) {
        final name = doc.data()['name'] as String? ?? 'Unnamed Chat Room';
        return ChatRoom(id: doc.id, name: name);
      }).toList();
    } catch (e) {
      print("An error occurred while fetching chat rooms: $e");
      return [];
    }
  }

  Future<void> sendNewMessage(
      String chatRoomId, String messageText, String? replyToMessageId) async {
    var currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('chats/$chatRoomId/messages').add({
        'text': messageText,
        'timestamp': Timestamp.now(),
        'userId': currentUser.uid,
        'replyToMessageId': replyToMessageId,
      });
    }
  }

  Future<void> updateLikes(
      String chatRoomId, String messageId, Set<String> updatedLikes) async {
    await _firestore
        .collection('chats/$chatRoomId/messages')
        .doc(messageId)
        .update({
      'likes': updatedLikes.toList(),
    });
  }
}
