// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/io.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('ProcessSignal', () {

    testUsingContext('signals are properly delegated', () async {
      final MockIoProcessSignal mockSignal = MockIoProcessSignal();
      final ProcessSignal signalUnderTest = ProcessSignal(mockSignal);
      final StreamController<io.ProcessSignal> controller = StreamController<io.ProcessSignal>();

      when(mockSignal.watch()).thenAnswer((Invocation invocation) => controller.stream);
      controller.add(mockSignal);

      expect(signalUnderTest, await signalUnderTest.watch().first);
    });

    testUsingContext('toString() works', () async {
      expect(io.ProcessSignal.sigint.toString(), ProcessSignal.SIGINT.toString());
    });
  });
}

class MockIoProcessSignal extends Mock implements io.ProcessSignal {}
