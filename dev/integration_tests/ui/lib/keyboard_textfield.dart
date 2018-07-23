// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'keys.dart' as keys;

void main() {
  enableFlutterDriverExtension();

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Keyboard & TextField',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _controller = new ScrollController();
  double offset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        offset = _controller.offset;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        children: <Widget>[
          new Text('$offset',
            key: const ValueKey<String>(keys.kOffsetText),
          ),
          new Expanded(
            child: new ListView(
              key: const ValueKey<String>(keys.kListView),
              controller: _controller,
              children: <Widget>[
                new Container(
                  height: MediaQuery.of(context).size.height,
                ),
                const TextField(
                  key: ValueKey<String>(keys.kDefaultTextField),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
