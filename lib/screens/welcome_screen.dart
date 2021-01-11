import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flashchat/components/rounded_button.dart';
import 'package:flashchat/screens/login_screen.dart';
import 'package:flashchat/screens/registration_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: Duration(seconds: 1), vsync: this);

    animation = ColorTween(begin: Colors.blueGrey, end: Colors.white)
        .animate(controller);

    controller.forward();

    controller.addListener(() {
      setState(() {});
      // print(controller.value); // goes from 0 to 1 in 1s
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
                child: Hero(
                tag: 'logo',
                child: Container(
                  child: Image.asset('assets/images/logo.png'),
                  height: 60.0,
                ),
              ),
            ),
            TypewriterAnimatedTextKit(
              speed: Duration(milliseconds: 100),
              text: ['Flash Chat'],
              textAlign: TextAlign.center,
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 45.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            RoundedButton(title: 'Log in',
             color: Colors.lightBlueAccent,
              onPressed: ()=> Navigator.pushNamed(context,LoginScreen.id),),
              RoundedButton(title: 'Register',
             color: Colors.blueAccent,
              onPressed: ()=> Navigator.pushNamed(context,RegistrationScreen.id),),
            
          ],
        ),
      ),
    );
  }
}


