// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'text_field_constants.dart';

export 'text_field_constants.dart';

/// A page with a normal text field and a password field.
class TextFieldPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TextFieldPageState();
}

class _TextFieldPageState extends State<TextFieldPage> {
  final TextEditingController _normalController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Key normalTextFieldKey = const ValueKey<String>(normalTextFieldKeyValue);
  final Key passwordTextFieldKey = const ValueKey<String>(passwordTextFieldKeyValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(key: ValueKey<String>('back'))),
      body: Material(
        child: Column(children: <Widget>[
          TextField(
            key: normalTextFieldKey,
            controller: _normalController,
            autofocus: false,
          ),
          const Spacer(),
          TextField(
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
