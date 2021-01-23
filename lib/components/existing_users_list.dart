import 'package:flashchat/models/user_model.dart';
import 'package:flashchat/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class ExistingUserWidget extends StatelessWidget {
  final UserModel userModel;
  final String chatId;

  const ExistingUserWidget({this.userModel, this.chatId});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        print('Chat id of this user is: $chatId');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ChatScreen();
            },
          ),
        );
      },
      label: Text(userModel.name),
      icon: CircleAvatar(
        backgroundImage: NetworkImage(userModel.photoURL),
        radius: 20,
      ),
    );
  }
}
