// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late StreamController<void> trigger;
  late StreamController<int> values;
  late List<int> emittedValues;
  late bool valuesCanceled;
  late bool triggerCanceled;
  late bool triggerPaused;
  late bool isDone;
  late List<String> errors;
  late Stream<int> transformed;
  late StreamSubscription<int> subscription;

  void setUpForStreamTypes(String triggerType, String valuesType,
      {required bool longPoll}) {
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
    transformed = values.stream.sample(trigger.stream, longPoll: longPoll);
    subscription =
        transformed.listen(emittedValues.add, onError: errors.add, onDone: () {
      isDone = true;
    });
  }

  for (var triggerType in streamTypes) {
    for (var valuesType in streamTypes) {
      group('Trigger type: [$triggerType], Values type: [$valuesType]', () {
        group('general behavior', () {
          setUp(() {
            setUpForStreamTypes(triggerType, valuesType, longPoll: true);
          });

          test('does not emit before `trigger`', () async {
            values.add(1);
            await Future(() {});
            expect(emittedValues, isEmpty);
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, [1]);
          });

          test('keeps most recent event between triggers', () async {
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            trigger.add(null);
            values
              ..add(3)
              ..add(4);
            await Future(() {});
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, [2, 4]);
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
            expect(emittedValues, [1]);
            expect(isDone, true);
          });

          test('closes when source closes and there is no pending', () async {
            expect(isDone, false);
            await values.close();
            await Future(() {});
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

        group('long polling', () {
          setUp(() {
            setUpForStreamTypes(triggerType, valuesType, longPoll: true);
          });

          test('emits immediately if trigger emits before a value', () async {
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, isEmpty);
            values.add(1);
            await Future(() {});
            expect(emittedValues, [1]);
          });

          test('two triggers in a row - emit buffere then emit next value',
              () async {
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            trigger
              ..add(null)
              ..add(null);
            await Future(() {});
            values.add(3);
            await Future(() {});
            expect(emittedValues, [2, 3]);
          });

          test('pre-emptive trigger then trigger after values', () async {
            trigger.add(null);
            await Future(() {});
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, [1, 2]);
          });

          test('multiple pre-emptive triggers, only emits first value',
              () async {
            trigger
              ..add(null)
              ..add(null);
            await Future(() {});
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            expect(emittedValues, [1]);
          });

          test('closes if there is no waiting long poll when source closes',
              () async {
            expect(isDone, false);
            values.add(1);
            trigger.add(null);
            await values.close();
            await Future(() {});
            expect(isDone, true);
          });

          test('waits to emit if there waiting long poll when trigger closes',
              () async {
            trigger.add(null);
            await trigger.close();
            expect(isDone, false);
            values.add(1);
            await Future(() {});
            expect(emittedValues, [1]);
            expect(isDone, true);
          });
        });

        group('immediate polling', () {
          setUp(() {
            setUpForStreamTypes(triggerType, valuesType, longPoll: false);
          });

          test('ignores trigger before values', () async {
            trigger.add(null);
            await Future(() {});
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, [2]);
          });

          test('ignores trigger if no pending values', () async {
            values
              ..add(1)
              ..add(2);
            await Future(() {});
            trigger
              ..add(null)
              ..add(null);
            await Future(() {});
            values
              ..add(3)
              ..add(4);
            await Future(() {});
            trigger.add(null);
            await Future(() {});
            expect(emittedValues, [2, 4]);
          });
        });
      });
    }
  }

  test('always cancels trigger if values is singlesubscription', () async {
    setUpForStreamTypes('broadcast', 'single subscription', longPoll: true);
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);

    setUpForStreamTypes('single subscription', 'single subscription',
        longPoll: true);
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);
  });

  test('cancels trigger if trigger is broadcast', () async {
    setUpForStreamTypes('broadcast', 'broadcast', longPoll: true);
    expect(triggerCanceled, false);
    await subscription.cancel();
    expect(triggerCanceled, true);
  });

  test('pauses single subscription trigger for broadcast values', () async {
    setUpForStreamTypes('single subscription', 'broadcast', longPoll: true);
    expect(triggerCanceled, false);
    expect(triggerPaused, false);
    await subscription.cancel();
    expect(triggerCanceled, false);
    expect(triggerPaused, true);
  });

  for (var triggerType in streamTypes) {
    test('cancel and relisten with [$triggerType] trigger', () async {
      setUpForStreamTypes(triggerType, 'broadcast', longPoll: true);
      values.add(1);
      trigger.add(null);
      await Future(() {});
      expect(emittedValues, [1]);
      await subscription.cancel();
      values.add(2);
      trigger.add(null);
      await Future(() {});
      subscription = transformed.listen(emittedValues.add);
      values.add(3);
      trigger.add(null);
      await Future(() {});
      expect(emittedValues, [1, 3]);
    });
  }
}
