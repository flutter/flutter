// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/context.dart' hide context;
import 'package:flutter_tools/src/base/context.dart' as pkg;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:test/test.dart';

void main() {
  group('AppContext', () {
    test('error', () async {
      AppContext context = new AppContext();
      BufferLogger mockLogger = new BufferLogger();
      context.setVariable(Logger, mockLogger);

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
      context.setVariable(Logger, mockLogger);

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
      context.setVariable(Logger, mockLogger);

      await context.runInZone(() {
        printTrace('foo bar');
      });

      expect(mockLogger.errorText, '');
      expect(mockLogger.statusText, '');
      expect(mockLogger.traceText, 'foo bar\n');
    });

    test('awaitNestedZones', () async {
      AppContext outerContext = new AppContext();
      await outerContext.runInZone(() async {
        AppContext middleContext = new AppContext();
        await middleContext.runInZone(() async {
          AppContext innerContext = new AppContext();
          await innerContext.runInZone(() async {
            expect(innerContext.getVariable(String), isNull);
          });
        });
      });
    });

    test('fireAndForgetNestedZones', () async {
      AppContext outerContext = new AppContext();
      outerContext.runInZone(() async {
        AppContext middleContext = new AppContext();
        middleContext.runInZone(() async {
          AppContext innerContext = new AppContext();
          innerContext.runInZone(() async {
            expect(innerContext.getVariable(String), isNull);
          });
        });
      });
    });

    test('overriddenValuesInNestedZones', () async {
      expect(pkg.context, isNull);
      AppContext outerContext = new AppContext();
      outerContext.setVariable(String, 'outer');
      outerContext.runInZone(() async {
        expect(pkg.context[String], 'outer');
        AppContext middleContext = new AppContext();
        middleContext.setVariable(String, 'middle');
        middleContext.runInZone(() async {
          expect(pkg.context[String], 'middle');
          AppContext innerContext = new AppContext();
          innerContext.setVariable(String, 'inner');
          innerContext.runInZone(() async {
            expect(pkg.context[String], 'inner');
          });
          expect(pkg.context[String], 'middle');
        });
        expect(pkg.context[String], 'outer');
      });
    });
  });
}
