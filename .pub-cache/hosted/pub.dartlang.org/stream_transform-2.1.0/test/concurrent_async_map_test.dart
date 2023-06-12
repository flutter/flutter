// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamController<int> controller;
  late List<String> emittedValues;
  late bool valuesCanceled;
  late bool isDone;
  late List<String> errors;
  late Stream<String> transformed;
  late StreamSubscription<String> subscription;

  late List<Completer<String>> finishWork;
  late List<dynamic> values;

  Future<String> convert(int value) {
    values.add(value);
    var completer = Completer<String>();
    finishWork.add(completer);
    return completer.future;
  }

  for (var streamType in streamTypes) {
    group('concurrentAsyncMap for stream type: [$streamType]', () {
      setUp(() {
        valuesCanceled = false;
        controller = createController(streamType)
          ..onCancel = () {
            valuesCanceled = true;
          };
        emittedValues = [];
        errors = [];
        isDone = false;
        finishWork = [];
        values = [];
        transformed = controller.stream.concurrentAsyncMap(convert);
        subscription = transformed
            .listen(emittedValues.add, onError: errors.add, onDone: () {
          isDone = true;
        });
      });

      test('does not emit before convert finishes', () async {
        controller.add(1);
        await Future(() {});
        expect(emittedValues, isEmpty);
        expect(values, [1]);
        finishWork.first.complete('result');
        await Future(() {});
        expect(emittedValues, ['result']);
      });

      test('allows calls to convert before the last one finished', () async {
        controller
          ..add(1)
          ..add(2)
          ..add(3);
        await Future(() {});
        expect(values, [1, 2, 3]);
      });

      test('forwards errors directly without waiting for previous convert',
          () async {
        controller.add(1);
        await Future(() {});
        controller.addError('error');
        await Future(() {});
        expect(errors, ['error']);
      });

      test('forwards errors which occur during the convert', () async {
        controller.add(1);
        await Future(() {});
        finishWork.first.completeError('error');
        await Future(() {});
        expect(errors, ['error']);
      });

      test('can continue handling events after an error', () async {
        controller.add(1);
        await Future(() {});
        finishWork[0].completeError('error');
        controller.add(2);
        await Future(() {});
        expect(values, [1, 2]);
        finishWork[1].completeError('another');
        await Future(() {});
        expect(errors, ['error', 'another']);
      });

      test('cancels value subscription when output canceled', () async {
        expect(valuesCanceled, false);
        await subscription.cancel();
        expect(valuesCanceled, true);
      });

      test('closes when values end if no conversion is pending', () async {
        expect(isDone, false);
        await controller.close();
        await Future(() {});
        expect(isDone, true);
      });

      if (streamType == 'broadcast') {
        test('multiple listeners all get values', () async {
          var otherValues = [];
          transformed.listen(otherValues.add);
          controller.add(1);
          await Future(() {});
          finishWork.first.complete('result');
          await Future(() {});
          expect(emittedValues, ['result']);
          expect(otherValues, ['result']);
        });

        test('multiple listeners get done when values end', () async {
          var otherDone = false;
          transformed.listen(null, onDone: () => otherDone = true);
          controller.add(1);
          await Future(() {});
          await controller.close();
          expect(isDone, false);
          expect(otherDone, false);
          finishWork.first.complete('');
          await Future(() {});
          expect(isDone, true);
          expect(otherDone, true);
        });

        test('can cancel and relisten', () async {
          controller.add(1);
          await Future(() {});
          finishWork.first.complete('first');
          await Future(() {});
          await subscription.cancel();
          controller.add(2);
          await Future(() {});
          subscription = transformed.listen(emittedValues.add);
          controller.add(3);
          await Future(() {});
          expect(values, [1, 3]);
          finishWork[1].complete('second');
          await Future(() {});
          expect(emittedValues, ['first', 'second']);
        });
      }
    });
  }
}
