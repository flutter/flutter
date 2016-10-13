// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextFieldDemo extends StatefulWidget {
  TextFieldDemo({ Key key }) : super(key: key);

  static const String routeName = '/text-field';

  @override
  TextFieldDemoState createState() => new TextFieldDemoState();
}

class PersonData {
  String name = '';
  String phoneNumber = '';
  String password = '';
}

class TextFieldDemoState extends State<TextFieldDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  PersonData person = new PersonData();

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value)
    ));
  }

  void _handleSubmitted() {
    // TODO(mpcomplete): Form could keep track of validation errors?
    if (_validateName(person.name) != null ||
        _validatePhoneNumber(person.phoneNumber) != null ||
        _validatePassword(person.password) != null) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
    }
  }

  String _validateName(String value) {
    if (value.isEmpty)
      return 'Name is required.';
    RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value))
      return 'Please enter only alphabetical characters.';
    return null;
  }

  String _validatePhoneNumber(String value) {
    RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value))
      return '###-###-#### - Please enter a valid phone number.';
    return null;
  }

  String _validatePassword(String value) {
    if (person.password == null || person.password.isEmpty)
      return 'Please choose a password.';
    if (person.password != value)
      return 'Passwords don\'t match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Text fields')
      ),
      body: new Form(
        child: new Block(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            new Input(
              hintText: 'What do people call you?',
              labelText: 'Name',
              formField: new FormField<String>(
                // TODO(mpcomplete): replace with person#name=
                setter:  (String val) { person.name = val; },
                validator: _validateName
              )
            ),
            new Input(
              hintText: 'Where can we reach you?',
              labelText: 'Phone Number',
              keyboardType: KeyboardType.phone,
              formField: new FormField<String>(
                setter: (String val) { person.phoneNumber = val; },
                validator: _validatePhoneNumber
              )
            ),
            new Input(
              hintText: 'Tell us about yourself (optional)',
              labelText: 'Life story',
              maxLines: 3,
              formField: new FormField<String>()
            ),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Flexible(
                  child: new Input(
                    hintText: 'How do you log in?',
                    labelText: 'New Password',
                    hideText: true,
                    formField: new FormField<String>(
                      setter: (String val) { person.password = val; }
                    )
                  )
                ),
                new Flexible(
                  child: new Input(
                    hintText: 'How do you log in?',
                    labelText: 'Re-type Password',
                    hideText: true,
                    formField: new FormField<String>(
                      validator: _validatePassword
                    )
                  )
                )
              ]
            ),
            new Container(
              padding: const EdgeInsets.all(20.0),
              alignment: const FractionalOffset(0.5, 0.5),
              child: new RaisedButton(
                child: new Text('SUBMIT'),
                onPressed: _handleSubmitted,
              ),
            )
          ]
        )
      )
    );
  }
}
