// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'text_field_constants.dart';

export 'text_field_constants.dart';

/// A page with a normal text field and a password field.
class TextFieldPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _TextFieldPageState();
}

class _TextFieldPageState extends State<TextFieldPage> {
  final TextEditingController _normalController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();
  final Key normalTextFieldKey = const ValueKey<String>(normalTextFieldKeyValue);
  final Key passwordTextFieldKey = const ValueKey<String>(passwordTextFieldKeyValue);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(leading: const BackButton(key: ValueKey<String>('back'))),
      body: new Material(
        child: new Column(children: <Widget>[
          new TextField(
            key: normalTextFieldKey,
            controller: _normalController,
            autofocus: false,
          ),
          const Spacer(),
          new TextField(
            key: passwordTextFieldKey,
            controller: _passwordController,
            obscureText: true,
            autofocus: false,
          ),
        ],
      ),
    ));
  }
}
