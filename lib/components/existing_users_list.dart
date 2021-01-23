import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/models/user_model.dart';
import 'package:flashchat/screens/chat_home.dart';
import 'package:flashchat/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class ExistingUserWidget extends StatelessWidget {
  final UserModel userModel;
  final String chatId;

  const ExistingUserWidget({this.userModel, this.chatId});

  @override
  Widget build(BuildContext context) {
    // final _firestore = FirebaseFirestore.instance;

    return TextButton.icon(
      onPressed: () {},
      label: Text(userModel.name),
      icon: CircleAvatar(
        backgroundImage: NetworkImage(userModel.photoURL),
        radius: 20,
      ),
    );
  }
}
