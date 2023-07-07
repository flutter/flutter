// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  for (var streamType in streamTypes) {
    group('takeUntil on Stream type [$streamType]', () {
      late StreamController<int> values;
      late List<int> emittedValues;
      late bool valuesCanceled;
      late bool isDone;
      late List<String> errors;
      late Stream<int> transformed;
      late StreamSubscription<int> subscription;
      late Completer<void> closeTrigger;

      setUp(() {
        valuesCanceled = false;
        values = createController(streamType)
          ..onCancel = () {
            valuesCanceled = true;
          };
        emittedValues = [];
        errors = [];
        isDone = false;
        closeTrigger = Completer();
        transformed = values.stream.takeUntil(closeTrigger.future);
        subscription = transformed
            .listen(emittedValues.add, onError: errors.add, onDone: () {
          isDone = true;
        });
      });

      test('forwards cancellation', () async {
        await subscription.cancel();
        expect(valuesCanceled, true);
      });

      test('lets values through before trigger', () async {
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

      test('sends done if original strem ends', () async {
        await values.close();
        expect(isDone, true);
      });

      test('sends done when trigger fires', () async {
        closeTrigger.complete();
        await Future(() {});
        expect(isDone, true);
      });

      test('cancels value subscription when trigger fires', () async {
        closeTrigger.complete();
        await Future(() {});
        expect(valuesCanceled, true);
      });

      if (streamType == 'broadcast') {
        test('multiple listeners all get values', () async {
          var otherValues = [];
          transformed.listen(otherValues.add);
          values
            ..add(1)
            ..add(2);
          await Future(() {});
          expect(emittedValues, [1, 2]);
          expect(otherValues, [1, 2]);
        });

        test('multiple listeners get done when trigger fires', () async {
          var otherDone = false;
          transformed.listen(null, onDone: () => otherDone = true);
          closeTrigger.complete();
          await Future(() {});
          expect(otherDone, true);
          expect(isDone, true);
        });

        test('multiple listeners get done when values end', () async {
          var otherDone = false;
          transformed.listen(null, onDone: () => otherDone = true);
          await values.close();
          expect(otherDone, true);
          expect(isDone, true);
        });

        test('can cancel and relisten before trigger fires', () async {
          values.add(1);
          await Future(() {});
          await subscription.cancel();
          values.add(2);
          await Future(() {});
          subscription = transformed.listen(emittedValues.add);
          values.add(3);
          await Future(() {});
          expect(emittedValues, [1, 3]);
        });
      }
    });
  }
}
