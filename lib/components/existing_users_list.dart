import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/models/user_model.dart';
import 'package:flutter/material.dart';

class ExistingUserWidget extends StatefulWidget {
  final UserModel userModel;
  final String chatId;

  const ExistingUserWidget({this.userModel, this.chatId});

  @override
  _ExistingUserWidgetState createState() => _ExistingUserWidgetState();
}

class _ExistingUserWidgetState extends State<ExistingUserWidget> {
  String lMsg = '';
  @override
  void initState() {
    lastMsg();
    super.initState();
  }

  void lastMsg() {
    final _firestore = FirebaseFirestore.instance.collection('newMessages');
    _firestore
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('created', descending: false)
        .get()
        .then((QuerySnapshot qs) {
      if (qs.docs.isNotEmpty) {
        if (qs.docs[0].data()['type'] == 'txt') {
          // print(qs.docs[0].data()['text']);

          lMsg = qs.docs[0].data()['text'];
        } else {
          lMsg = 'Voice Message (${qs.docs[0].data()['duration']})';
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        // mainAxisAlignment: MainAxisAlignment.,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.08),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: width * 0.075,
              child: CircleAvatar(
                radius: width * 0.07,
                backgroundImage: NetworkImage(widget.userModel.photoURL),
              ),
            ),
          ),
          SizedBox(width: width * 0.05),
          Column(
            children: [
              Text(
                widget.userModel.name,
                style: TextStyle(fontSize: 20),
              ),
              Text(lMsg),
            ],
          )
        ],
      ),
    );
  }
}
