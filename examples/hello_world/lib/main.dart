// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {

  void tapped(TapDownDetails details) {
    print(details.globalPosition.toString());
  }

  void forceStarted(ForcePressDetails details) {
    print('force started ' + details.globalPosition.toString());
  }

  void forcePeaked(ForcePressDetails details) {
    print('forec peaked ' + details.globalPosition.toString());
  }

  void forceUpdated(ForcePressUpdateDetails details) {
    print('force update ' + details.pressure.toString());
  }


  runApp(
    MaterialApp(
      home: Material(
        child: Container(
          color: Colors.blue,
//          child: GestureDetector(
//            onForcePressStart: forceStarted,
//            onForcePressPeak: forcePeaked,
//            onForcePressUpdate: forceUpdated,
//            onTapDown: tapped,
//          ),
        ),
      ),
    )
  );
}