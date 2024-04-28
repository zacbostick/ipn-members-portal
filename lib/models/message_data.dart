import 'package:cloud_firestore/cloud_firestore.dart';

class MessageData {
  final DocumentSnapshot messageSnapshot;
  final Map<String, dynamic>? userData;
  final String? replyToMessageText;

  MessageData({
    required this.messageSnapshot,
    this.userData,
    this.replyToMessageText,
  });
}
