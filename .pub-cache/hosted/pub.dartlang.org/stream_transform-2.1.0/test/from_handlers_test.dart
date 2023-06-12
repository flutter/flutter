// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/src/from_handlers.dart';
import 'package:test/test.dart';

void main() {
  late StreamController<int> values;
  late List<int> emittedValues;
  late bool valuesCanceled;
  late bool isDone;
  late List<String> errors;
  late Stream<int> transformed;
  late StreamSubscription<int> subscription;

  void setUpForController(StreamController<int> controller,
      Stream<int> Function(Stream<int>) transform) {
    valuesCanceled = false;
    values = controller
      ..onCancel = () {
        valuesCanceled = true;
      };
    emittedValues = [];
    errors = [];
    isDone = false;
    transformed = transform(values.stream);
    subscription =
        transformed.listen(emittedValues.add, onError: errors.add, onDone: () {
      isDone = true;
    });
  }

  group('default from_handlers', () {
    group('Single subscription stream', () {
      setUp(() {
        setUpForController(StreamController(), (s) => s.transformByHandlers());
      });

      test('has correct stream type', () {
        expect(transformed.isBroadcast, false);
      });

      test('forwards values', () async {
        values
          ..add(1)
          ..add(2);
        await Future(() {});
        expect(emittedValues, [1, 2]);
      });

      test('forwards errors', () async {
        values.addError('error');
        await Future(() {});
        expect(errors, ['error']);
      });

      test('forwards done', () async {
        await values.close();
        expect(isDone, true);
      });

      test('forwards cancel', () async {
        await subscription.cancel();
        expect(valuesCanceled, true);
      });
    });

    group('broadcast stream with muliple listeners', () {
      late List<int> emittedValues2;
      late List<String> errors2;
      late bool isDone2;
      late StreamSubscription<int> subscription2;

      setUp(() {
        setUpForController(
            StreamController.broadcast(), (s) => s.transformByHandlers());
        emittedValues2 = [];
        errors2 = [];
        isDone2 = false;
        subscription2 = transformed
            .listen(emittedValues2.add, onError: errors2.add, onDone: () {
          isDone2 = true;
        });
      });

      test('has correct stream type', () {
        expect(transformed.isBroadcast, true);
      });

      test('forwards values', () async {
        values
          ..add(1)
          ..add(2);
        await Future(() {});
        expect(emittedValues, [1, 2]);
        expect(emittedValues2, [1, 2]);
      });

      test('forwards errors', () async {
        values.addError('error');
        await Future(() {});
        expect(errors, ['error']);
        expect(errors2, ['error']);
      });

      test('forwards done', () async {
        await values.close();
        expect(isDone, true);
        expect(isDone2, true);
      });

      test('forwards cancel', () async {
        await subscription.cancel();
        expect(valuesCanceled, false);
        await subscription2.cancel();
        expect(valuesCanceled, true);
      });
    });
  });

  group('custom handlers', () {
    group('single subscription', () {
      setUp(() async {
        setUpForController(
            StreamController(),
            (s) => s.transformByHandlers(onData: (value, sink) {
                  sink.add(value + 1);
                }));
      });
      test('uses transform from handleData', () async {
        values
          ..add(1)
          ..add(2);
        await Future(() {});
        expect(emittedValues, [2, 3]);
      });
    });

    group('broadcast stream with multiple listeners', () {
      late int dataCallCount;
      late int doneCallCount;
      late int errorCallCount;

      setUp(() async {
        dataCallCount = 0;
        doneCallCount = 0;
        errorCallCount = 0;
        setUpForController(
            StreamController.broadcast(),
            (s) => s.transformByHandlers(onData: (value, sink) {
                  dataCallCount++;
                }, onError: (error, stackTrace, sink) {
                  errorCallCount++;
                  sink.addError(error, stackTrace);
                }, onDone: (sink) {
                  doneCallCount++;
                }));
        transformed.listen((_) {}, onError: (_, __) {});
      });

      test('handles data once', () async {
        values.add(1);
        await Future(() {});
        expect(dataCallCount, 1);
      });

      test('handles done once', () async {
        await values.close();
        expect(doneCallCount, 1);
      });

      test('handles errors once', () async {
        values.addError('error');
        await Future(() {});
        expect(errorCallCount, 1);
      });
    });
  });
}
