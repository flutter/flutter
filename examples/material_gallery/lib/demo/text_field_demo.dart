// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class LoginData {
  String name;
  String phoneNumber;
  String password;

  String setName(String value) {
    if (value.isEmpty)
      return 'Name is required.';
    RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value))
      return 'Please enter only alphabetical characters.';
    this.name = value;
    return null;
  }

  String setPhoneNumber(String value) {
    RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value))
      return '###-###-#### - Please enter a valid phone number.';
    this.phoneNumber = value;
    return null;
  }

  String setPassword(String value, String retypeValue) {
    if (value.isEmpty)
      return 'Please choose a password.';
    if (value != retypeValue)
      return 'Passwords don\'t match';
    this.password = value;
    return null;
  }
}

class TextFieldDemo extends StatefulComponent {
  TextFieldDemo({ Key key }) : super(key: key);

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
  LoginData _login = new LoginData();

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value)
    ));
  }

  String _handleInputChanged(InputValue value, int which) {
    setState(() {
      _inputs[which] = value;
    });
    return value.text;
  }

  void _handleInputSubmitted(InputValue value) {
    showInSnackBar('${_login.name}\'s phone number is ${_login.phoneNumber}');
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      toolBar: new ToolBar(
        center: new Text('Text Fields')
      ),
      body: new Block(
        padding: const EdgeDims.all(8.0),
        children: <Widget>[
          new Input(
            hintText: 'What do people call you?',
            labelText: 'Name',
            errorText: _login.setName(_inputs[0].text),
            value: _inputs[0],
            onChanged: (InputValue value) { _login.setName(_handleInputChanged(value, 0)); },
            onSubmitted: _handleInputSubmitted
          ),
          new Input(
            hintText: 'Where can we reach you?',
            labelText: 'Phone Number',
            errorText: _login.setPhoneNumber(_inputs[1].text),
            value: _inputs[1],
            onChanged: (InputValue value) { _login.setPhoneNumber(_handleInputChanged(value, 1)); },
            onSubmitted: _handleInputSubmitted
          ),
          new Row(
            alignItems: FlexAlignItems.start,
            children: <Widget>[
              new Flexible(
                child: new Input(
                  hintText: 'How do you log in?',
                  labelText: 'New Password',
                  hideText: true,
                  value: _inputs[2],
                  onChanged: (InputValue value) { _login.setPassword(_handleInputChanged(value, 2), _inputs[3].text); },
                  onSubmitted: _handleInputSubmitted
                )
              ),
              new Flexible(
                child: new Input(
                  hintText: 'How do you log in?',
                  labelText: 'Re-type Password',
                  errorText: _login.setPassword(_inputs[2].text, _inputs[3].text),
                  hideText: true,
                  value: _inputs[3],
                  onChanged: (InputValue value) { _login.setPassword(_inputs[2].text, _handleInputChanged(value, 3)); },
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
