// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/executable.dart' as tools;
import 'package:flutter_tools/src/base/io.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void testReplay(
  String description,
  dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides: const <Type, Generator>{},
  bool skip,
}) {
  setUp(() {
    setExitFunctionForTests();
  });

  tearDown(() {
    restoreExitFunction();
  });

  testUsingContext(
    description,
    testMethod,
    timeout: timeout,
    overrides: overrides,
    skip: skip,
    initializeContext: (_) {},
  );
}

void expectProcessExits(List<String> command, {dynamic exitCode: 0}) {
  final Future<Null> mainFuture = tools.main(command);
  expect(mainFuture, throwsProcessExit(exitCode));
}
