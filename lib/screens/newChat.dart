import 'dart:io';

import 'package:audio_wave/audio_wave.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:random_string/random_string.dart' as random;

class Chat extends StatefulWidget {
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = true;
  String _mPath;
  bool sendButtonVisible = false;
  bool showWave = false;

  bool isThereURL = true;

  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  bool isMyMessage;

  @override
  void initState() {
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    super.initState();

    getPermissions();
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
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  Future<void> getPermissions() async {
    var statusMic = await Permission.microphone.request();
    var statusStorage = await Permission.storage.request();

    if (statusMic == PermissionStatus.denied ||
        statusStorage == PermissionStatus.denied) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
  }

  Future<void> openTheRecorder() async {
    //TEST

    // var tempDir = await getApplicationDocumentsDirectory();
    // String newFilePath = p.join(tempDir.path, _randomString(10));
    // _mPath = '$newFilePath.aac';
    // var outputFile = File(_mPath);
    // if (outputFile.existsSync()) {
    //   await outputFile.delete();
    // }
    await _mRecorder.openAudioSession();
    _mRecorderIsInited = true;
  }

  Future<void> record() async {
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
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder.isStopped &&
        _mPlayer.isStopped);

    print("Is init$_mPlayerIsInited");
    print("playback ready $_mplaybackReady");
    print("rec ${_mRecorder.isStopped}");
    print("play ${_mPlayer.isStopped}");

    await _mPlayer.startPlayer(
        fromURI: url,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();

    setState(() {});
  }

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    _mplaybackReady = true;
    sendButtonVisible = true;
  }

  String _randomString(int length) {
    return random.randomNumeric(length);
  }

  void Function() getRecorder() {
    if (!_mRecorderIsInited || !_mPlayer.isStopped) {
      return null;
    }

    return _mRecorder.isStopped
        ? record
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
  }

  void sendMessage() {
    print("Clicked");
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
          // 'sender': loggedInUser.email,
          'content': content,
          'created': FieldValue.serverTimestamp()
        },
      );

      setState(() {
        sendButtonVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice chat"),
      ),
      bottomNavigationBar: Material(
        elevation: 13.0,
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Container(
              //   child: _mRecorder.isStopped
              //       ? SizedBox()
              // showWave
              //     ? SizedBox()
              _mRecorder.isStopped
                  ? SizedBox()
                  : AudioWave(
                      height: height * 0.1,
                      width: width * 0.45,
                      beatRate: Duration(milliseconds: 100),
                      spacing: 2.5,
                      bars: [
                        AudioWaveBar(height: 10, color: Colors.lightBlueAccent),
                        AudioWaveBar(height: 30, color: Colors.blue),
                        AudioWaveBar(height: 70, color: Colors.black),
                        AudioWaveBar(height: 40),
                        AudioWaveBar(height: 20, color: Colors.orange),
                        AudioWaveBar(height: 10, color: Colors.lightBlueAccent),
                        AudioWaveBar(height: 30, color: Colors.blue),
                        AudioWaveBar(height: 70, color: Colors.black),
                        AudioWaveBar(height: 40),
                        AudioWaveBar(height: 20, color: Colors.orange),
                        AudioWaveBar(height: 10, color: Colors.lightBlueAccent),
                        AudioWaveBar(height: 30, color: Colors.blue),
                        AudioWaveBar(height: 70, color: Colors.black),
                        AudioWaveBar(height: 40),
                        AudioWaveBar(height: 20, color: Colors.orange),
                        AudioWaveBar(height: 10, color: Colors.lightBlueAccent),
                        AudioWaveBar(height: 30, color: Colors.blue),
                        AudioWaveBar(height: 70, color: Colors.black),
                        AudioWaveBar(height: 40),
                        AudioWaveBar(height: 20, color: Colors.orange),
                      ],
                    ),
              IconButton(
                icon: _mRecorder.isStopped
                    ? Icon(Icons.fiber_manual_record)
                    : Icon(Icons.stop),
                onPressed: getRecorder(),
                iconSize: 45.0,
                color: Theme.of(context).primaryColor,
                tooltip: "Tap to Record",
              ),
              Visibility(
                visible: sendButtonVisible,
                child: IconButton(
                  icon: Icon(Icons.send),
                  iconSize: 20.0,
                  onPressed: () {
                    sendMessage();
                  },
                  color: Theme.of(context).primaryColor,
                  tooltip: "Send",
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment:
              //  isMyMessage ?
              Alignment.centerRight,
          //  : Alignment.centerLeft,
          child: Material(
            borderRadius: BorderRadius.circular(10.0),
            elevation: 2.0,
            child: Container(
              padding: EdgeInsets.all(10.0),
              width: MediaQuery.of(context).size.width * 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                      // child: isMyMessage
                      //     ? Text(widget.currentUserName.substring(0, 1))
                      //     : Text(widget.chatUserName.substring(0, 1)),
                      child: Text("D")),
                  !_mPlayer.isPlaying
                      ? SizedBox()
                      : AudioWave(
                          height: height * 0.08,
                          width: width * 0.15,
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
                            // AudioWaveBar(
                            //     height: 10, color: Colors.lightBlueAccent),
                            // AudioWaveBar(height: 30, color: Colors.blue),
                            // AudioWaveBar(height: 70, color: Colors.black),
                            // AudioWaveBar(height: 40),
                            // AudioWaveBar(height: 20, color: Colors.orange),
                          ],
                        ),
                  IconButton(
                    icon: _mPlayer.isPlaying
                        ? Icon(
                            Icons.pause_circle_filled,
                            size: height * 0.06,
                          )
                        : Icon(
                            Icons.play_circle_filled,
                            size: height * 0.06,
                          ),
                    onPressed: () async {
                      var newURL;
                      var documentReference =
                          FirebaseFirestore.instance.collection('users');
                      await documentReference
                          .get()
                          .then((QuerySnapshot snapshot) {
                        if (snapshot.docs.isNotEmpty) {
                          setState(() {
                            isThereURL = false;
                            newURL = snapshot.docs[0].data()['content'];
                          });
                        }
                      });
                      _mPlayer.isPlaying
                          ? stopPlayer()
                          : play(isThereURL
                              ? "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.aac"
                              : newURL); //message.content
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // flutterPlaySound(url) async {
  //   await flutterSound.startPlayer(url);

  //   flutterSound.onPlayerStateChanged.listen((e) {
  //     if (e == null) {
  //       setState(() {
  //         this.isPlaying = false;
  //       });
  //     } else {
  //       print("Playing Mohan");
  //       setState(() {
  //         this.isPlaying = false;
  //       });
  //     }
  //   });
  // }

  // Future<dynamic> flutterStopPlayer(url) async {
  //   await flutterSound.stopPlayer().then((value) {
  //     flutterPlaySound(url);
  //   });
  // }
}
