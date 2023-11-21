// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class TextFieldPasswordUseCase extends UseCase {

  @override
  String get name => 'TextField password';

  @override
  String get route => '/text-field-password';

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
        title: const Text('TextField password'),
      ),
      body: ListView(
        children: <Widget>[
          TextField(
            key: const Key('enabled password'),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
            ),
            obscureText: true,
          ),
          TextField(
            key: const Key('disabled password'),
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
            ),
            enabled: false,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}
