import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final participants = [currentUser.uid, otherUserId]..sort();
    final chatId = participants.join('_');

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _createUserChatReference(currentUser.uid, otherUserId, chatId);
      await _createUserChatReference(otherUserId, currentUser.uid, chatId);
    }

    return chatId;
  }

  Future<void> _createUserChatReference(
    String userId,
    String otherUserId,
    String chatId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .set({
          'otherUserId': otherUserId,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unread': 0,
        });
  }

  Future<void> sendMessage(String chatId, String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'text': text,
          'timestamp': timestamp,
          'read': false,
        });

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'updatedAt': timestamp,
    });

    await _updateUserChatReferences(chatId, text, timestamp);
  }

  Future<void> _updateUserChatReferences(
    String chatId,
    String lastMessage,
    dynamic timestamp,
  ) async {
    final participants = chatId.split("_");

    if (lastMessage.isEmpty) {
      QuerySnapshot messageSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messageSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> messageData =
            messageSnapshot.docs[0].data() as Map<String, dynamic>;
        lastMessage = messageData['text'] ?? '';
      }
    }

    for (final userId in participants) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .set({
            'lastMessage': lastMessage,
            'lastMessageTime': timestamp,
            'unread': FieldValue.increment(userId == _auth.currentUser?.uid ? 0 : 1),
          });
    }
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(chatId)
        .update({'unread': 0});

    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in messages.docs) {
      await doc.reference.update({'read': true});
    }
  }
}