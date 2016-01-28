// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('DeviceManager', () {
    test('error', () async {
      MockContext mockContext = new MockContext();

      runZoned(() {
        printError('foo bar');
      }, zoneValues: {'context': mockContext});

      expect(mockContext.errorText, 'foo bar\n');
      expect(mockContext.statusText, '');
      expect(mockContext.traceText, '');
    });

    test('status', () async {
      MockContext mockContext = new MockContext();

      runZoned(() {
        printStatus('foo bar');
      }, zoneValues: {'context': mockContext});

      expect(mockContext.errorText, '');
      expect(mockContext.statusText, 'foo bar\n');
      expect(mockContext.traceText, '');
    });

    test('trace', () async {
      MockContext mockContext = new MockContext();

      runZoned(() {
        printTrace('foo bar');
      }, zoneValues: {'context': mockContext});

      expect(mockContext.errorText, '');
      expect(mockContext.statusText, '');
      expect(mockContext.traceText, 'foo bar\n');
    });
  });
}

class MockContext implements AppContext {
  bool verbose = false;

  StringBuffer _error = new StringBuffer();
  StringBuffer _status = new StringBuffer();
  StringBuffer _trace = new StringBuffer();

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();

  void printError(String message, [StackTrace stackTrace]) => _error.writeln(message);
  void printStatus(String message) => _status.writeln(message);
  void printTrace(String message) => _trace.writeln(message);
}
