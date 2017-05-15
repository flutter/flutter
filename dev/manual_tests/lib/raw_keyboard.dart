// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(new MaterialApp(
    title: 'Hardware Key Demo',
    home: new Scaffold(
      appBar: new AppBar(
        title: const Text('Hardware Key Demo'),
      ),
      body: const Center(
        child: const RawKeyboardDemo(),
      ),
    ),
  ));
}

class RawKeyboardDemo extends StatefulWidget {
  const RawKeyboardDemo({ Key key }) : super(key: key);

  @override
  _HardwareKeyDemoState createState() => new _HardwareKeyDemoState();
}

class _HardwareKeyDemoState extends State<RawKeyboardDemo> {
  final FocusNode _focusNode = new FocusNode();
  RawKeyEvent _event;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    setState(() {
      _event = event;
    });
  }

  @override
  Widget build(BuildContext context)  {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return new RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: new AnimatedBuilder(
        animation: _focusNode,
        builder: (BuildContext context, Widget child) {
          if (!_focusNode.hasFocus) {
            return new GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_focusNode);
              },
              child: new Text('Tap to focus', style: textTheme.display1),
            );
          }

          if (_event == null)
            return new Text('Press a key', style: textTheme.display1);

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
          return new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text('${_event.runtimeType}', style: textTheme.body2),
              new Text('codePoint: $codePoint', style: textTheme.display4),
              new Text('keyCode: $keyCode', style: textTheme.display4),
              new Text('hidUsage: $hidUsage', style: textTheme.display4),
            ],
          );
        },
      ),
    );
  }
}
