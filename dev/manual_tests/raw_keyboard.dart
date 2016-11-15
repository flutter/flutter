// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

GlobalKey _key = new GlobalKey();

void main() {
  runApp(new MaterialApp(
    title: "Hardware Key Demo",
    home: new Scaffold(
      appBar: new AppBar(
        title: new Text("Hardware Key Demo")
      ),
      body: new Center(
        child: new RawKeyboardDemo(
          key: _key
        )
      )
    )
  ));
}

class RawKeyboardDemo extends StatefulWidget {
  RawKeyboardDemo({ GlobalKey key }) : super(key: key);

  @override
  _HardwareKeyDemoState createState() => new _HardwareKeyDemoState();
}

class _HardwareKeyDemoState extends State<RawKeyboardDemo> {
  RawKeyEvent _event;

  void _handleKeyEvent(RawKeyEvent event) {
    setState(() {
      _event = event;
    });
  }

  @override
  Widget build(BuildContext context)  {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool focused = Focus.at(context);
    Widget child;
    if (!focused) {
      child = new GestureDetector(
        onTap: () {
          Focus.moveTo(config.key);
        },
        child: new Text('Tap to focus', style: textTheme.display1),
      );
    } else if (_event == null) {
      child = new Text('Press a key', style: textTheme.display1);
    } else {
      int codePoint;
      int keyCode;
      int hidUsage;
      final RawKeyEventData data = _event.data;
      if (data is RawKeyEventDataAndroid) {
        codePoint = data.codePoint;
        keyCode = data.keyCode;
      } else if (data is RawKeyEventDataFuchsia) {
        codePoint = data.codePoint;
        hidUsage = data.hidUsage;
      }
      child = new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text('${_event.runtimeType}', style: textTheme.body2),
          new Text('codePoint: $codePoint', style: textTheme.display4),
          new Text('keyCode: $keyCode', style: textTheme.display4),
          new Text('hidUsage: $hidUsage', style: textTheme.display4),
        ],
      );
    }
    return new RawKeyboardListener(
      focused: focused,
      onKey: _handleKeyEvent,
      child: child,
    );
  }
}

