// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _MyBase with MyBase {}

mixin MyBase {
  static MyBase get instance => _instance;
  static set instance(MyBase updated) {
    _instance = updated;
  }

  static MyBase _instance = _MyBase();

  void foo() {
    print('MyBase: foo');
  }
}

class MyCustomBase with MyBase {
  MyCustomBase() {
    MyBase.instance = this;
  }

  @override
  void foo() {
    print('MyCustomBase: foo');
  }
}

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            FlutterLogo(size: 48),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This app is only meant to be run under the Flutter debugger',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
