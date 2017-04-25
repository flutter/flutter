// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum TestStatus { ok, pending, failed, complete }

class TestStepResult {
  static const TestStepResult complete = const TestStepResult(
    'Test complete',
    TestStatus.complete,
  );

  const TestStepResult(
    this.description,
    this.status, {
    this.messageSent = '-',
    this.messageEcho = '-',
    this.messageReceived = '-',
    this.replyEcho = '-',
  });

  factory TestStepResult.fromSnapshot(AsyncSnapshot<TestStepResult> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return new TestStepResult('Not started', TestStatus.ok);
      case ConnectionState.waiting:
        return new TestStepResult('Executing', TestStatus.pending);
      case ConnectionState.done:
        return (snapshot.hasData)
            ? snapshot.data
            : new TestStepResult(
                'Failed: ${snapshot.error}', TestStatus.failed);
      default:
        throw 'Unsupported state ${snapshot.connectionState}';
    }
  }

  final String description;
  final String messageSent;
  final String messageEcho;
  final String messageReceived;
  final String replyEcho;
  final TestStatus status;

  Widget asWidget(BuildContext context) {
    return new Column(children: <Widget>[
      new Text('Step: $description'),
      new Text('Msg sent: $messageSent'),
      new Text('Msg echo: $messageEcho'),
      new Text('Msg rvcd: $messageReceived'),
      new Text('Reply echo: $replyEcho'),
      new Text(
        status.toString().substring('TestStatus.'.length),
        key: new ValueKey<String>(
            status == TestStatus.pending ? 'nostatus' : 'status'),
      ),
    ]);
  }
}
