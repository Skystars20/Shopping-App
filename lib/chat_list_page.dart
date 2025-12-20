import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shopping_app/ChatService.dart';
import 'package:shopping_app/chat_page.dart';

class ChatListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
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
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(chat['otherUserName'][0]),
                ),
                title: Text(chat['otherUserName']),
                subtitle: Text(chat['lastMessage']),
                trailing: chat['unreadCount'] > 0
                    ? CircleAvatar(
                        radius: 12,
                        child: Text(chat['unreadCount'].toString()),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chats[index].id,
                        otherUserId: chat['otherUserId'],
                        otherUserName: chat['otherUserName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}