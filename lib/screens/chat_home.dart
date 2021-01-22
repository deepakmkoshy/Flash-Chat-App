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
  // List<String> testList = [
  //   'Deepak',
  //   'Dep',
  //   'Kevin',
  //   'Kelin',
  //   'Mohasin',
  //   'Moas',
  //   'Mohes'
  // ];
  // List<Widget> finalList = [];
  List<QueryDocumentSnapshot> docList = [];
  bool isChatHomeEmpty = true;
  final _controller = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserWidget> userslist = [];

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

        setState(() {});
      }
    });
  }

  void checkUser() {
    userslist.clear();
    if (docList.isNotEmpty) {
      for (var item in docList) {
        if (item.data()['name'].toString().startsWith(_controller.text)) {
          setState(() {
            userslist.add(
              UserWidget(
                userModel: UserModel(
                    name: item.data()['name'],
                    photoURL: item.data()['photoURL'],
                    uid: item.id),
              ),
            );
          });
        }
      }
    }
    setState(() {});
    print(userslist);
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
                checkUser();
              },
              keyboardType: TextInputType.name,
            ),
            Expanded(
              child: SizedBox(
                width: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userslist.length,
                  itemBuilder: (context, index) {
                    return userslist[index];
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(
                    thickness: 2,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
