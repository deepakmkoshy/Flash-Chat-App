import 'package:flashchat/models/user_model.dart';
import 'package:flutter/material.dart';

class UserWidget extends StatelessWidget {
  final UserModel userModel;

  const UserWidget({this.userModel});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: (){},
      // style: ButtonStyle(backgroundColor: ),
      label: Text(userModel.name),
      icon: CircleAvatar(backgroundImage: NetworkImage(userModel.photoURL),
            radius: 20,)
      ,
      );
  }
}
