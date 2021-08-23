// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Scroll Wheel Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'RobotoMono',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter Scroll Wheel Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: 1000,
        itemBuilder: (BuildContext context, int index) => Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            height: 100,
            color: Colors.lightBlue,
            child: Center(
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('scroll-button'),
        onPressed: () {
          const int centerX = 100; //html.window.innerWidth ~/ 2;
          const int centerY = 100; //html.window.innerHeight ~/ 2;
          dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
          dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
          dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
          dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
          dispatchMouseWheelEvent(centerX, centerY, DeltaMode.kLine, 0, 1);
        },
        label: const Text('Scroll'),
        icon: const Icon(Icons.thumb_up),
      ),
    );
  }
}

abstract class DeltaMode {
  static const int kPixel = 0x00;
  static const int kLine = 0x01;
  static const int kPage = 0x02;
}

void dispatchMouseWheelEvent(int mouseX, int mouseY,
    int deltaMode, double deltaX, double deltaY) {
  final html.EventTarget target = html.document.elementFromPoint(mouseX, mouseY)!;

  target.dispatchEvent(html.MouseEvent('mouseover',
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
  ));

  target.dispatchEvent(html.MouseEvent('mousemove',
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
  ));

  target.dispatchEvent(html.WheelEvent('wheel',
    screenX: mouseX,
    screenY: mouseY,
    clientX: mouseX,
    clientY: mouseY,
    deltaMode: deltaMode,
    deltaX : deltaX,
    deltaY : deltaY,
    shiftKey: false,
  ));
}
