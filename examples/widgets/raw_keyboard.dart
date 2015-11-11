// Copyright (c) 2015, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sky_services/raw_keyboard/raw_keyboard.mojom.dart' as mojo;
import 'package:sky_services/sky/input_event.mojom.dart' as mojo;

void main() {
  runApp(
    new MaterialApp(
      title: "Hardware Key Demo",
      routes: {
        '/': (RouteArguments args) => const HardwareKeyDemo()
      }
    )
  );
}

class HardwareKeyDemo extends StatefulComponent {
  const HardwareKeyDemo();
  HardwareKeyDemoState createState() => new HardwareKeyDemoState();
}

class HardwareKeyDemoState extends State<HardwareKeyDemo> implements mojo.RawKeyboardListener {

  mojo.InputEvent _event = null;

  void initState() {
    mojo.RawKeyboardServiceProxy rawKeyboardService = new mojo.RawKeyboardServiceProxy.unbound();
    try {
      shell.connectToService(null, rawKeyboardService);
      mojo.RawKeyboardListenerStub listener = new mojo.RawKeyboardListenerStub.unbound()
        ..impl = this;
      rawKeyboardService.ptr.addListener(listener);
    } finally {
      rawKeyboardService.close();
    }
    super.initState();
  }

  void onKey(mojo.InputEvent event) {
    setState(() {
      _event = event;
    });
  }

  Widget _buildBody() {
    if (_event == null) {
      return new Center(
        child: new Text("Press a key", style: Typography.black.display1)
      );
    }
    return new Column([
        new Text(
          '${_event.type}',
          style: Typography.black.body2
        ),
        new Text(
          '${_event.keyData.keyCode}',
          style: Typography.black.display4
        )
    ], justifyContent: FlexJustifyContent.center);
  }

  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Hardware Key Demo")
      ),
      body: new Material(
        child: _buildBody()
      )
    );
  }
}
