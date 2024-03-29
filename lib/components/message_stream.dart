import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/components/message_bubble.dart';
import 'package:flutter/material.dart';

class MessagesStream extends StatelessWidget {
  final String chatId;

  const MessagesStream({this.chatId});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    bool isMe = true;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('newMessages')
          .doc(chatId)
          .collection('messages')
          .orderBy('created', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data.docs.reversed;
          List<Bubble> messageWidgets = [];
          for (var message in messages) {
            isMe = email == message.data()['sender'];
            Bubble messageWidget = Bubble(message: message, isMe: isMe);
            messageWidgets.add(messageWidget);
          }
          return ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: messageWidgets,
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
