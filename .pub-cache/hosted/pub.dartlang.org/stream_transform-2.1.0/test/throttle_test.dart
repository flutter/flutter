// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  for (var streamType in streamTypes) {
    group('Stream type [$streamType]', () {
      late StreamController<int> values;
      late List<int> emittedValues;
      late bool valuesCanceled;
      late bool isDone;
      late Stream<int> transformed;
      late StreamSubscription<int> subscription;

      group('throttle - trailing: false', () {
        setUp(() async {
          valuesCanceled = false;
          values = createController(streamType)
            ..onCancel = () {
              valuesCanceled = true;
            };
          emittedValues = [];
          isDone = false;
          transformed = values.stream.throttle(const Duration(milliseconds: 5));
          subscription = transformed.listen(emittedValues.add, onDone: () {
            isDone = true;
          });
        });

        test('cancels values', () async {
          await subscription.cancel();
          expect(valuesCanceled, true);
        });

        test('swallows values that come faster than duration', () async {
          values
            ..add(1)
            ..add(2);
          await values.close();
          await waitForTimer(5);
          expect(emittedValues, [1]);
        });

        test('outputs multiple values spaced further than duration', () async {
          values.add(1);
          await waitForTimer(5);
          values.add(2);
          await waitForTimer(5);
          expect(emittedValues, [1, 2]);
        });

        test('closes output immediately', () async {
          values.add(1);
          await waitForTimer(5);
          values.add(2);
          await values.close();
          expect(isDone, true);
        });

        if (streamType == 'broadcast') {
          test('multiple listeners all get values', () async {
            var otherValues = <int>[];
            transformed.listen(otherValues.add);
            values.add(1);
            await Future(() {});
            expect(emittedValues, [1]);
            expect(otherValues, [1]);
          });
        }
      });

      group('throttle - trailing: true', () {
        setUp(() async {
          valuesCanceled = false;
          values = createController(streamType)
            ..onCancel = () {
              valuesCanceled = true;
            };
          emittedValues = [];
          isDone = false;
          transformed = values.stream
              .throttle(const Duration(milliseconds: 5), trailing: true);
          subscription = transformed.listen(emittedValues.add, onDone: () {
            isDone = true;
          });
        });

        test('emits both first and last in a period', () async {
          values
            ..add(1)
            ..add(2);
          await values.close();
          await waitForTimer(5);
          expect(emittedValues, [1, 2]);
        });

        test('swallows values that are not the latest in a period', () async {
          values
            ..add(1)
            ..add(2)
            ..add(3);
          await values.close();
          await waitForTimer(5);
          expect(emittedValues, [1, 3]);
        });

        test('waits to output the last value even if the stream closes',
            () async {
          values
            ..add(1)
            ..add(2);
          await values.close();
          await Future(() {});
          expect(isDone, false);
          expect(emittedValues, [1],
              reason: 'Should not be emitted until after duration');
          await waitForTimer(5);
          expect(emittedValues, [1, 2]);
          expect(isDone, true);
        });

        test('closes immediately if there is no pending value', () async {
          values.add(1);
          await values.close();
          await Future(() {});
          expect(isDone, true);
        });

        if (streamType == 'broadcast') {
          test('multiple listeners all get values', () async {
            var otherValues = <int>[];
            transformed.listen(otherValues.add);
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            expect(emittedValues, [1]);
            expect(otherValues, [1]);
            await waitForTimer(5);
            expect(emittedValues, [1, 2]);
            expect(otherValues, [1, 2]);
          });
        }
      });
    });
  }
}
