// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'src/basic_messaging.dart';
import 'src/test_step.dart';

void main() {
  runApp(new TestApp());
}

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => new _TestAppState();
}

class _TestAppState extends State<TestApp> {
  Future<TestStepResult> _result;
  int _step = 0;

  @override
  void initState() {
    super.initState();
  }

  void _executeNextStep() {
    setState(() {
      _result = _executeStep(_step++);
    });
  }

  Future<TestStepResult> _executeStep(int step) async {
    switch (step) {
      case 0:
        return basicStringMessaging('hello, world');
      case 1:
        return basicStringMessaging('hello \u263A \u{1f602} unicode');
      case 2:
        return basicStringMessaging('');
      case 3:
        return basicStringMessaging(null);
      case 4:
        return basicJsonMessaging(null);
      case 5:
        return basicJsonMessaging(true);
      case 6:
        return basicJsonMessaging(false);
      case 7:
        return basicJsonMessaging(0);
      case 8:
        return basicJsonMessaging(-7);
      case 9:
        return basicJsonMessaging(7);
      case 10:
        return basicJsonMessaging(1 << 32);
      case 11:
        return basicJsonMessaging(1 << 64);
      case 12:
        return basicJsonMessaging(1 << 128);
      case 13:
        return basicJsonMessaging(0.0);
      case 14:
        return basicJsonMessaging(-7.0);
      case 15:
        return basicJsonMessaging(7.0);
      case 16:
        return basicJsonMessaging('');
      case 17:
        return basicJsonMessaging('hello, world');
      case 18:
        return basicJsonMessaging('hello \u263A \u{1f602} unicode');
      case 19:
        return basicJsonMessaging(<dynamic>[]);
      case 20:
        return basicJsonMessaging(<dynamic>[
          false,
          0,
          0.0,
          'hello',
          <dynamic>[
            <String, dynamic>{'key': 42}
          ]
        ]);
      case 21:
        return basicJsonMessaging(<String, dynamic>{});
      case 22:
        return basicJsonMessaging(<String, dynamic>{
          'a': false,
          'b': 0,
          'c': 0.0,
          'd': 'hello',
          'e': <dynamic>[
            <String, dynamic>{'key': 42}
          ]
        });
      default:
        return TestStepResult.complete;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Channels Test',
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Channels Test'),
        ),
        body: new Center(
          child: new FutureBuilder<TestStepResult>(
              future: _result,
              builder: (BuildContext context,
                  AsyncSnapshot<TestStepResult> snapshot) {
                return new TestStepResult.fromSnapshot(snapshot)
                    .asWidget(context);
              }),
        ),
        floatingActionButton: new FloatingActionButton(
          key: new ValueKey<String>('step'),
          onPressed: _executeNextStep,
          child: new Icon(Icons.navigate_next),
        ),
      ),
    );
  }
}
