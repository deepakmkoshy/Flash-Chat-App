import 'package:flutter/material.dart';

class UsersList extends StatelessWidget {
  final String photoURL;
  final String name;

  const UsersList({Key key, this.photoURL, this.name}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(photoURL),
          radius: 20,
        ),
        SizedBox(width: 30),
        Text(name),
      ],
    );
  }
}
