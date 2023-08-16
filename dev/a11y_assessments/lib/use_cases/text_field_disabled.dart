// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class TextFieldDisabledUseCase extends UseCase {

  @override
  String get name => 'TextField disabled';

  @override
  String get route => '/text-field-disabled';

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
        title: const Text('TextField disabled'),
      ),
      body: Center(
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Email',
            suffixText: '@gmail.com',
            hintText: 'Enter your email',
            enabled: false,
          ),
          controller: TextEditingController(text: 'abc'),
        )
      ),
    );
  }
}
