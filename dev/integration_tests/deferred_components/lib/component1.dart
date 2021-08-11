library component1;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


int add(int i, int j) {
  return i + j;
}

class LogoScreen extends StatelessWidget {

  LogoScreen() {}

   @override
   Widget build(BuildContext context) {
      print('Running deferred code');
      return Container(
        child: Column(
          children: <Widget>[
            Text('DeferredWidget', key: Key('DeferredWidget')),
            Image.asset('customassets/flutter_logo.png', key: Key('DeferredImage')),
          ]
        ),
        padding: EdgeInsets.all(25),
        color: Colors.blue,
      );
   }
}