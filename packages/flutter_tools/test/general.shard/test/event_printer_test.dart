// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/test/event_printer.dart';
import 'package:flutter_tools/src/test/test_device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('EventPrinter handles a null parent', () {
    final EventPrinter eventPrinter = EventPrinter(out: StringBuffer());
    final _Device device = _Device();
    final Uri observatoryUri = Uri.parse('http://localhost:1234');

    expect(() => eventPrinter.handleFinishedTest(device), returnsNormally);
    expect(() => eventPrinter.handleStartedDevice(observatoryUri), returnsNormally);
    expect(() => eventPrinter.handleTestCrashed(device), returnsNormally);
    expect(() => eventPrinter.handleTestTimedOut(device), returnsNormally);
  });
}

class _Device extends Mock implements TestDevice {}
