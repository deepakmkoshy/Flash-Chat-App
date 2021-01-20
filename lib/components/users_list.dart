import 'package:flashchat/models/user_model.dart';
import 'package:flutter/material.dart';

class UserWidget extends StatelessWidget {
  final UserModel userModel;

  const UserWidget({this.userModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(userModel.photoURL),
          radius: 20,
        ),
        SizedBox(width: 30),
        Text(userModel.name),
      ],
    );
  }
}
