// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextFieldsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _TextFieldsPageState();
}

class _TextFieldsPageState extends State<TextFieldsPage> {
  final TextEditingController _controller1 = new TextEditingController();
  final TextEditingController _controller2 = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(leading: const BackButton(key: const ValueKey<String>('back'))),
      body: new Material(
        child: new ListView(
          children: <Widget>[
            new TextFormField(
              key: const ValueKey<String>('TextFields#TextField1'),
              controller: _controller1,
              decoration: const InputDecoration(
                hintText: 'What is your name?',
                labelText: 'Name',
              ),
            ),
            new TextFormField(
              key: const ValueKey<String>('TextFields#TextField2'),
              controller: _controller2,
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

}