// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(new GestureDetector(
    onTap: () {
      Intent intent = new Intent()
        ..action = 'android.intent.action.VIEW'
        ..url = 'http://flutter.io/';
      activity.startActivity(intent);
    },
    child: new Container(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF006600)
      ),
      child: new Center(
        child: new Text('Tap to launch a URL!')
      )
    )
  ));
}
