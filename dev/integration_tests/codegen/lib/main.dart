// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'message.dart' as generated; // ignore: uri_does_not_exist

Future<void> main() async {
  enableFlutterDriverExtension();
  runApp(ExampleWidget());
}

class ExampleWidget extends StatefulWidget {
  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: const Text('Press Button, Get Coffee'),
              onPressed: () async {
                setState(() {
                 _pressed = true;
                });
              },
            ),
            _pressed ? GeneratedWidget() : const SizedBox(),
          ],
        ),
      ),
    );
  }
}

class GeneratedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(generated.message);
  }
}
