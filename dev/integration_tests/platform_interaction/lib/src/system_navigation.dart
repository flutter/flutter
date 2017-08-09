// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'test_step.dart';

Future<TestStepResult> systemNavigatorPop() async {
  const BasicMessageChannel<String> channel = const BasicMessageChannel<String>(
    'SystemNavigator.pop',
    const StringCodec(),
  );

  TestStatus status = TestStatus.failed;
  channel.setMessageHandler((String message) async {
    status = TestStatus.ok;
    return '';
  });
  await SystemNavigator.pop();
  return new TestStepResult('System navigation pop', '', status);
}