// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/tests/controls_page.dart';

void main() {
  enableFlutterDriverExtension(handler: dataHandler);
  runApp(const TestApp());
}

const MethodChannel kSemanticsChannel = MethodChannel('semantics');

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

const List<String> routes = <String>[
  selectionControlsRoute,
];

class TestApp extends StatelessWidget {
  const TestApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      routes: <String, WidgetBuilder>{
        selectionControlsRoute: (BuildContext context) => new SelectionControlsPage(),
      },
      home: new Builder(
        builder: (BuildContext context) {
          return new Scaffold(
            body: new Column(
              children: routes.map((String value) {
                return new MaterialButton(
                  child: new Text(value),
                  onPressed: () {
                    Navigator.of(context).pushNamed(value);
                  },
                );
              }).toList(),
            ),
          );
        }
      ),
    );
  }
}
