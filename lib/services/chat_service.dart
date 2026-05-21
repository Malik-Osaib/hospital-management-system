// FILE: lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<void> sendMessage(MessageModel message) async {
    await _firestore.collection('messages').add(message.toMap());
  }

  // Get messages between two users
  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromFirestore(doc);
      }).where((message) {
        return (message.senderId == userId1 && message.receiverId == userId2) ||
            (message.senderId == userId2 && message.receiverId == userId1);
      }).toList();
    });
  }

  // Get list of users (for patients to find doctors)
  Stream<List<Map<String, dynamic>>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }
}