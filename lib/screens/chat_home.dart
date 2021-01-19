import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatHome extends StatefulWidget {
  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<String> users = [];
  bool isChatHomeEmpty = true;
  final _controller = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getUsersList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getUsersList() async {
    _firestore.collection("users").get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        for (var snap in querySnapshot.docs) {
          users.add(snap.id.toString());
        }
        print(users);
        setState(() {});
      }
    });
  }

  void checkChatHome() {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚡️Chat'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body:
          //  isChatHomeEmpty?
          SafeArea(
        child: Column(
          children: [
            TextField(
              // controller: _controller,
              decoration: InputDecoration(labelText: "Search Users by Name"),
            ),
          ],
        ),
      ),
    );
  }
}
