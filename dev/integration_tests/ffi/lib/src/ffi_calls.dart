// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'generated/all.dart' as ffi_tests;

Future<TestStatusResult> testFfiCall() async {
  try {
    await ffi_tests.main();
  } catch (e, s) {
    print('FFI Tests failed\nException:$e\nStack:$s');
    return TestStatusResult('Failed', 'FFI tests failed with "$e"\n$s');
  }
  return TestStatusResult.successful;
}

typedef TestStatus = Future<TestStatusResult> Function();

class TestStatusResult {
  const TestStatusResult(
    this.name,
    this.description);

  factory TestStatusResult.fromSnapshot(AsyncSnapshot<TestStatusResult> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return start;
      case ConnectionState.waiting:
        return executing;
      case ConnectionState.done:
        return snapshot.data;
      default:
        throw 'Unsupported state ${snapshot.connectionState}';
    }
  }

  final String name;
  final String description;

  static const TestStatusResult start = TestStatusResult('Start', '');
  static const TestStatusResult executing = TestStatusResult('Executing', '');
  static const TestStatusResult successful = TestStatusResult('Success', '');

  static const TextStyle bold = TextStyle(fontWeight: FontWeight.bold);

  Widget asWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Status: $name', style: bold, key: const ValueKey<String>('status')),
        Text('Outcome: $description', style: bold, key: const ValueKey<String>('outcome')),
      ],
    );
  }
}
