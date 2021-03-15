// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/test/event_printer.dart';
import 'package:flutter_tools/src/test/test_device.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group(EventPrinter, () {
    final Uri observatoryUri = Uri.parse('http://localhost:1234');
    EventPrinter eventPrinter;
    StringBuffer output;

    setUp(() {
      output = StringBuffer();
      eventPrinter = EventPrinter(out: output);
    });

    testWithoutContext('handles a null parent', () {
      final FakeDevice device = FakeDevice();

      expect(() => eventPrinter.handleFinishedTest(device), returnsNormally);
      expect(() => eventPrinter.handleStartedDevice(observatoryUri), returnsNormally);
      expect(() => eventPrinter.handleTestCrashed(device), returnsNormally);
      expect(() => eventPrinter.handleTestTimedOut(device), returnsNormally);
    });

    group('handleStartedDevice', () {
      testWithoutContext('with non-null observatory', () {
        eventPrinter.handleStartedDevice(observatoryUri);

        expect(
          output.toString(),
          '\n'
          '[{"event":"test.startedProcess","params":{"observatoryUri":"http://localhost:1234"}}]'
          '\n',
        );
      });

      testWithoutContext('with null observatory', () {
        eventPrinter.handleStartedDevice(null);

        expect(
          output.toString(),
          '\n'
          '[{"event":"test.startedProcess","params":{"observatoryUri":null}}]'
          '\n',
        );
      });
    });
  });
}

class FakeDevice extends Fake implements TestDevice {}
