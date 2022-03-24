// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      key: Key('mainapp'),
      title: 'Integration Test App For Platform Messages',
      home: MyHomePage(title: 'Integration Test App For Platform Messages'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State createState() => _MyHomePageState();
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
