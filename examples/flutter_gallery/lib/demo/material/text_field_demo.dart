// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

class TextFieldDemo extends StatefulWidget {
  TextFieldDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/text-field';

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

  bool _autovalidate = false;
  bool _formWasEdited = false;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final GlobalKey<FormFieldState<InputValue>> _passwordFieldKey = new GlobalKey<FormFieldState<InputValue>>();
  void _handleSubmitted() {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      _autovalidate = true;  // Start validating on every change.
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      showInSnackBar('${person.name}\'s phone number is ${person.phoneNumber}');
    }
  }

  String _validateName(InputValue value) {
    _formWasEdited = true;
    if (value.text.isEmpty)
      return 'Name is required.';
    final RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value.text))
      return 'Please enter only alphabetical characters.';
    return null;
  }

  String _validatePhoneNumber(InputValue value) {
    _formWasEdited = true;
    final RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value.text))
      return '###-###-#### - Please enter a valid phone number.';
    return null;
  }

  String _validatePassword(InputValue value) {
    _formWasEdited = true;
    final FormFieldState<InputValue> passwordField = _passwordFieldKey.currentState;
    if (passwordField.value == null || passwordField.value.text.isEmpty)
      return 'Please choose a password.';
    if (passwordField.value.text != value.text)
      return 'Passwords don\'t match';
    return null;
  }

  Future<bool> _warnUserAboutInvalidData() {
    final FormState form = _formKey.currentState;
    if (!_formWasEdited || form.validate())
      return new Future<bool>.value(true);

    return showDialog<bool>(
      context: context,
      child: new AlertDialog(
        title: new Text('This form has errors'),
        content: new Text('Really leave this form?'),
        actions: <Widget> [
          new FlatButton(
            child: new Text('YES'),
            onPressed: () { Navigator.of(context).pop(true); },
          ),
          new FlatButton(
            child: new Text('NO'),
            onPressed: () { Navigator.of(context).pop(false); },
          ),
        ],
      ),
    );
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
        autovalidate: _autovalidate,
        onWillPop: _warnUserAboutInvalidData,
        child: new ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            new TextField(
              icon: new Icon(Icons.person),
              hintText: 'What do people call you?',
              labelText: 'Name *',
              onSaved: (InputValue val) { person.name = val.text; },
              validator: _validateName,
            ),
            new TextField(
              icon: new Icon(Icons.phone),
              hintText: 'Where can we reach you?',
              labelText: 'Phone Number *',
              keyboardType: TextInputType.phone,
              onSaved: (InputValue val) { person.phoneNumber = val.text; },
              validator: _validatePhoneNumber,
            ),
            new TextField(
              hintText: 'Tell us about yourself',
              labelText: 'Life story',
              maxLines: 3,
            ),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                    key: _passwordFieldKey,
                    hintText: 'How do you log in?',
                    labelText: 'New Password *',
                    obscureText: true,
                    onSaved: (InputValue val) { person.password = val.text; }
                  )
                ),
                const SizedBox(width: 16.0),
                new Expanded(
                  child: new TextField(
                    hintText: 'How do you log in?',
                    labelText: 'Re-type Password *',
                    obscureText: true,
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
            ),
            new Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: new Text('* indicates required field', style: Theme.of(context).textTheme.caption),
            ),
          ]
        )
      )
    );
  }
}
