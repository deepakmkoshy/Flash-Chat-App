import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/components/message_bubble.dart';
import 'package:flashchat/components/wave.dart';
import 'package:flashchat/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart' as random;

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

  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = true;
  String _mPath;
  bool sendButtonVisible = false;
  bool showWave = false;
  bool recordButtonVisible = true;
  bool isTextMsg = true;
  String dur = "0:00";

  String type;
  String content;
  String text;
  String messageSender;
  String durationFb;
  String currentUser;
  bool isMe = true;

  String tmpUrl = "www";

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
    super.dispose();
    messageTextController.dispose();
    _mPlayer.closeAudioSession();
    _mPlayer = null;

    stopRecorder();
    _mRecorder.closeAudioSession();
    _mRecorder = null;
    if (_mPath != null) {
      var outputFile = File(_mPath);
      if (outputFile.existsSync()) {
        outputFile.delete();
      }
    }
  }

  @override
  void initState() {
    getPermissions();
    getCurrentUser();
    _mPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
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

  //------------------------------------Audio Logic-------------

  Future<void> openTheRecorder() async {
    await _mRecorder.openAudioSession();
    _mRecorderIsInited = true;
  }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();
    setState(() {});
  }

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    _mplaybackReady = true;
  }

  Future<void> record() async {
    setState(() {
      showWave = true;
      isTextMsg = false;
      sendButtonVisible = false;
    });

    var tempDir = await getApplicationDocumentsDirectory();
    String newFilePath = p.join(tempDir.path, randomString(10));
    _mPath = '$newFilePath.aac';
    var outputFile = File(_mPath);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }

    assert(_mRecorderIsInited && _mPlayer.isStopped);
    await _mRecorder.startRecorder(
      toFile: _mPath,
      codec: Codec.aacADTS,
    );
    setState(() {});
  }

  void play(String url) async {
    tmpUrl = url;

    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder.isStopped &&
        _mPlayer.isStopped);

    await _mPlayer.startPlayer(
        fromURI: url,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> duration() async {
    await flutterSoundHelper.duration(_mPath).then((value) {
      setState(() {
        if (value.inSeconds < 9) {
          dur = "0:0${value.inSeconds}";
        } else {
          dur = "0:${value.inSeconds}";
        }
      });
    });
  }

  void Function() getRecorder() {
    if (!_mRecorderIsInited || !_mPlayer.isStopped) {
      return null;
    }

    return _mRecorder.isStopped
        ? record
        : () {
            stopRecorder().then((value) async {
              await duration();
            });
          };
  }

  void sendMessage() {
    uploadPic(_mPath).then((downloadUrl) {
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
          'duration': dur,
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

  Widget messageBubble(QueryDocumentSnapshot message) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    var content = message.data()['content'];

    return (type.contains('txt'))
        ? TextMessageBubble(message: message, isMe: isMe)
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Material(
                  borderRadius: BorderRadius.circular(10.0),
                  elevation: 2.0,
                  color: isMe ? Colors.lightBlueAccent : Colors.white,
                  child: Container(
                    padding: EdgeInsets.all(6.0),
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  NetworkImage(message.data()['photo']),
                            ),
                            SizedBox(height: 2),
                            Text(durationFb,
                                style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black))
                          ],
                        ),
                        !(_mPlayer.isPlaying &&
                                tmpUrl == content)
                            ? SizedBox()
                            : Wave(
                                height: height * 0.08,
                                width: width * 0.15,
                                isFull: false,
                              ),
                        IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          iconSize: MediaQuery.of(context).size.height * 0.06,
                          icon: (_mPlayer.isPlaying &&
                                  tmpUrl == content)
                              ? Icon(
                                  Icons.stop_circle_outlined,
                                  color: Colors.black,
                                )
                              : Icon(
                                  Icons.play_arrow,
                                  color: Colors.black,
                                ),
                          onPressed: () async {
                            _mPlayer.isPlaying
                                ? stopPlayer()
                                : play(content); //message.content
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                signOutGoogle();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: messagesStream()),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: showWave
                          ? _mRecorder.isStopped
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
                      onLongPress: getRecorder(),
                      onLongPressEnd: (longPressEndDetails) {
                        stopRecorder().then((value) async {
                          await duration();
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
      // ),
    );
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

  Widget messagesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('created', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data.docs.reversed;
          List<Widget> messageWidgets = [];
          for (var message in messages) {
            currentUser = email;
            type = message.data()['type'];
            messageSender = message.data()['sender'];
            isMe = currentUser == messageSender;
            Widget messageWidget;

            if (type == 'txt') {
              text = message.data()['text'];
            } else {
              content = message.data()['content'];
              durationFb = message.data()['duration'];
            }
            messageWidget = messageBubble(message);
            messageWidgets.add(messageWidget);
          }
          return ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: messageWidgets,
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
