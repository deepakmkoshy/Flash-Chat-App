import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final String type;
  final String url;
  final String duration;
  final FlutterSoundPlayer mPlayer;

  MessageBubble(
      {this.sender,
      this.text,
      this.isMe,
      this.type,
      this.url,
      this.duration,
      this.mPlayer});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
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
                    color: isMe ? Colors.white : Colors.black54, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
    // :Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Align(
    //       alignment:
    //           //  isMyMessage ?
    //           Alignment.centerRight,
    //       //  : Alignment.centerLeft,
    //       child: Material(
    //         borderRadius: BorderRadius.circular(10.0),
    //         elevation: 2.0,
    //         child: Container(
    //           padding: EdgeInsets.all(10.0),
    //           width: MediaQuery.of(context).size.width * 0.5,
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: <Widget>[
    //               CircleAvatar(
    //                   // child: isMyMessage
    //                   //     ? Text(widget.currentUserName.substring(0, 1))
    //                   //     : Text(widget.chatUserName.substring(0, 1)),
    //                   child: Text("D")),
    //               !mPlayer.isPlaying
    //                   ? SizedBox()
    //                   : AudioWave(
    //                       height: height * 0.08,
    //                       width: width * 0.15,
    //                       beatRate: Duration(milliseconds: 100),
    //                       spacing: 2.5,
    //                       bars: [
    //                         AudioWaveBar(
    //                             height: 10, color: Colors.lightBlueAccent),
    //                         AudioWaveBar(height: 30, color: Colors.blue),
    //                         AudioWaveBar(height: 70, color: Colors.black),
    //                         AudioWaveBar(height: 40),
    //                         AudioWaveBar(height: 20, color: Colors.orange),
    //                         AudioWaveBar(
    //                             height: 10, color: Colors.lightBlueAccent),
    //                         AudioWaveBar(height: 30, color: Colors.blue),
    //                         AudioWaveBar(height: 70, color: Colors.black),
    //                         AudioWaveBar(height: 40),
    //                         AudioWaveBar(height: 20, color: Colors.orange),
    //                         AudioWaveBar(
    //                             height: 10, color: Colors.lightBlueAccent),
    //                         AudioWaveBar(height: 30, color: Colors.blue),
    //                         AudioWaveBar(height: 70, color: Colors.black),
    //                         AudioWaveBar(height: 40),
    //                         AudioWaveBar(height: 20, color: Colors.orange),
    //                         // AudioWaveBar(
    //                         //     height: 10, color: Colors.lightBlueAccent),
    //                         // AudioWaveBar(height: 30, color: Colors.blue),
    //                         // AudioWaveBar(height: 70, color: Colors.black),
    //                         // AudioWaveBar(height: 40),
    //                         // AudioWaveBar(height: 20, color: Colors.orange),
    //                       ],
    //                     ),
    //               IconButton(
    //                 icon: mPlayer.isPlaying
    //                     ? Icon(
    //                         Icons.pause_circle_filled,
    //                         size: height * 0.06,
    //                       )
    //                     : Icon(
    //                         Icons.play_circle_filled,
    //                         size: height * 0.06,
    //                       ),
    //                 onPressed: () async {
    //                   var newURL;

    //                                         mPlayer.isPlaying
    //                       ? stopPlayer()
    //                       : play(
    //                           ? "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.aac"
    //                           : newURL); //message.content
    //                 },
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ),
    //   );
  }
}
