// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

const Color _kKeyUmbraOpacity = Color(0x33000000); // alpha = 0.2
const Color _kKeyPenumbraOpacity = Color(0x24000000); // alpha = 0.14
const Color _kAmbientShadowOpacity = Color(0x1F000000); // alpha = 0.12

class CupertinoSegmentedControlDemo extends StatefulWidget {
  static const String routeName = 'cupertino/segmented_control';

  @override
  _CupertinoSegmentedControlDemoState createState() => _CupertinoSegmentedControlDemoState();
}

class _CupertinoSegmentedControlDemoState extends State<CupertinoSegmentedControlDemo> {
  final Map<int, Widget> children = const <int, Widget>{
    0: Text('Midnight'),
    1: Text('Viridian'),
    2: Text('Cerulean'),
  };

  final Map<int, Widget> icons = const <int, Widget>{
    0: Center(
      child: FlutterLogo(
        colors: Colors.indigo,
        size: 200.0,
      ),
    ),
    1: Center(
      child: FlutterLogo(
        colors: Colors.teal,
        size: 200.0,
      ),
    ),
    2: Center(
      child: FlutterLogo(
        colors: Colors.cyan,
        size: 200.0,
      ),
    ),
  };

  int sharedValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segmented Control'),
        actions: <Widget>[MaterialDemoDocumentationButton(CupertinoSegmentedControlDemo.routeName)],
      ),
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16.0),
          ),
          SizedBox(
            width: 500.0,
            child: CupertinoSegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
              },
              groupValue: sharedValue,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 64.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(3.0),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      offset: Offset(0.0, 3.0),
                      blurRadius: 5.0,
                      spreadRadius: -1.0,
                      color: _kKeyUmbraOpacity,
                    ),
                    BoxShadow(
                      offset: Offset(0.0, 6.0),
                      blurRadius: 10.0,
                      spreadRadius: 0.0,
                      color: _kKeyPenumbraOpacity,
                    ),
                    BoxShadow(
                      offset: Offset(0.0, 1.0),
                      blurRadius: 18.0,
                      spreadRadius: 0.0,
                      color: _kAmbientShadowOpacity,
                    ),
                  ],
                ),
                child: icons[sharedValue],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
