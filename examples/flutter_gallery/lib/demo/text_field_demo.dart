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

  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  GlobalKey<FormFieldState<InputValue>> _passwordFieldKey = new GlobalKey<FormFieldState<InputValue>>();
  void _handleSubmitted() {
    FormState form = _formKey.currentState;
    if (form.hasErrors) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
    }
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

  String _validatePassword(InputValue value) {
    FormFieldState<InputValue> passwordField = _passwordFieldKey.currentState;
    if (passwordField.value == null || passwordField.value.text.isEmpty)
      return 'Please choose a password.';
    if (passwordField.value.text != value.text)
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
        key: _formKey,
        child: new Block(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            new FormField<InputValue>(
              initialValue: InputValue.empty,
              onSaved: (InputValue val) { person.name = val.text; },
              validator: _validateName,
              builder: (FormFieldState<InputValue> field) {
                return new Input(
                  hintText: 'What do people call you?',
                  labelText: 'Name',
                  value: field.value,
                  onChanged: field.onChanged,
                  errorText: field.errorText
                );
              },
            ),
            new InputFormField(
              hintText: 'Where can we reach you?',
              labelText: 'Phone Number',
              keyboardType: TextInputType.phone,
              onSaved: (InputValue val) { person.phoneNumber = val.text; },
              validator: _validatePhoneNumber,
            ),
            new InputFormField(
              hintText: 'Tell us about yourself (optional)',
              labelText: 'Life story',
              maxLines: 3,
            ),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Flexible(
                  child: new InputFormField(
                    key: _passwordFieldKey,
                    hintText: 'How do you log in?',
                    labelText: 'New Password',
                    hideText: true,
                    onSaved: (InputValue val) { person.password = val.text; }
                  )
                ),
                new SizedBox(width: 16.0),
                new Flexible(
                  child: new InputFormField(
                    hintText: 'How do you log in?',
                    labelText: 'Re-type Password',
                    hideText: true,
                    validator: _validatePassword,
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
