import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart' as random;

const Color primaryColor = Color(0XFF00C9B1);
const Color chatColor = Color(0XFF00C9B1);

const kSendButtonTextStyle = TextStyle(
  color: Colors.lightBlueAccent,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
);

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  border: OutlineInputBorder(
      borderRadius: BorderRadius.all(
    Radius.circular(20),
  )),
);

const kMessageContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
  ),
);

const kTextFieldDecoration = InputDecoration(
  hintText: 'Enter your email',
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

String randomString(int length) {
  return random.randomNumeric(length);
}

Future<String> uploadPic(String _mPath) async {
  File file = File(_mPath);
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  Reference reference =
      firebaseStorage.ref().child("rec/" + randomString(10) + '.aac');

  UploadTask uploadTask = reference.putFile(file);

  var dowurl;

  await uploadTask
      .whenComplete(() async => dowurl = await reference.getDownloadURL());
  var url = dowurl.toString();

  return url;
}
