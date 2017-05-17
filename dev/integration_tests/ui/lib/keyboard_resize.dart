// Copyright 2017 The Chromium Authors. All rights reserved.
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
      title: 'Text Editing',
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
  TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final TextField textField = new TextField(
      key: const Key(keys.kDefaultTextField),
      controller: _controller,
      focusNode: new FocusNode(),
    );
    return new Scaffold(
      body: new Stack(
        fit: StackFit.expand,
        alignment: FractionalOffset.bottomCenter,
        children: <Widget>[
          new LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return new Center(child: new Text('${constraints.biggest.height}', key: const Key(keys.kHeightText)));
            }
          ),
          textField,
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        key: const Key(keys.kUnfocusButton),
        onPressed: () { textField.focusNode.unfocus(); },
        tooltip: 'Unfocus',
        child: const Icon(Icons.done),
      ),
    );
  }
}
