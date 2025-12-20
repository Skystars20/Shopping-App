import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/ChatService.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/message_user.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    ;
  }

  Future<Map<String, dynamic>> _getOtherUsernameAndPfp(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userData = doc.data() as Map<String, dynamic>;

    String username = userData['displayName'] ?? "Unknown User";
    String? profilePicture;
    try {
      profilePicture = userData['pfp'] as String?;
    } catch (e) {
      profilePicture = null;
    }

    Map<String, dynamic> returnValue = {
      'username': username,
      'pfp': profilePicture,
    };

    return returnValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: chats.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>? ?? {};
              final chatId = chats[index].id;
              final currentUser = FirebaseAuth.instance.currentUser;
              final otherUserId = chatId
                  .split("_")
                  .firstWhere((element) => element != currentUser?.uid);
              final lastMessage =
                  chat['lastMessage'] as String? ?? 'No messages';
              final unread = chat['unread'] as int? ?? 0;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getOtherUsernameAndPfp(otherUserId),
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container();
                  }

                  final data = asyncSnapshot.data;

                  final initials = (data!['username'] ?? "Unknown User")
                      .toString()[0]
                      .toUpperCase();

                  debugPrint(initials);

                  String? profilePicture = data['pfp'];

                  return ListTile(
                    leading: CircleAvatar(
                      child: (profilePicture == null)
                          ? Text(initials)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Base64Image(base64String: profilePicture),
                            ),
                    ),
                    title: Text(data['username'] ?? "Unknown User"),
                    subtitle: Text(lastMessage),
                    trailing: unread == 1
                        ? CircleAvatar(backgroundColor: Colors.red, radius: 8)
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MessageUser(otherUserId: otherUserId),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showBottomSheet(currentUser?.uid, chatId);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showBottomSheet(String? uid, String chatId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection('chats')
                      .doc(chatId)
                      .delete();
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 30),
                    const SizedBox(width: 5),
                    Text("Close chat", style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
