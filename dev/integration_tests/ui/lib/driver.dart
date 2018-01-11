// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension(handler: (String message) async {
    // TODO(cbernaschina) remove when test flakiness is resolved
    return 'driver';
  });
  runApp(new DriverTestApp());
}

class DriverTestApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DriverTestAppState();
  }
}

class DriverTestAppState extends State<DriverTestApp> {
  bool present = true;
  Letter _selectedValue = Letter.a;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('FlutterDriver test'),
        ),
        body: new ListView(
          padding: const EdgeInsets.all(5.0),
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Expanded(
                  child: new Text(present ? 'present' : 'absent'),
                ),
                new RaisedButton(
                  child: const Text(
                    'toggle',
                    key: const ValueKey<String>('togglePresent'),
                  ),
                  onPressed: () {
                    setState(() {
                      present = !present;
                    });
                  },
                ),
              ],
            ),
            new Row(
              children: <Widget>[
                const Expanded(
                  child: const Text('hit testability'),
                ),
                new DropdownButton<Letter>(
                  key: const ValueKey<String>('dropdown'),
                  value: _selectedValue,
                  onChanged: (Letter newValue) {
                    setState(() {
                      _selectedValue = newValue;
                    });
                  },
                  items: const <DropdownMenuItem<Letter>>[
                    const DropdownMenuItem<Letter>(
                      value: Letter.a,
                      child: const Text('Aaa', key: const ValueKey<String>('a')),
                    ),
                    const DropdownMenuItem<Letter>(
                      value: Letter.b,
                      child: const Text('Bbb', key: const ValueKey<String>('b')),
                    ),
                    const DropdownMenuItem<Letter>(
                      value: Letter.c,
                      child: const Text('Ccc', key: const ValueKey<String>('c')),
                    ),
                  ],
                ),
              ],
            ),
            const TextField(
              key: const ValueKey<String>('enter-text-field'),
            ),
          ],
        ),
      ),
    );
  }
}

enum Letter { a, b, c }
