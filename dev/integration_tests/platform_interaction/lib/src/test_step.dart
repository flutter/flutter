// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum TestStatus { ok, pending, failed, complete }

typedef Future<TestStepResult> TestStep();

const String nothing = '-';

class TestStepResult {
  static const TextStyle bold = const TextStyle(fontWeight: FontWeight.bold);
  static const TestStepResult complete = const TestStepResult(
    'Test complete',
    nothing,
    TestStatus.complete,
  );

  const TestStepResult(this.name, this.description, this.status);

  factory TestStepResult.fromSnapshot(AsyncSnapshot<TestStepResult> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return const TestStepResult('Not started', nothing, TestStatus.ok);
      case ConnectionState.waiting:
        return const TestStepResult('Executing', nothing, TestStatus.pending);
      case ConnectionState.done:
        if (snapshot.hasData) {
          return snapshot.data;
        } else {
          final TestStepResult result = snapshot.error;
          return result;
        }
        break;
      default:
        throw 'Unsupported state ${snapshot.connectionState}';
    }
  }

  final String name;
  final String description;
  final TestStatus status;

  Widget asWidget(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Text('Step: $name', style: bold),
        new Text(description),
        const Text(' '),
        new Text(
          status.toString().substring('TestStatus.'.length),
          key: new ValueKey<String>(
              status == TestStatus.pending ? 'nostatus' : 'status'),
          style: bold,
        ),
      ],
    );
  }
}
