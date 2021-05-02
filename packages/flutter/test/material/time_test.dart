// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeOfDay.format', () {
    testWidgets('respects alwaysUse24HourFormat option', (WidgetTester tester) async {
      Future<String> pumpTest(bool alwaysUse24HourFormat) async {
        late String formattedValue;
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: alwaysUse24HourFormat),
            child: Builder(builder: (BuildContext context) {
              formattedValue = const TimeOfDay(hour: 7, minute: 0).format(context);
              return Container();
            }),
          ),
        ));
        return formattedValue;
      }

      expect(await pumpTest(false), '7:00 AM');
      expect(await pumpTest(true), '07:00');
    });
  });

  group('RestorableTimeOfDay tests', () {
    testWidgets('value is not accessible when not registered', (WidgetTester tester) async {
      expect(() => RestorableTimeOfDay(const TimeOfDay(hour: 20, minute: 4)).value, throwsAssertionError);
    });

    testWidgets('work when not in restoration scope', (WidgetTester tester) async {
      await tester.pumpWidget(const _RestorableWidget());

      final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

      // Initialized to default values.
      expect(state.timeOfDay.value, const TimeOfDay(hour: 10, minute: 5));

      // Modify values.
      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 2, minute: 2);
      });
      await tester.pump();

      expect(state.timeOfDay.value, const TimeOfDay(hour: 2, minute: 2));
    });

    testWidgets('restart and restore', (WidgetTester tester) async {
      await tester.pumpWidget(const RootRestorationScope(
        restorationId: 'root-child',
        child: _RestorableWidget(),
      ));

      _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

      // Initialized to default values.
      expect(state.timeOfDay.value, const TimeOfDay(hour: 10, minute: 5));

      // Modify values.
      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 2, minute: 2);
      });
      await tester.pump();

      expect(state.timeOfDay.value, const TimeOfDay(hour: 2, minute: 2));

      // Restores to previous values.
      await tester.restartAndRestore();
      final _RestorableWidgetState oldState = state;
      state = tester.state(find.byType(_RestorableWidget));
      expect(state, isNot(same(oldState)));

      expect(state.timeOfDay.value, const TimeOfDay(hour: 2, minute: 2));
    });

    testWidgets('restore to older state', (WidgetTester tester) async {
      await tester.pumpWidget(const RootRestorationScope(
        restorationId: 'root-child',
        child: _RestorableWidget(),
      ));

      final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

      // Modify values.
      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 2, minute: 2);
      });
      await tester.pump();

      final TestRestorationData restorationData = await tester.getRestorationData();

      // Modify values.
      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 4, minute: 4);
      });
      await tester.pump();

      // Restore to previous.
      await tester.restoreFrom(restorationData);
      expect(state.timeOfDay.value, const TimeOfDay(hour: 2, minute: 2));

      // Restore to empty data will re-initialize to default values.
      await tester.restoreFrom(TestRestorationData.empty);
      expect(state.timeOfDay.value, const TimeOfDay(hour: 10, minute: 5));
    });

    testWidgets('call notifiers when value changes', (WidgetTester tester) async {
      await tester.pumpWidget(const RootRestorationScope(
        restorationId: 'root-child',
        child: _RestorableWidget(),
      ));

      final _RestorableWidgetState state = tester.state(find.byType(_RestorableWidget));

      final List<String> notifyLog = <String>[];

      state.timeOfDay.addListener(() {
        notifyLog.add('hello world');
      });

      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 2, minute: 2);
      });
      expect(notifyLog.single, 'hello world');
      notifyLog.clear();
      await tester.pump();

      // Does not notify when set to same value.
      state.setProperties(() {
        state.timeOfDay.value = const TimeOfDay(hour: 2, minute: 2);
      });

      expect(notifyLog, isEmpty);
    });
  });
}

class _RestorableWidget extends StatefulWidget {
  const _RestorableWidget({Key? key}) : super(key: key);

  @override
  State<_RestorableWidget> createState() => _RestorableWidgetState();
}

class _RestorableWidgetState extends State<_RestorableWidget> with RestorationMixin {
  final RestorableTimeOfDay timeOfDay = RestorableTimeOfDay(const TimeOfDay(hour: 10, minute: 5));

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(timeOfDay, 'time_of_day');
  }

  void setProperties(VoidCallback callback) {
    setState(callback);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }

  @override
  String get restorationId => 'widget';
}
