// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/test/event_printer.dart';
import 'package:flutter_tools/src/test/watcher.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';

void main() {
  testWithoutContext('EventPrinter handles a null parent', () {
    final EventPrinter eventPrinter = EventPrinter(out: StringBuffer());
    final ProcessEvent processEvent = ProcessEvent(0, FakeProcess());

    expect(() => eventPrinter.handleFinishedTest(processEvent), returnsNormally);
    expect(() => eventPrinter.handleStartedProcess(processEvent), returnsNormally);
    expect(() => eventPrinter.handleTestCrashed(processEvent), returnsNormally);
    expect(() => eventPrinter.handleTestTimedOut(processEvent), returnsNormally);
  });
}
