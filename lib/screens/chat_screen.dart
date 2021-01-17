import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashchat/audio_provider.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/components/message_stream.dart';
import 'package:flashchat/components/wave.dart';
import 'package:flashchat/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'login.dart';

final _firestore = FirebaseFirestore.instance;
auth.User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  String messageText;
  final _auth = auth.FirebaseAuth.instance;

  bool sendButtonVisible = false;
  bool showWave = false;
  bool recordButtonVisible = true;
  bool isTextMsg = true;

  String content;
  bool isMe = true;

  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    print("Entered disposal");
    messageTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getPermissions();
    getCurrentUser();

    Provider.of<AudioProvider>(context, listen: false).initRec();
    super.initState();
  }

  Future<void> getPermissions() async {
    var statusMic = await Permission.microphone.request();

    if (statusMic == PermissionStatus.denied) {
      Fluttertoast.showToast(
          msg: "Kindly allow mic access for sending voice messages");
      await Future.delayed(Duration(seconds: 1));
      getPermissions();
    }
  }

  void sendMessage() {
    uploadPic(Provider.of<AudioProvider>(context, listen: false).mPath)
        .then((downloadUrl) {
      firestoreMsgUpload(downloadUrl);
    });
  }

  firestoreMsgUpload(content) {
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        {
          'name': name,
          'photo': imageUrl,
          'duration': Provider.of<AudioProvider>(context, listen: false).dur,
          'type': "voice",
          'sender': email,
          'content': content,
          'created': FieldValue.serverTimestamp()
        },
      );

      setState(() {
        recordButtonVisible = true;
        isTextMsg = true;
        sendButtonVisible = false;
        showWave = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Consumer<AudioProvider>(builder: (context, aud, child) {
      return Scaffold(
        appBar: AppBar(
          leading: null,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                signOutGoogle();
                //Disposing audio player
                Provider.of<AudioProvider>(context, listen: false).dispRec();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) {
                  return LoginNew();
                }), ModalRoute.withName('/'));
              },
            ),
          ],
          title: Text('⚡️Chat'),
          centerTitle: true,
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(child: MessagesStream()),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                        child: showWave
                            ? aud.isRecStopped
                                ? textField()
                                : Row(
                                    children: [
                                      SizedBox(width: width * 0.05),
                                      Wave(
                                          height: height * 0.08,
                                          width: width * 0.45,
                                          isFull: true),
                                    ],
                                  )
                            : textField()),
                    Visibility(
                      visible: recordButtonVisible,
                      child: GestureDetector(
                        onTap: () => Fluttertoast.showToast(
                          msg: "Hold to record, release to send",
                        ),
                        onLongPress: () async {
                          setState(() {
                            sendButtonVisible = false;
                            showWave = true;
                            isTextMsg = false;
                          });
                          aud.getRecorder();
                        },
                        onLongPressEnd: (longPressEndDetails) {
                          aud.stopRecorder().then((value) async {
                            await aud.duration();
                          });
                          sendMessage();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.keyboard_voice,
                            size: width * 0.1,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: sendButtonVisible,
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            size: width * 0.1,
                          ),
                          onPressed: () {
                            if (isTextMsg) {
                              messageTextController.clear();
                              _firestore.collection('messages').add({
                                'text': messageText,
                                'type': "txt",
                                'name': name,
                                'sender': loggedInUser.email,
                                'created': FieldValue.serverTimestamp()
                              });
                              setState(() {
                                sendButtonVisible = false;
                                recordButtonVisible = true;
                              });
                            } else {
                              sendMessage();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget textField() {
    return TextField(
      controller: messageTextController,
      onChanged: (value) {
        setState(() {
          if (value == '') {
            sendButtonVisible = false;
            recordButtonVisible = true;
          } else {
            sendButtonVisible = true;
            recordButtonVisible = false;
          }
        });
        messageText = value;
      },
      decoration: kMessageTextFieldDecoration,
    );
  }
}
