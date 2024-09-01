// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class TextFieldUseCase extends UseCase {
  @override
  String get name => 'TextField';

  @override
  String get route => '/text-field';

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatelessWidget {
  _MainWidget();

  final String pageTitle = getUseCaseName(TextFieldUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: ListView(
        children: <Widget>[
          Semantics(
            label: 'Input field with suffix @gmail.com',
            child: const TextField(
              key: Key('enabled text field'),
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Email',
                suffixText: '@gmail.com',
                hintText: 'Enter your email',
              ),
            ),
          ),
          Semantics(
            label: 'Input field with suffix @gmail.com',
            child: TextField(
              key: const Key('disabled text field'),
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
        ],
      ),
    );
  }
}
