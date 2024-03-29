import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/components/existing_users_list.dart';
import 'package:flashchat/constants.dart';
import 'package:flashchat/models/user_model.dart';
import 'package:flashchat/screens/login.dart';
import 'package:flashchat/screens/search_users.dart';
import 'package:flutter/material.dart';

class ChatHome extends StatefulWidget {
  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<String> otherUsersIdList = [];
  List<QueryDocumentSnapshot> docList = [];
  List<QueryDocumentSnapshot> chatIdList = [];
  bool isChatHomeEmpty = false;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ExistingUserWidget> chatUserslist = [];

  @override
  void initState() {
    super.initState();
    getUsersList();
  }

  @override
  void dispose() {
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
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'name': name, 'photoURL': imageUrl});
  }

  void getUsersList() async {
    // First user error
    _firestore.collection('users').get().then(
      (QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          docList = querySnapshot.docs;
          getChatIdList();
        }
        isFirstTimeUser();
      },
    );
  }

  void getChatIdList() async {
    _firestore
        .collection("newMessages")
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          chatIdList = querySnapshot.docs;
        });
        genChatUsers();
      } else {
        setState(() {
          isChatHomeEmpty = true;
        });
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
    if (chatUserslist.isEmpty) {
      setState(() {
        isChatHomeEmpty = true;
      });
    } else {
      setState(() {
        isChatHomeEmpty = false;
      });
    }
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
          otherUsersIdList.add(item.id);
          return UserModel(
              name: item.data()['name'],
              photoURL: item.data()['photoURL'],
              uid: item.id);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        splashColor: primaryColor.withOpacity(0.5),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return SearchUsers(
                  otherUsersIdList: otherUsersIdList,
                  docList: docList,
                );
              },
            ),
          );
        },
        child: Icon(
          Icons.add,
          size: 30,
        ),
      ),
      appBar: AppBar(
        title: Text('Flash Chat'),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: <Widget>[
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                case 1:
                  chatUserslist.clear();
                  getUsersList();
                  break;
                case 2:
                  signOutGoogle();

                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) {
                    return LoginNew();
                  }), ModalRoute.withName('/'));
                  break;
              }
            },
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isChatHomeEmpty
          ? SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: double.infinity),
                  Center(
                    child: Text(
                      'Click here to add new users',
                      style: TextStyle(fontSize: width / 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 70.0),
                    child: Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 100,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  )
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: chatUserslist.length,
                      itemBuilder: (context, index) {
                        return chatUserslist[index];
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(
                        indent: width * 0.25,
                        endIndent: width * 0.05,
                        thickness: 2,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !isChatHomeEmpty,
                    child: Divider(
                      indent: width * 0.25,
                      endIndent: width * 0.05,
                      thickness: 2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
