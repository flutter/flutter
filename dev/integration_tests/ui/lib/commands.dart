// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

String log = '';

void main() {
  enableFlutterDriverExtension(handler: (String message) async {
    log = 'log:';
    await WidgetsBinding.instance.reassembleApplication();
    return log;
  });
  runApp(const MaterialApp(home: Test()));
}

class Test extends SingleChildRenderObjectWidget {
  const Test({ Key key }) : super(key: key);

  @override
  RenderTest createRenderObject(BuildContext context) {
    return RenderTest();
  }
}

class RenderTest extends RenderProxyBox {
  RenderTest({ RenderBox child }) : super(child);

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    log += ' debugPaintSize';
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    log += ' paint';
  }
}
