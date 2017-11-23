// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_driver/src/common/find.dart';
import 'package:flutter_driver/src/common/request_data.dart';
import 'package:flutter_driver/src/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('waitUntilNoTransientCallbacks', () {
    FlutterDriverExtension extension;
    Map<String, dynamic> result;
    int messageId = 0;
    final List<String> log = <String>[];

    setUp(() {
      result = null;
      extension = new FlutterDriverExtension((String message) async { log.add(message); return (messageId += 1).toString(); });
    });

    testWidgets('returns immediately when transient callback queue is empty', (WidgetTester tester) async {
      extension.call(new WaitUntilNoTransientCallbacks().serialize())
          .then<Null>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      await tester.idle();
      expect(
          result,
          <String, dynamic>{
            'isError': false,
            'response': null,
          },
      );
    });

    testWidgets('waits until no transient callbacks', (WidgetTester tester) async {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Intentionally blank. We only care about existence of a callback.
      });

      extension.call(new WaitUntilNoTransientCallbacks().serialize())
          .then<Null>(expectAsync1((Map<String, dynamic> r) {
        result = r;
      }));

      // Nothing should happen until the next frame.
      await tester.idle();
      expect(result, isNull);

      // NOW we should receive the result.
      await tester.pump();
      expect(
          result,
          <String, dynamic>{
            'isError': false,
            'response': null,
          },
      );
    });

    testWidgets('handler', (WidgetTester tester) async {
      expect(log, isEmpty);
      final dynamic result = RequestDataResult.fromJson((await extension.call(new RequestData('hello').serialize()))['response']);
      expect(log, <String>['hello']);
      expect(result.message, '1');
    });
  });
}
