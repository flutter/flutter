// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextFieldDemo extends StatefulWidget {
  TextFieldDemo({ Key key }) : super(key: key);

  @override
  TextFieldDemoState createState() => new TextFieldDemoState();
}

class TextFieldDemoState extends State<TextFieldDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final List<InputValue> _inputs = <InputValue>[
    InputValue.empty,
    InputValue.empty,
    InputValue.empty,
    InputValue.empty,
  ];

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value)
    ));
  }

  void _handleInputChanged(InputValue value, int which) {
    setState(() {
      _inputs[which] = value;
    });
  }

  void _handleInputSubmitted(InputValue value) {
    showInSnackBar('${_inputs[0].text}\'s phone number is ${_inputs[1].text}');
  }

  String _validateName(InputValue value) {
    if (value.text.isEmpty)
      return 'Name is required.';
    RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value.text))
      return 'Please enter only alphabetical characters.';
    return null;
  }

  String _validatePhoneNumber(InputValue value) {
    RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value.text))
      return '###-###-#### - Please enter a valid phone number.';
    return null;
  }

  String _validatePassword(InputValue value1, InputValue value2) {
    if (value1.text.isEmpty)
      return 'Please choose a password.';
    if (value1.text != value2.text)
      return 'Passwords don\'t match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Text Fields')
      ),
      body: new Block(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          new Input(
            hintText: 'What do people call you?',
            labelText: 'Name',
            errorText: _validateName(_inputs[0]),
            value: _inputs[0],
            onChanged: (InputValue value) { _handleInputChanged(value, 0); },
            onSubmitted: _handleInputSubmitted
          ),
          new Input(
            hintText: 'Where can we reach you?',
            labelText: 'Phone Number',
            errorText: _validatePhoneNumber(_inputs[1]),
            value: _inputs[1],
            onChanged: (InputValue value) { _handleInputChanged(value, 1); },
            onSubmitted: _handleInputSubmitted
          ),
          new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Flexible(
                child: new Input(
                  hintText: 'How do you log in?',
                  labelText: 'New Password',
                  hideText: true,
                  value: _inputs[2],
                  onChanged: (InputValue value) { _handleInputChanged(value, 2); },
                  onSubmitted: _handleInputSubmitted
                )
              ),
              new Flexible(
                child: new Input(
                  hintText: 'How do you log in?',
                  labelText: 'Re-type Password',
                  errorText: _validatePassword(_inputs[2], _inputs[3]),
                  hideText: true,
                  value: _inputs[3],
                  onChanged: (InputValue value) { _handleInputChanged(value, 3); },
                  onSubmitted: _handleInputSubmitted
                )
              )
            ]
          )
        ]
      )
    );
  }
}
