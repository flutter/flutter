// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  for (var firstType in streamTypes) {
    for (var secondType in streamTypes) {
      group('followedBy [$firstType] with [$secondType]', () {
        late StreamController<int> first;
        late StreamController<int> second;

        late List<int> emittedValues;
        late bool firstCanceled;
        late bool secondCanceled;
        late bool secondListened;
        late bool isDone;
        late List<String> errors;
        late Stream<int> transformed;
        late StreamSubscription<int> subscription;

        setUp(() async {
          firstCanceled = false;
          secondCanceled = false;
          secondListened = false;
          first = createController(firstType)
            ..onCancel = () {
              firstCanceled = true;
            };
          second = createController(secondType)
            ..onCancel = () {
              secondCanceled = true;
            }
            ..onListen = () {
              secondListened = true;
            };
          emittedValues = [];
          errors = [];
          isDone = false;
          transformed = first.stream.followedBy(second.stream);
          subscription = transformed
              .listen(emittedValues.add, onError: errors.add, onDone: () {
            isDone = true;
          });
        });

        test('adds all values from both streams', () async {
          first
            ..add(1)
            ..add(2);
          await first.close();
          await Future(() {});
          second
            ..add(3)
            ..add(4);
          await Future(() {});
          expect(emittedValues, [1, 2, 3, 4]);
        });

        test('Does not listen to second stream before first stream finishes',
            () async {
          expect(secondListened, false);
          await first.close();
          expect(secondListened, true);
        });

        test('closes stream after both inputs close', () async {
          await first.close();
          await second.close();
          expect(isDone, true);
        });

        test('cancels any type of first stream on cancel', () async {
          await subscription.cancel();
          expect(firstCanceled, true);
        });

        if (firstType == 'single subscription') {
          test(
              'cancels any type of second stream on cancel if first is '
              'broadcast', () async {
            await first.close();
            await subscription.cancel();
            expect(secondCanceled, true);
          });

          if (secondType == 'broadcast') {
            test('can pause and resume during second stream - dropping values',
                () async {
              await first.close();
              subscription.pause();
              second.add(1);
              await Future(() {});
              subscription.resume();
              second.add(2);
              await Future(() {});
              expect(emittedValues, [2]);
            });
          } else {
            test('can pause and resume during second stream - buffering values',
                () async {
              await first.close();
              subscription.pause();
              second.add(1);
              await Future(() {});
              subscription.resume();
              second.add(2);
              await Future(() {});
              expect(emittedValues, [1, 2]);
            });
          }
        }

        if (firstType == 'broadcast') {
          test('can cancel and relisten during first stream', () async {
            await subscription.cancel();
            first.add(1);
            subscription = transformed.listen(emittedValues.add);
            first.add(2);
            await Future(() {});
            expect(emittedValues, [2]);
          });

          test('can cancel and relisten during second stream', () async {
            await first.close();
            await subscription.cancel();
            second.add(2);
            await Future(() {});
            subscription = transformed.listen(emittedValues.add);
            second.add(3);
            await Future(() {});
            expect(emittedValues, [3]);
          });

          test('forwards values to multiple listeners', () async {
            var otherValues = [];
            transformed.listen(otherValues.add);
            first.add(1);
            await first.close();
            second.add(2);
            await Future(() {});
            var thirdValues = [];
            transformed.listen(thirdValues.add);
            second.add(3);
            await Future(() {});
            expect(emittedValues, [1, 2, 3]);
            expect(otherValues, [1, 2, 3]);
            expect(thirdValues, [3]);
          });
        }
      });
    }
  }
}
