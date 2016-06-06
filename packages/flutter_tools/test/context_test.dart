// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/context.dart' hide context;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:test/test.dart';

void main() {
  group('DeviceManager', () {
    test('error', () async {
      AppContext context = new AppContext();
      BufferLogger mockLogger = new BufferLogger();
      context[Logger] = mockLogger;

      await context.runInZone(() {
        printError('foo bar');
      });

      expect(mockLogger.errorText, 'foo bar\n');
      expect(mockLogger.statusText, '');
      expect(mockLogger.traceText, '');
    });

    test('status', () async {
      AppContext context = new AppContext();
      BufferLogger mockLogger = new BufferLogger();
      context[Logger] = mockLogger;

      await context.runInZone(() {
        printStatus('foo bar');
      });

      expect(mockLogger.errorText, '');
      expect(mockLogger.statusText, 'foo bar\n');
      expect(mockLogger.traceText, '');
    });

    test('trace', () async {
      AppContext context = new AppContext();
      BufferLogger mockLogger = new BufferLogger();
      context[Logger] = mockLogger;

      await context.runInZone(() {
        printTrace('foo bar');
      });

      expect(mockLogger.errorText, '');
      expect(mockLogger.statusText, '');
      expect(mockLogger.traceText, 'foo bar\n');
    });
  });
}
