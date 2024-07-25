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
          Semantics(
            key: const Key('enabled password semantics wrapper'),
            child: const TextField(
              key: Key('enabled password'),
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ),
          Semantics(
            key: const Key('disabled password semantics wrapper'),
            child: const TextField(
              key: Key('disabled password'),
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              enabled: false,
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }
}
