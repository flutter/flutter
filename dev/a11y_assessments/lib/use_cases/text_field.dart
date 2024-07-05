// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class TextFieldUseCase extends UseCase {

  @override
  String get name => 'TextField';

  @override
  String get route => '/text-field';

  @override
  Widget build(BuildContext context) => const _MainWidget();
}

class _MainWidget extends StatelessWidget {
  const _MainWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TextField'),
      ),
      body: ListView(
        children: <Widget>[
          const TextField(
            key: Key('enabled text field'),
            decoration: InputDecoration(
              labelText: 'Email',
              suffixText: '@gmail.com',
              hintText: 'Enter your email',
            ),
          ),
          TextField(
            key: const Key('disabled text field'),
            decoration: const InputDecoration(
              labelText: 'Email',
              suffixText: '@gmail.com',
              hintText: 'Enter your email',
            ),
            enabled: false,
            controller: TextEditingController(text: 'xyz'),
          ),
        ],
      ),
    );
  }
}
