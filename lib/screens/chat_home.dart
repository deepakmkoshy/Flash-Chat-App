import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/components/existing_users_list.dart';
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
  List<QueryDocumentSnapshot> chatIdList = [];
  bool isChatHomeEmpty = true;
  final _controller = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserWidget> userslist = [];
  List<ExistingUserWidget> chatUserslist = [];

  @override
  void initState() {
    super.initState();
    getUsersList();
    getChatIdList();
    isFirstTimeUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //To add to users to users collection
  void isFirstTimeUser() async {
    if (docList.isNotEmpty) {
      for (var item in docList) {
        if (uid == item.id) {
          return;
        }
      }
    }
    await _firestore.collection("users").doc(uid).set({'name': name, 'photoURL': imageUrl});
  }

  void getUsersList() async {
    _firestore.collection("users").get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        docList = querySnapshot.docs;

        setState(() {});
      }
    });
  }

  void getChatIdList() async {
    _firestore
        .collection("newMessages")
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        chatIdList = querySnapshot.docs;
        genChatUsers();
      } else {
        //New user with no chat
      }
    });
  }

  //List for users for which chatid has been generated(already chatted)
  void genChatUsers() {
    for (var item in chatIdList) {
      if (item.id.contains(uid.substring(0, 6))) {
        chatUserslist.add(ExistingUserWidget(
          userModel: otherUserDetails(item.id),
          chatId: item.id,
        ));
      }
    }
    setState(() {});
  }

  //For getting the opp user details for existing already chatted users
  UserModel otherUserDetails(String chatId) {
    String otherId;
    if (chatId.startsWith(uid.substring(0, 6))) {
      otherId = chatId.substring(6, 12);
    } else {
      otherId = chatId.substring(0, 6);
    }
    if (docList.isNotEmpty) {
      for (var item in docList) {
        if (item.id.startsWith(otherId)) {
          return UserModel(
              name: item.data()['name'],
              photoURL: item.data()['photoURL'],
              uid: item.id);
        }
      }
    }
    return null;
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
            ),
            Divider(
              thickness: 2,
            ),
            Expanded(
              child: SizedBox(
                width: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: chatUserslist.length,
                  itemBuilder: (context, index) {
                    return chatUserslist[index];
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(
                    thickness: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
