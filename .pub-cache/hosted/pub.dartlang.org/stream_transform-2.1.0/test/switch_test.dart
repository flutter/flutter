// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  for (var outerType in streamTypes) {
    for (var innerType in streamTypes) {
      group('Outer type: [$outerType], Inner type: [$innerType]', () {
        late StreamController<int> first;
        late StreamController<int> second;
        late StreamController<int> third;
        late StreamController<Stream<int>> outer;

        late List<int> emittedValues;
        late bool firstCanceled;
        late bool outerCanceled;
        late bool isDone;
        late List<String> errors;
        late StreamSubscription<int> subscription;

        setUp(() async {
          firstCanceled = false;
          outerCanceled = false;
          outer = createController(outerType)
            ..onCancel = () {
              outerCanceled = true;
            };
          first = createController(innerType)
            ..onCancel = () {
              firstCanceled = true;
            };
          second = createController(innerType);
          third = createController(innerType);
          emittedValues = [];
          errors = [];
          isDone = false;
          subscription = outer.stream
              .switchLatest()
              .listen(emittedValues.add, onError: errors.add, onDone: () {
            isDone = true;
          });
        });

        test('forwards events', () async {
          outer.add(first.stream);
          await Future(() {});
          first
            ..add(1)
            ..add(2);
          await Future(() {});

          outer.add(second.stream);
          await Future(() {});
          second
            ..add(3)
            ..add(4);
          await Future(() {});

          expect(emittedValues, [1, 2, 3, 4]);
        });

        test('forwards errors from outer Stream', () async {
          outer.addError('error');
          await Future(() {});
          expect(errors, ['error']);
        });

        test('forwards errors from inner Stream', () async {
          outer.add(first.stream);
          await Future(() {});
          first.addError('error');
          await Future(() {});
          expect(errors, ['error']);
        });

        test('closes when final stream is done', () async {
          outer.add(first.stream);
          await Future(() {});

          outer.add(second.stream);
          await Future(() {});

          await outer.close();
          expect(isDone, false);

          await second.close();
          expect(isDone, true);
        });

        test(
            'closes when outer stream closes if latest inner stream already '
            'closed', () async {
          outer.add(first.stream);
          await Future(() {});
          await first.close();
          expect(isDone, false);

          await outer.close();
          expect(isDone, true);
        });

        test('cancels listeners on previous streams', () async {
          outer.add(first.stream);
          await Future(() {});

          outer.add(second.stream);
          await Future(() {});
          expect(firstCanceled, true);
        });

        if (innerType != 'broadcast') {
          test('waits for cancel before listening to subsequent stream',
              () async {
            var cancelWork = Completer<void>();
            first.onCancel = () => cancelWork.future;
            outer.add(first.stream);
            await Future(() {});

            var cancelDone = false;
            second.onListen = expectAsync0(() {
              expect(cancelDone, true);
            });
            outer.add(second.stream);
            await Future(() {});
            cancelWork.complete();
            cancelDone = true;
          });

          test('all streams are listened to, even while cancelling', () async {
            var cancelWork = Completer<void>();
            first.onCancel = () => cancelWork.future;
            outer.add(first.stream);
            await Future(() {});

            var cancelDone = false;
            second.onListen = expectAsync0(() {
              expect(cancelDone, true);
            });
            third.onListen = expectAsync0(() {
              expect(cancelDone, true);
            });
            outer
              ..add(second.stream)
              ..add(third.stream);
            await Future(() {});
            cancelWork.complete();
            cancelDone = true;
          });
        }

        if (outerType != 'broadcast' && innerType != 'broadcast') {
          test('pausing while cancelling an inner stream is respected',
              () async {
            var cancelWork = Completer<void>();
            first.onCancel = () => cancelWork.future;
            outer.add(first.stream);
            await Future(() {});

            var cancelDone = false;
            second.onListen = expectAsync0(() {
              expect(cancelDone, true);
            });
            outer.add(second.stream);
            await Future(() {});
            subscription.pause();
            cancelWork.complete();
            cancelDone = true;
            await Future(() {});
            expect(second.isPaused, true);
            subscription.resume();
          });
        }

        test('cancels listener on current and outer stream on cancel',
            () async {
          outer.add(first.stream);
          await Future(() {});
          await subscription.cancel();

          await Future(() {});
          expect(outerCanceled, true);
          expect(firstCanceled, true);
        });
      });
    }
  }

  group('switchMap', () {
    test('uses map function', () async {
      var outer = StreamController<List<int>>();

      var values = [];
      outer.stream.switchMap((l) => Stream.fromIterable(l)).listen(values.add);

      outer.add([1, 2, 3]);
      await Future(() {});
      outer.add([4, 5, 6]);
      await Future(() {});
      expect(values, [1, 2, 3, 4, 5, 6]);
    });

    test('can create a broadcast stream', () async {
      var outer = StreamController.broadcast();

      var transformed = outer.stream.switchMap((_) => const Stream.empty());

      expect(transformed.isBroadcast, true);
    });

    test('forwards errors from the convert callback', () async {
      var errors = <String>[];
      var source = Stream.fromIterable([1, 2, 3]);
      source.switchMap((i) {
        // ignore: only_throw_errors
        throw 'Error: $i';
      }).listen((_) {}, onError: errors.add);
      await Future<void>(() {});
      expect(errors, ['Error: 1', 'Error: 2', 'Error: 3']);
    });
  });
}
