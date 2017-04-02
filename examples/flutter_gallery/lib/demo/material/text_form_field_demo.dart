// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

class TextFormFieldDemo extends StatefulWidget {
  TextFormFieldDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/text-form-field';

  @override
  TextFormFieldDemoState createState() => new TextFormFieldDemoState();
}

class PersonData {
  String name = '';
  String phoneNumber = '';
  String password = '';
}

class TextFormFieldDemoState extends State<TextFormFieldDemo> {
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
  final GlobalKey<FormFieldState<String>> _passwordFieldKey = new GlobalKey<FormFieldState<String>>();
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

  String _validateName(String value) {
    _formWasEdited = true;
    if (value.isEmpty)
      return 'Name is required.';
    final RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value))
      return 'Please enter only alphabetical characters.';
    return null;
  }

  String _validatePhoneNumber(String value) {
    _formWasEdited = true;
    final RegExp phoneExp = new RegExp(r'^\d\d\d-\d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value))
      return '###-###-#### - Please enter a valid phone number.';
    return null;
  }

  String _validatePassword(String value) {
    _formWasEdited = true;
    final FormFieldState<String> passwordField = _passwordFieldKey.currentState;
    if (passwordField.value == null || passwordField.value.isEmpty)
      return 'Please choose a password.';
    if (passwordField.value != value)
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
        title: new Text('Text fields'),
      ),
      body: new Form(
        key: _formKey,
        autovalidate: _autovalidate,
        onWillPop: _warnUserAboutInvalidData,
        child: new ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            new TextFormField(
              decoration: const InputDecoration(
                icon: const Icon(Icons.person),
                hintText: 'What do people call you?',
                labelText: 'Name *',
              ),
              onSaved: (String value) { person.name = value; },
              validator: _validateName,
            ),
            new TextFormField(
              decoration: const InputDecoration(
                icon: const Icon(Icons.phone),
                hintText: 'Where can we reach you?',
                labelText: 'Phone Number *',
              ),
              keyboardType: TextInputType.phone,
              onSaved: (String value) { person.phoneNumber = value; },
              validator: _validatePhoneNumber,
            ),
            new TextFormField(
              decoration: const InputDecoration(
                hintText: 'Tell us about yourself',
                labelText: 'Life story',
              ),
              maxLines: 3,
            ),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                  child: new TextFormField(
                    key: _passwordFieldKey,
                    decoration: const InputDecoration(
                      hintText: 'How do you log in?',
                      labelText: 'New Password *',
                    ),
                    obscureText: true,
                    onSaved: (String value) { person.password = value; },
                  ),
                ),
                const SizedBox(width: 16.0),
                new Expanded(
                  child: new TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'How do you log in?',
                      labelText: 'Re-type Password *',
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                ),
              ],
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
          ],
        )
      ),
    );
  }
}
