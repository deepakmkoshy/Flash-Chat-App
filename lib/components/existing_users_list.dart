import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashchat/models/user_model.dart';
import 'package:flashchat/screens/chat_screen.dart';
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
  String date = '';
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
        .orderBy('created', descending: true)
        .get()
        .then((QuerySnapshot qs) {
      if (qs.docs.isNotEmpty) {
        if (qs.docs[0].data()['type'] == 'txt') {
          lMsg = qs.docs[0].data()['text'];
        } else {
          lMsg = 'Voice Message (${qs.docs[0].data()['duration']})';
        }
        DateTime dateCreated = qs.docs[0].data()['created']?.toDate();
        date = '${dateCreated.day}/${dateCreated.month}/21';

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) {
                return ChatScreen(
                  chatId: widget.chatId,
                );
              },
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.08),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    spreadRadius: 0,
                    blurRadius: 10,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userModel.name,
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: width / 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: width * 0.01,
                ),
                Text(
                  lMsg,
                  style: TextStyle(
                    fontFamily: 'Montserrat-Medium',
                    fontSize: width / 30,
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              date,
              style: TextStyle(
                fontFamily: 'Montserrat-Medium',
                fontSize: width / 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
