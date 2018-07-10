// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const Color _kKeyUmbraOpacity = const Color(0x33000000); // alpha = 0.2
const Color _kKeyPenumbraOpacity = const Color(0x24000000); // alpha = 0.14
const Color _kAmbientShadowOpacity = const Color(0x1F000000); // alpha = 0.12

class CupertinoSegmentedControlDemo extends StatefulWidget {
  static const String routeName = 'cupertino/segmented_control';

  @override
  _CupertinoSegmentedControlDemoState createState() => new _CupertinoSegmentedControlDemoState();
}

class _CupertinoSegmentedControlDemoState extends State<CupertinoSegmentedControlDemo> {
  final Map<int, Widget> children = const <int, Widget>{
    0: Center(
      child: const Text('Red'),
    ),
    1: Center(
      child: const Text('Green'),
    ),
    2: Center(
      child: const Text('Blue'),
    ),
  };

  final Map<int, Widget> icons = const <int, Widget>{
    0: Center(
      child: const FlutterLogo(
        colors: Colors.red,
        size: 200.0,
      ),
    ),
    1: Center(
      child: const FlutterLogo(
        colors: Colors.green,
        size: 200.0,
      ),
    ),
    2: Center(
      child: const FlutterLogo(
        colors: Colors.blue,
        size: 200.0,
      ),
    ),
  };

  int sharedValue = 0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Cupertino Segmented Control'),
      ),
      body: new Column(
        children: <Widget>[
          const Padding(
            padding: const EdgeInsets.all(16.0),
          ),
          new SegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {
              setState(() {
                sharedValue = newValue;
              });
            },
            groupValue: sharedValue,
          ),
          new Expanded(
            child: new Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 16.0,
              ),
              child: new Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 64.0,
                    horizontal: 16.0,
                  ),
                  decoration: new BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: new BorderRadius.circular(3.0),
                    boxShadow: const <BoxShadow>[
                      const BoxShadow(
                        offset: const Offset(0.0, 3.0),
                        blurRadius: 5.0,
                        spreadRadius: -1.0,
                        color: _kKeyUmbraOpacity,
                      ),
                      const BoxShadow(
                        offset: const Offset(0.0, 6.0),
                        blurRadius: 10.0,
                        spreadRadius: 0.0,
                        color: _kKeyPenumbraOpacity,
                      ),
                      const BoxShadow(
                        offset: const Offset(0.0, 1.0),
                        blurRadius: 18.0,
                        spreadRadius: 0.0,
                        color: _kAmbientShadowOpacity,
                      ),
                    ],
                  ),
                  child: icons[sharedValue]),
            ),
          ),
        ],
      ),
    );
  }
}
