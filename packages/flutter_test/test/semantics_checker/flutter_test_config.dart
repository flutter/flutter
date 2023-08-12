// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  reportTestException = (FlutterErrorDetails details, String testDescription) {
    errors.add(details);
  };

  // The error that the test throws in their run methods below will be forwarded
  // to our exception handler above and do not cause the test to fail. The
  // tearDown method then checks that the test threw the expected exception.
  await testMain();
}

void pipelineOwnerTestRun() {
  testWidgets('open SemanticsHandle from PipelineOwner fails test', (WidgetTester tester) async {
    final int outstandingHandles = tester.binding.debugOutstandingSemanticsHandles;
    tester.binding.ensureSemantics();
    expect(tester.binding.debugOutstandingSemanticsHandles, outstandingHandles + 1);
    // SemanticsHandle is not disposed on purpose to verify in tearDown that
    // the test failed due to an active SemanticsHandle.
  });

  tearDown(() {
    expect(errors, hasLength(1));
    expect(errors.single.toString(), contains('SemanticsHandle was active at the end of the test'));
  });
}

void semanticsBindingTestRun() {
  testWidgets('open SemanticsHandle from SemanticsBinding fails test', (WidgetTester tester) async {
    final int outstandingHandles = tester.binding.debugOutstandingSemanticsHandles;
    tester.binding.ensureSemantics();
    expect(tester.binding.debugOutstandingSemanticsHandles, outstandingHandles + 1);
    // SemanticsHandle is not disposed on purpose to verify in tearDown that
    // the test failed due to an active SemanticsHandle.
  });

  tearDown(() {
    expect(errors, hasLength(1));
    expect(errors.single.toString(), contains('SemanticsHandle was active at the end of the test'));
  });
}

void failingTestTestRun() {
  testWidgets('open SemanticsHandle from SemanticsBinding fails test', (WidgetTester tester) async {
    final int outstandingHandles = tester.binding.debugOutstandingSemanticsHandles;
    tester.binding.ensureSemantics();
    expect(tester.binding.debugOutstandingSemanticsHandles, outstandingHandles + 1);

    // Failing expectation to verify that an open semantics handle doesn't
    // cause any cascading failures and only the failing expectation is
    // reported.
    expect(1, equals(2));
    fail('The test should never have gotten this far.');
  });

  tearDown(() {
    expect(errors, hasLength(1));
    expect(errors.single.toString(), contains('Expected: <2>'));
    expect(errors.single.toString(), contains('Actual: <1>'));
  });
}
