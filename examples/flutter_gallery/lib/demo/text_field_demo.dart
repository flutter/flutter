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
  String lifeStory = '';
  String password = '';
}

class TextFieldDemoState extends State<TextFieldDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  static PersonData person = new PersonData();

  FormField<InputValue> _name;
  FormField<InputValue> _phoneNumber;
  FormField<InputValue> _lifeStory;
  FormField<InputValue> _password1;
  FormField<InputValue> _password2;

  @override
  void initState() {
    super.initState();
    _name = new FormField<InputValue>(
      initialValue: new InputValue(text: person.name),
      validator: _validateName,
    );
    _phoneNumber = new FormField<InputValue>(
      initialValue: new InputValue(text: person.phoneNumber),
      validator: _validatePhoneNumber,
    );
    _lifeStory = new FormField<InputValue>(
      initialValue: new InputValue(text: person.lifeStory),
    );
    _password1 = new FormField<InputValue>(
      initialValue: new InputValue(text: person.password),
    );
    _password2 = new FormField<InputValue>(
      initialValue: new InputValue(text: person.password),
      validator: _validatePassword,
    );
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value)
    ));
  }

  void _handleSubmitted() {
    if (_validateName(_name.value) != null ||
        _validatePhoneNumber(_phoneNumber.value) != null ||
        _validatePassword(_password2.value) != null) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      person.name = _name.value.text;
      person.phoneNumber = _phoneNumber.value.text;
      person.lifeStory = _lifeStory.value.text;
      person.password = _password1.value.text;
      showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
    }
  }

  String _validateName(InputValue value) {
    if (value.text.isEmpty)
      return 'Name is required.';
    RegExp nameExp = new RegExp(r'\S');
    if (!nameExp.hasMatch(value.text))
      return 'Please enter at least one non-whitespace character.';
    return null;
  }

  String _validatePhoneNumber(InputValue value) {
    RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value.text))
      return '###-###-#### - Please enter a valid US phone number.';
    return null;
  }

  String _validatePassword(InputValue value) {
    if (_password1.value.text == null || _password1.value.text.isEmpty)
      return 'Please choose a password.';
    if (_password1.value.text != value.text)
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
              formField: _name,
            ),
            new Input(
              hintText: 'Where can we reach you?',
              labelText: 'Phone Number',
              keyboardType: KeyboardType.phone,
              formField: _phoneNumber,
            ),
            new Input(
              hintText: 'Tell us about yourself (optional)',
              labelText: 'Life story',
              maxLines: 3,
              formField: _lifeStory,
            ),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Flexible(
                  child: new Input(
                    hintText: 'How do you log in?',
                    labelText: 'New Password',
                    hideText: true,
                    formField: _password1,
                  )
                ),
                new Flexible(
                  child: new Input(
                    hintText: 'How do you log in?',
                    labelText: 'Re-type Password',
                    hideText: true,
                    formField: _password2,
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
