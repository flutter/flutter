// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('forwards errors from the convert callback', () async {
    var errors = <String>[];
    var source = Stream.fromIterable([1, 2, 3]);
    source.concurrentAsyncExpand((i) {
      // ignore: only_throw_errors
      throw 'Error: $i';
    }).listen((_) {}, onError: errors.add);
    await Future<void>(() {});
    expect(errors, ['Error: 1', 'Error: 2', 'Error: 3']);
  });

  for (var outerType in streamTypes) {
    for (var innerType in streamTypes) {
      group('concurrentAsyncExpand $outerType to $innerType', () {
        late StreamController<int> outerController;
        late bool outerCanceled;
        late List<StreamController<String>> innerControllers;
        late List<bool> innerCanceled;
        late List<String> emittedValues;
        late bool isDone;
        late List<String> errors;
        late Stream<String> transformed;
        late StreamSubscription<String> subscription;

        setUp(() {
          outerController = createController(outerType)
            ..onCancel = () {
              outerCanceled = true;
            };
          outerCanceled = false;
          innerControllers = [];
          innerCanceled = [];
          emittedValues = [];
          errors = [];
          isDone = false;
          transformed = outerController.stream.concurrentAsyncExpand((i) {
            var index = innerControllers.length;
            innerCanceled.add(false);
            innerControllers.add(createController<String>(innerType)
              ..onCancel = () {
                innerCanceled[index] = true;
              });
            return innerControllers.last.stream;
          });
          subscription = transformed
              .listen(emittedValues.add, onError: errors.add, onDone: () {
            isDone = true;
          });
        });

        test('interleaves events from sub streams', () async {
          outerController
            ..add(1)
            ..add(2);
          await Future<void>(() {});
          expect(emittedValues, isEmpty);
          expect(innerControllers, hasLength(2));
          innerControllers[0].add('First');
          innerControllers[1].add('Second');
          innerControllers[0].add('First again');
          await Future<void>(() {});
          expect(emittedValues, ['First', 'Second', 'First again']);
        });

        test('forwards errors from outer stream', () async {
          outerController.addError('Error');
          await Future<void>(() {});
          expect(errors, ['Error']);
        });

        test('forwards errors from inner streams', () async {
          outerController
            ..add(1)
            ..add(2);
          await Future<void>(() {});
          innerControllers[0].addError('Error 1');
          innerControllers[1].addError('Error 2');
          await Future<void>(() {});
          expect(errors, ['Error 1', 'Error 2']);
        });

        test('can continue handling events after an error in outer stream',
            () async {
          outerController
            ..addError('Error')
            ..add(1);
          await Future<void>(() {});
          innerControllers[0].add('First');
          await Future<void>(() {});
          expect(emittedValues, ['First']);
          expect(errors, ['Error']);
        });

        test('cancels outer subscription if output canceled', () async {
          await subscription.cancel();
          expect(outerCanceled, true);
        });

        if (outerType != 'broadcast' || innerType != 'single subscription') {
          // A single subscription inner stream in a broadcast outer stream is
          // not canceled.
          test('cancels inner subscriptions if output canceled', () async {
            outerController
              ..add(1)
              ..add(2);
            await Future<void>(() {});
            await subscription.cancel();
            expect(innerCanceled, [true, true]);
          });
        }

        test('stays open if any inner stream is still open', () async {
          outerController.add(1);
          await outerController.close();
          await Future<void>(() {});
          expect(isDone, false);
        });

        test('stays open if outer stream is still open', () async {
          outerController.add(1);
          await Future<void>(() {});
          await innerControllers[0].close();
          await Future<void>(() {});
          expect(isDone, false);
        });

        test('closes after all inner streams and outer stream close', () async {
          outerController.add(1);
          await Future<void>(() {});
          await innerControllers[0].close();
          await outerController.close();
          await Future<void>(() {});
          expect(isDone, true);
        });

        if (outerType == 'broadcast') {
          test('multiple listerns all get values', () async {
            var otherValues = <String>[];
            transformed.listen(otherValues.add);
            outerController.add(1);
            await Future<void>(() {});
            innerControllers[0].add('First');
            await Future<void>(() {});
            expect(emittedValues, ['First']);
            expect(otherValues, ['First']);
          });

          test('multiple listeners get closed', () async {
            var otherDone = false;
            transformed.listen(null, onDone: () => otherDone = true);
            outerController.add(1);
            await Future<void>(() {});
            await innerControllers[0].close();
            await outerController.close();
            await Future<void>(() {});
            expect(isDone, true);
            expect(otherDone, true);
          });

          test('can cancel and relisten', () async {
            outerController
              ..add(1)
              ..add(2);
            await Future(() {});
            innerControllers[0].add('First');
            innerControllers[1].add('Second');
            await Future(() {});
            await subscription.cancel();
            innerControllers[0].add('Ignored');
            await Future(() {});
            subscription = transformed.listen(emittedValues.add);
            innerControllers[0].add('Also ignored');
            outerController.add(3);
            await Future(() {});
            innerControllers[2].add('More');
            await Future(() {});
            expect(emittedValues, ['First', 'Second', 'More']);
          });
        }
      });
    }
  }
}
