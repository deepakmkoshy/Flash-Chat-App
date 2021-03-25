import 'package:firebase_core/firebase_core.dart';
import 'package:flashchat/services/audio_provider.dart';
import 'package:flashchat/components/auth.dart';
import 'package:flashchat/screens/chat_home.dart';
import 'package:flashchat/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await getCurrentUser();
  runApp(ChangeNotifierProvider(
      create: (context) => AudioProvider(), child: FlashChat()));
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Montserrat-SemiBold',
          textTheme: TextTheme(
            bodyText2: TextStyle(fontSize: 15),
          ),
        ),
        home: (userMain != null) ? ChatHome() : LoginNew());
  }
}
