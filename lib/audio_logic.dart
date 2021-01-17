import 'dart:io';

import 'package:flashchat/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioLogic extends StatefulWidget {
  @override
  _AudioLogicState createState() => _AudioLogicState();
}

class _AudioLogicState extends State<AudioLogic> {
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
  String tmpUrl = "www";

  String content;
  String text;
  bool isMe = true;

//aud log
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

//aud end

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
