// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  group('merge', () {
    test('includes all values', () async {
      var first = Stream.fromIterable([1, 2, 3]);
      var second = Stream.fromIterable([4, 5, 6]);
      var allValues = await first.merge(second).toList();
      expect(allValues, containsAllInOrder([1, 2, 3]));
      expect(allValues, containsAllInOrder([4, 5, 6]));
      expect(allValues, hasLength(6));
    });

    test('cancels both sources', () async {
      var firstCanceled = false;
      var first = StreamController()
        ..onCancel = () {
          firstCanceled = true;
        };
      var secondCanceled = false;
      var second = StreamController()
        ..onCancel = () {
          secondCanceled = true;
        };
      var subscription = first.stream.merge(second.stream).listen((_) {});
      await subscription.cancel();
      expect(firstCanceled, true);
      expect(secondCanceled, true);
    });

    test('completes when both sources complete', () async {
      var first = StreamController();
      var second = StreamController();
      var isDone = false;
      first.stream.merge(second.stream).listen((_) {}, onDone: () {
        isDone = true;
      });
      await first.close();
      expect(isDone, false);
      await second.close();
      expect(isDone, true);
    });

    test('can cancel and relisten to broadcast stream', () async {
      var first = StreamController.broadcast();
      var second = StreamController();
      var emittedValues = [];
      var transformed = first.stream.merge(second.stream);
      var subscription = transformed.listen(emittedValues.add);
      first.add(1);
      second.add(2);
      await Future(() {});
      expect(emittedValues, contains(1));
      expect(emittedValues, contains(2));
      await subscription.cancel();
      emittedValues = [];
      subscription = transformed.listen(emittedValues.add);
      first.add(3);
      second.add(4);
      await Future(() {});
      expect(emittedValues, contains(3));
      expect(emittedValues, contains(4));
    });
  });

  group('mergeAll', () {
    test('includes all values', () async {
      var first = Stream.fromIterable([1, 2, 3]);
      var second = Stream.fromIterable([4, 5, 6]);
      var third = Stream.fromIterable([7, 8, 9]);
      var allValues = await first.mergeAll([second, third]).toList();
      expect(allValues, containsAllInOrder([1, 2, 3]));
      expect(allValues, containsAllInOrder([4, 5, 6]));
      expect(allValues, containsAllInOrder([7, 8, 9]));
      expect(allValues, hasLength(9));
    });

    test('handles mix of broadcast and single-subscription', () async {
      var firstCanceled = false;
      var first = StreamController.broadcast()
        ..onCancel = () {
          firstCanceled = true;
        };
      var secondBroadcastCanceled = false;
      var secondBroadcast = StreamController.broadcast()
        ..onCancel = () {
          secondBroadcastCanceled = true;
        };
      var secondSingleCanceled = false;
      var secondSingle = StreamController()
        ..onCancel = () {
          secondSingleCanceled = true;
        };

      var merged =
          first.stream.mergeAll([secondBroadcast.stream, secondSingle.stream]);

      var firstListenerValues = [];
      var secondListenerValues = [];

      var firstSubscription = merged.listen(firstListenerValues.add);
      var secondSubscription = merged.listen(secondListenerValues.add);

      first.add(1);
      secondBroadcast.add(2);
      secondSingle.add(3);

      await Future(() {});
      await firstSubscription.cancel();

      expect(firstCanceled, false);
      expect(secondBroadcastCanceled, false);
      expect(secondSingleCanceled, false);

      first.add(4);
      secondBroadcast.add(5);
      secondSingle.add(6);

      await Future(() {});
      await secondSubscription.cancel();

      await Future(() {});
      expect(firstCanceled, true);
      expect(secondBroadcastCanceled, true);
      expect(secondSingleCanceled, false,
          reason: 'Single subscription streams merged into broadcast streams '
              'are not canceled');

      expect(firstListenerValues, [1, 2, 3]);
      expect(secondListenerValues, [1, 2, 3, 4, 5, 6]);
    });
  });
}
