import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/components/users_list.dart';
import 'package:flashchat/models/user_model.dart';
import 'package:flutter/material.dart';

class ChatHome extends StatefulWidget {
  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<String> users = [];
  List<QueryDocumentSnapshot> docList = [];
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
        docList = querySnapshot.docs;
        // for (var snap in querySnapshot.docs) {
        //   users.add(snap.id.toString());
        // }
        // print(users);
        setState(() {});
      }
    });
  }

  void checkUser() {
    List<UserModel> availUsers = [];
    List<UserWidget> userslist = [];
    if (docList.isNotEmpty) {
      for (var item in docList) {
        if (item.data()['name'].toString().startsWith(_controller.text)) {
            availUsers.add(UserModel(name: item.data()['name'], photoURL: item.data()['photoURL'],
             uid: item.id));
             
          // availUsers.add(item.data()['name'].toString());
        }
      }
        for( var ind in availUsers){
          userslist.add(UserWidget(userModel: ind));
        }
      
    }
    print(availUsers);
    // print(userslist);
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
              controller: _controller,
              decoration: InputDecoration(labelText: "Search Users by Name"),
              onChanged: (String str) {
                setState(() {
                  checkUser();
                });
              },
            ),
          //   ListView(
          //   reverse: true,
          //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          //   children: m,
          // );
          ],
        ),
      ),
    );
  }
}
