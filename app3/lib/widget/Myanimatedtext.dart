import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class Myanimatedtext extends StatefulWidget {
  const Myanimatedtext({super.key});

  @override
  State<Myanimatedtext> createState() => _MyanimatedtextState();
}

class _MyanimatedtextState extends State<Myanimatedtext> {
  @override
  Widget build(BuildContext context) {
    const colorizeColors = [
      Colors.purple,
      Colors.blue,
      Colors.yellow,
      Colors.red,
    ];

    const colorizeTextStyle = TextStyle(
      fontSize: 20.0,
      fontFamily: 'Horizon',
    );
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.image),
        backgroundColor: Colors.blue,
        title: const Text(
          'Animated Text',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        toolbarHeight: 100,
      ),
      body: Center(
          child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30),
        child: SizedBox(
          width: 250.0,
          child: AnimatedTextKit(
            animatedTexts: [
              ColorizeAnimatedText(
                'Larry Page',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
              ),
              ColorizeAnimatedText(
                'Bill Gates',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
              ),
              ColorizeAnimatedText(
                'Steve Jobs',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
              ),
            ],
            isRepeatingAnimation: true,
            onTap: () {
              print("Tap Event");
            },
          ),
        ),
      )),
    );
  }
}
