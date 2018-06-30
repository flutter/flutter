// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/selection_controls.dart';
import 'src/text_fields.dart';

void main() {
  enableFlutterDriverExtension(handler: dataHandler);
  runApp(new TestApp());
}

const MethodChannel kSemanticsChannel = const MethodChannel('semantics');

Future<String> dataHandler(String message) async {
  if (message.contains('getSemanticsNode')) {
    final int id = int.tryParse(message.split('#')[1]) ?? 0;
    final dynamic result = await kSemanticsChannel.invokeMethod('getSemanticsNode', <String, dynamic>{
      'id': id,
    });
    return json.encode(result);
  }
  throw new UnimplementedError();
}


class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      routes: <String, WidgetBuilder>{
        'SelectionControls': (BuildContext context) => new SelectionControlsPage(),
        'TextFields': (BuildContext context) => new TextFieldsPage(),
      },
      home: new StatefulBuilder(builder: (BuildContext context, Function setState) {
        return new Scaffold(
          body: new Column(children: <Widget>[
            new OutlineButton(
              child: const Text('SelectionControls'),
              onPressed: () {
                Navigator.of(context).pushNamed('SelectionControls');
              }
            ),
            new OutlineButton(
              child: const Text('TextFields'),
              onPressed: () {
                Navigator.of(context).pushNamed('TextFields');
              },
            )
          ]),
        );
      }),
    );
  }
}