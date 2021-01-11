import 'dart:io';

import 'package:audio_wave/audio_wave.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashchat/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
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
  bool isThereURL = true;
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
    stopPlayer();
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
    var statusStorage = await Permission.storage.request();

    if (statusMic == PermissionStatus.denied ||
        statusStorage == PermissionStatus.denied) {
      throw RecordingPermissionException('Microphone permission not granted');
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
    recordButtonVisible = false;
    sendButtonVisible = true;
  }

  Future<void> record() async {
    setState(() {
      showWave = true;
      isTextMsg = false;
      sendButtonVisible = false;
    });
    var tempDir = await getApplicationDocumentsDirectory();
    String newFilePath = p.join(tempDir.path, _randomString(10));
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

    // print("Is init$_mPlayerIsInited");
    // print("playback ready $_mplaybackReady");
    // print("rec ${_mRecorder.isStopped}");
    // print("play ${_mPlayer.isStopped}");

    await _mPlayer.startPlayer(
        fromURI: url,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  String _randomString(int length) {
    return random.randomNumeric(length);
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
    uploadPic().then((downloadUrl) {
      firestoreMsgUpload(downloadUrl);
    });
  }

  Future<String> uploadPic() async {
    File file = File(_mPath);

    Reference reference =
        firebaseStorage.ref().child("rec/" + _randomString(10) + '.aac');

    UploadTask uploadTask = reference.putFile(file);

    var dowurl;

    await uploadTask
        .whenComplete(() async => dowurl = await reference.getDownloadURL());
    var url = dowurl.toString();

    return url;
  }

  firestoreMsgUpload(content) {
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        {
          'duration': dur,
          'type': "voice",
          'sender': loggedInUser.email,
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
    // final height = MediaQuery.of(context).size.height;
    // final width = MediaQuery.of(context).size.width;
    return (type.contains('txt'))
        ? Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  messageSender,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Material(
                  elevation: 5,
                  borderRadius: BorderRadius.only(
                    topRight: isMe ? Radius.zero : Radius.circular(30),
                    topLeft: isMe ? Radius.circular(30) : Radius.zero,
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  color: isMe ? Colors.lightBlueAccent : Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(
                      text,
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black54,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                messageSender,
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.end,
              ),
                Material(
                  borderRadius: BorderRadius.circular(10.0),
                  elevation: 2.0,
                  color: isMe ? Colors.lightBlueAccent : Colors.white,
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CircleAvatar(
                                // child: isMyMessage
                                //     ? Text(widget.currentUserName.substring(0, 1))
                                //     : Text(widget.chatUserName.substring(0, 1)),
                                child: Text("D")),
                            Text(durationFb,
                            style: TextStyle(color:
                               isMe?Colors.white: Colors.black))
                          ],
                        ),
                        !(_mPlayer.isPlaying && tmpUrl == message.data()['content'])
                            ? SizedBox()
                            : AudioWave(
                                height: MediaQuery.of(context).size.height * 0.08,
                                width: MediaQuery.of(context).size.width * 0.15,
                                beatRate: Duration(milliseconds: 100),
                                spacing: 2.5,
                                bars: [
                                  AudioWaveBar(
                                      height: 10, color: Colors.lightBlueAccent),
                                  AudioWaveBar(height: 30, color: Colors.blue),
                                  AudioWaveBar(height: 70, color: Colors.black),
                                  AudioWaveBar(height: 40),
                                  AudioWaveBar(height: 20, color: Colors.orange),
                                  AudioWaveBar(
                                      height: 10, color: Colors.lightBlueAccent),
                                  AudioWaveBar(height: 30, color: Colors.blue),
                                  AudioWaveBar(height: 70, color: Colors.black),
                                  AudioWaveBar(height: 40),
                                  AudioWaveBar(height: 20, color: Colors.orange),
                                  AudioWaveBar(
                                      height: 10, color: Colors.lightBlueAccent),
                                  AudioWaveBar(height: 30, color: Colors.blue),
                                  AudioWaveBar(height: 70, color: Colors.black),
                                  AudioWaveBar(height: 40),
                                  AudioWaveBar(height: 20, color: Colors.orange),
                                ],
                              ),
                        IconButton(
                             icon: (_mPlayer.isPlaying && tmpUrl == message.data()['content'])?
                               Icon(
                                  Icons.stop_circle_outlined,
                                  color: Colors.black,
                                  size: MediaQuery.of(context).size.height * 0.06,
                                )

                                :
                               Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.black,
                                  size: MediaQuery.of(context).size.height * 0.06,
                                ),
                          onPressed: () async {
                            _mPlayer.isPlaying
                                ? stopPlayer()
                                : play(
                                    message.data()['content']); //message.content
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
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        // child: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: width * 0.05),
                                  Icon(Icons.fiber_manual_record,
                                      color: Colors.red),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    dur,
                                    style: TextStyle(fontSize: width / 18),
                                  )
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(width: width * 0.05),
                                  AudioWave(
                                    height: height * 0.08,
                                    width: width * 0.45,
                                    beatRate: Duration(milliseconds: 100),
                                    spacing: 2.5,
                                    bars: [
                                      AudioWaveBar(
                                          height: 10,
                                          color: Colors.lightBlueAccent),
                                      AudioWaveBar(
                                          height: 30, color: Colors.blue),
                                      AudioWaveBar(
                                          height: 70, color: Colors.black),
                                      AudioWaveBar(height: 40),
                                      AudioWaveBar(
                                          height: 20, color: Colors.orange),
                                      AudioWaveBar(
                                          height: 10,
                                          color: Colors.lightBlueAccent),
                                      AudioWaveBar(
                                          height: 30, color: Colors.blue),
                                      AudioWaveBar(
                                          height: 70, color: Colors.black),
                                      AudioWaveBar(height: 40),
                                      AudioWaveBar(
                                          height: 20, color: Colors.orange),
                                      AudioWaveBar(
                                          height: 10,
                                          color: Colors.lightBlueAccent),
                                      AudioWaveBar(
                                          height: 30, color: Colors.blue),
                                      AudioWaveBar(
                                          height: 70, color: Colors.black),
                                      AudioWaveBar(height: 40),
                                      AudioWaveBar(
                                          height: 20, color: Colors.orange),
                                      AudioWaveBar(
                                          height: 10,
                                          color: Colors.lightBlueAccent),
                                      AudioWaveBar(
                                          height: 30, color: Colors.blue),
                                      AudioWaveBar(
                                          height: 70, color: Colors.black),
                                      AudioWaveBar(height: 40),
                                      AudioWaveBar(
                                          height: 20, color: Colors.orange),
                                    ],
                                  ),
                                ],
                              )
                        : TextField(
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
                              //Do something with the user input.
                            },
                            decoration: kMessageTextFieldDecoration,
                          ),
                  ),
                  // IconButton(
                  //   icon: Icon(Icons.keyboard_voice),
                  //   onPressed: (){},
                  // ),
                  // messageTextController.value?
                  Visibility(
                    visible: recordButtonVisible,
                    child: IconButton(
                        icon: _mRecorder.isStopped
                            ? Icon(Icons.keyboard_voice)
                            : Icon(Icons.stop),
                        onPressed: getRecorder()),
                  ),
                  Visibility(
                    visible: sendButtonVisible,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (isTextMsg) {
                          messageTextController.clear();
                          _firestore.collection('messages').add({
                            'text': messageText,
                            'type': "txt",
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
                        //Implement send functionality.
                      },
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

  Widget messagesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('created', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        // print(snapshot.data.docs[0].data()['type']);
        if (snapshot.hasData) {
          final messages = snapshot.data.docs.reversed;
          List<Widget> messageWidgets = [];
          for (var message in messages) {
            currentUser = loggedInUser.email;
            type = message.data()['type'];
            // print(type == 'txt');
            messageSender = message.data()['sender'];
            Widget messageWidget;

            if (type == 'txt') {
              text = message.data()['text'].toString();
              isMe = currentUser == messageSender;

              messageWidget = messageBubble(message);


            } else {
              content = message.data()['content'];
              durationFb = message.data()['duration'];
              isMe = currentUser == messageSender;
              messageWidget = messageBubble(message);
            }
            messageWidgets.add(messageWidget);
          }
          return ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: messageWidgets,
          );
          // );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

// class MessagesStream extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('messages')
//           .orderBy('created', descending: false)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           final messages = snapshot.data.docs.reversed;
//           List<MessageBubble> messageWidgets = [];
//           for (var message in messages) {
//             final currentUser = loggedInUser.email;
//             final type = message.data()['type'];
//             final messageSender = message.data()['sender'];
//             MessageBubble messageWidget;

//             if (type == 'txt') {
//               final messageText = message.data()['text'];

//               messageWidget = MessageBubble(
//                   sender: messageSender,
//                   text: messageText,
//                   type: type,
//                   isMe: currentUser == messageSender);
//             } else {
//               final content = message.data()['content'];
//               final duration = message.data()['duration'];

//               messageWidget = MessageBubble(
//                   sender: messageSender,
//                   url: content,
//                   type: type,
//                   duration: duration,
//                   isMe: currentUser == messageSender);
//             }
//             messageWidgets.add(messageWidget);
//           }
//           return Expanded(
//             child: ListView(
//               reverse: true,
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//               children: messageWidgets,
//             ),
//           );
//         } else {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//       },
//     );
//   }
// }
