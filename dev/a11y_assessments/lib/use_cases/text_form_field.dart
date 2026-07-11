// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class TextFormFieldUseCase extends UseCase {
  TextFormFieldUseCase();

  @override
  String get name => 'TextFormField';

  @override
  String get route => '/text-form-field';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatefulWidget {
  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String pageTitle = getUseCaseName(TextFormFieldUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Semantics(
              label: 'Enabled text form field',
              child: TextFormField(
                key: const Key('enabled text form field'),
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  suffixText: '@gmail.com',
                  hintText: 'Enter your email',
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
            Semantics(
              label: 'Disabled text form field',
              child: TextFormField(
                key: const Key('disabled text form field'),
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  suffixText: '@gmail.com',
                  hintText: 'Enter your email',
                ),
                enabled: false,
                controller: TextEditingController(text: 'xyz'),
              ),
            ),
            ElevatedButton(
              key: const Key('submit button'),
              onPressed: () {
                _formKey.currentState!.validate();
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
