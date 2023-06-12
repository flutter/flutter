// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamController<int> values;
  late Stream<int> transformed;
  late StreamSubscription<int> subscription;

  late List<int> emittedValues;
  late bool isDone;

  void setupForStreamType(
      String streamType, Stream<int> Function(Stream<int>) transform) {
    emittedValues = [];
    isDone = false;
    values = createController(streamType);
    transformed = transform(values.stream);
    subscription =
        transformed.listen(emittedValues.add, onDone: () => isDone = true);
  }

  for (var streamType in streamTypes) {
    group('startWith then [$streamType]', () {
      setUp(() => setupForStreamType(streamType, (s) => s.startWith(1)));

      test('outputs all values', () async {
        values
          ..add(2)
          ..add(3);
        await Future(() {});
        expect(emittedValues, [1, 2, 3]);
      });

      test('outputs initial when followed by empty stream', () async {
        await values.close();
        expect(emittedValues, [1]);
      });

      test('closes with values', () async {
        expect(isDone, false);
        await values.close();
        expect(isDone, true);
      });

      if (streamType == 'broadcast') {
        test('can cancel and relisten', () async {
          values.add(2);
          await Future(() {});
          await subscription.cancel();
          subscription = transformed.listen(emittedValues.add);
          values.add(3);
          await Future(() {});
          await Future(() {});
          expect(emittedValues, [1, 2, 3]);
        });
      }
    });

    group('startWithMany then [$streamType]', () {
      setUp(() async {
        setupForStreamType(streamType, (s) => s.startWithMany([1, 2]));
        // Ensure all initial values go through
        await Future(() {});
      });

      test('outputs all values', () async {
        values
          ..add(3)
          ..add(4);
        await Future(() {});
        expect(emittedValues, [1, 2, 3, 4]);
      });

      test('outputs initial when followed by empty stream', () async {
        await values.close();
        expect(emittedValues, [1, 2]);
      });

      test('closes with values', () async {
        expect(isDone, false);
        await values.close();
        expect(isDone, true);
      });

      if (streamType == 'broadcast') {
        test('can cancel and relisten', () async {
          values.add(3);
          await Future(() {});
          await subscription.cancel();
          subscription = transformed.listen(emittedValues.add);
          values.add(4);
          await Future(() {});
          expect(emittedValues, [1, 2, 3, 4]);
        });
      }
    });

    for (var startingStreamType in streamTypes) {
      group('startWithStream [$startingStreamType] then [$streamType]', () {
        late StreamController<int> starting;
        setUp(() async {
          starting = createController(startingStreamType);
          setupForStreamType(
              streamType, (s) => s.startWithStream(starting.stream));
        });

        test('outputs all values', () async {
          starting
            ..add(1)
            ..add(2);
          await starting.close();
          values
            ..add(3)
            ..add(4);
          await Future(() {});
          expect(emittedValues, [1, 2, 3, 4]);
        });

        test('closes with values', () async {
          expect(isDone, false);
          await starting.close();
          expect(isDone, false);
          await values.close();
          expect(isDone, true);
        });

        if (streamType == 'broadcast') {
          test('can cancel and relisten during starting', () async {
            starting.add(1);
            await Future(() {});
            await subscription.cancel();
            subscription = transformed.listen(emittedValues.add);
            starting.add(2);
            await starting.close();
            values
              ..add(3)
              ..add(4);
            await Future(() {});
            expect(emittedValues, [1, 2, 3, 4]);
          });

          test('can cancel and relisten during values', () async {
            starting
              ..add(1)
              ..add(2);
            await starting.close();
            values.add(3);
            await Future(() {});
            await subscription.cancel();
            subscription = transformed.listen(emittedValues.add);
            values.add(4);
            await Future(() {});
            expect(emittedValues, [1, 2, 3, 4]);
          });
        }
      });
    }
  }
}
