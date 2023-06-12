// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:test/test.dart';

import 'package:stream_transform/stream_transform.dart';

import 'utils.dart';

void main() {
  late StreamController<void> trigger;
  late StreamController<int> values;
  late List<List<int>> emittedValues;
  late bool valuesCanceled;
  late bool triggerCanceled;
  late bool triggerPaused;
  late bool isDone;
  late List<String> errors;
  late Stream<List<int>> transformed;
  late StreamSubscription<List<int>> subscription;

  void setUpForStreamTypes(String triggerType, String valuesType) {
    valuesCanceled = false;
    triggerCanceled = false;
    triggerPaused = false;
    trigger = createController(triggerType)
      ..onCancel = () {
        triggerCanceled = true;
      };
    if (triggerType == 'single subscription') {
      trigger.onPause = () {
        triggerPaused = true;
      };
    }
    values = createController(valuesType)
      ..onCancel = () {
        valuesCanceled = true;
      };
    emittedValues = [];
    errors = [];
    isDone = false;
    transformed = values.stream.buffer(trigger.stream);
    subscription =
        transformed.listen(emittedValues.add, onError: errors.add, onDone: () {
      isDone = true;
    });
  }

  for (var triggerType in streamTypes) {
    for (var valuesType in streamTypes) {
      group('Trigger type: [$triggerType], Values type: [$valuesType]', () {
        setUp(() {
          setUpForStreamTypes(triggerType, valuesType);
        });

        test('does not emit before `trigger`', () async {
          values.add(1);
          await Future(() {});
          expect(emittedValues, isEmpty);
          trigger.add(null);
          await Future(() {});
          expect(emittedValues, [
            [1]
          ]);
        });

        test('emits immediately if trigger emits before a value', () async {
          trigger.add(null);
          await Future(() {});
          expect(emittedValues, isEmpty);
          values.add(1);
          await Future(() {});
          expect(emittedValues, [
            [1]
          ]);
        });

        test('two triggers in a row - emit then emit next value', () async {
          values..add(1)..add(2);
          await Future(() {});
          trigger..add(null)..add(null);
          await Future(() {});
          values.add(3);
          await Future(() {});
          expect(emittedValues, [
            [1, 2],
            [3]
          ]);
        });

        test('pre-emptive trigger then trigger after values', () async {
          trigger.add(null);
          await Future(() {});
          values..add(1)..add(2);
          await Future(() {});
          trigger.add(null);
          await Future(() {});
          expect(emittedValues, [
            [1],
            [2]
          ]);
        });

        test('multiple pre-emptive triggers, only emits first value', () async {
          trigger..add(null)..add(null);
          await Future(() {});
          values..add(1)..add(2);
          await Future(() {});
          expect(emittedValues, [
            [1]
          ]);
        });

        test('groups values between trigger', () async {
          values..add(1)..add(2);
          await Future(() {});
          trigger.add(null);
          values..add(3)..add(4);
          await Future(() {});
          trigger.add(null);
          await Future(() {});
          expect(emittedValues, [
            [1, 2],
            [3, 4]
          ]);
        });

        test('cancels value subscription when output canceled', () async {
          expect(valuesCanceled, false);
          await subscription.cancel();
          expect(valuesCanceled, true);
        });

        test('closes when trigger ends', () async {
          expect(isDone, false);
          await trigger.close();
          await Future(() {});
          expect(isDone, true);
        });

        test('closes after outputting final values when source closes',
            () async {
          expect(isDone, false);
          values.add(1);
          await values.close();
          expect(isDone, false);
          trigger.add(null);
          await Future(() {});
          expect(emittedValues, [
            [1]
          ]);
          expect(isDone, true);
        });

        test('closes if there are no pending values when source closes',
            () async {
          expect(isDone, false);
          values.add(1);
          trigger.add(null);
          await values.close();
          await Future(() {});
          expect(isDone, true);
        });

        test('waits to emit if there is a pending trigger when trigger closes',
            () async {
          trigger.add(null);
          await trigger.close();
          expect(isDone, false);
          values.add(1);
          await Future(() {});
          expect(emittedValues, [
            [1]
          ]);
          expect(isDone, true);
        });

        test('forwards errors from trigger', () async {
          trigger.addError('error');
          await Future(() {});
          expect(errors, ['error']);
        });

        test('forwards errors from values', () async {
          values.addError('error');
          await Future(() {});
          expect(errors, ['error']);
        });
      });
    }
  }

  test('always cancels trigger if values is singlesubscription', () async {
    setUpForStreamTypes('broadcast', 'single subscription');
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);

    setUpForStreamTypes('single subscription', 'single subscription');
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);
  });

  test('cancels trigger if trigger is broadcast', () async {
    setUpForStreamTypes('broadcast', 'broadcast');
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);
  });

  test('pauses single subscription trigger for broadcast values', () async {
    setUpForStreamTypes('single subscription', 'broadcast');
    expect(triggerCanceled, false);
    expect(triggerPaused, false);
    await subscription.cancel();
    expect(triggerCanceled, false);
    expect(triggerPaused, true);
  });

  for (var triggerType in streamTypes) {
    test('cancel and relisten with [$triggerType] trigger', () async {
      setUpForStreamTypes(triggerType, 'broadcast');
      values.add(1);
      trigger.add(null);
      await Future(() {});
      expect(emittedValues, [
        [1]
      ]);
      await subscription.cancel();
      values.add(2);
      trigger.add(null);
      await Future(() {});
      subscription = transformed.listen(emittedValues.add);
      values.add(3);
      trigger.add(null);
      await Future(() {});
      expect(emittedValues, [
        [1],
        [3]
      ]);
    });
  }
}
