// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

Future<ClipboardData> dataFuture;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const Key('mainapp'),
      title: 'Integration Test App For Platform Messages',
      home: MyHomePage(title: 'Integration Test App For Platform Messages'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller =
  TextEditingController(text: 'Text1');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
              const Text('Hello World',
            ),
            // Create a text form field since we can't test clipboard unless
            // html document has focus.
            TextFormField(
              key: const Key('input'),
              enabled: true,
              controller: _controller,
              //initialValue: 'Text1',
              decoration: const InputDecoration(
                labelText: 'Text Input Field:',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
