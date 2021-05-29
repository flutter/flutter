// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('dispose does not throw exception if no process is present', () {
    final ForwardedPort forwardedPort = ForwardedPort(123, 456);
    expect(forwardedPort.context, isNull);
    forwardedPort.dispose();
  });

  testUsingContext('dispose kills process if process was available', () {
    final MockProcess mockProcess = MockProcess();
    final ForwardedPort forwardedPort = ForwardedPort.withContext(123, 456, mockProcess);
    forwardedPort.dispose();
    expect(forwardedPort.context, isNotNull);
    verify(mockProcess.kill());
  });
}

class MockProcess extends Mock implements Process {}
