// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Scroll Wheel Test',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        fontFamily: 'RobotoMono',
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Scroll Wheel Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: 1000,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            height: 100,
            color: Colors.lightBlue,
            child: Center(
              child: Text("Item $index"),
            ),
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            key: const Key('scroll-button'),
            onPressed: () {
              final int centerX = 100; //html.window.innerWidth ~/ 2;
              final int centerY = 100; //html.window.innerHeight ~/ 2;
              dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
              dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
              dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
              dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
              dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
            },
            label: Text('Scroll'),
            icon: Icon(Icons.thumb_up),
          ),
    );
  }
}


abstract class DeltaMode {
  static const int kPixel = 0x00;
  static const int kLine = 0x01;
  static const int kPage = 0x02;
}

html.WheelEvent dispatchMouseWheelEvent(int mouseX, int mouseY,
    int deltaMode, double deltaX, double deltaY,
    {bool shiftKeyPressed = false}) {
  html.EventTarget target = html.document.elementFromPoint(mouseX, mouseY);

  target.dispatchEvent(html.MouseEvent("mouseover",
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
  ));

  target.dispatchEvent(html.MouseEvent("mousemove",
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
  ));

  html.WheelEvent event = html.WheelEvent('wheel',
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
    deltaMode: deltaMode,
    deltaX : deltaX,
    deltaY : deltaY,
    shiftKey: shiftKeyPressed,
  );
  target.dispatchEvent(event);
  return event;
}
