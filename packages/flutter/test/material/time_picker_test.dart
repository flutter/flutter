// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

@TestOn('!chrome') // entire file needs triage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

final Finder _hourControl = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourControl');
final Finder _minuteControl = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_MinuteControl');
final Finder _timePickerDialog = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_TimePickerDialog');

class _TimePickerLauncher extends StatelessWidget {
  const _TimePickerLauncher({
    Key key,
    this.onChanged,
    this.locale,
    this.entryMode = TimePickerEntryMode.dial,
  }) : super(key: key);

  final ValueChanged<TimeOfDay> onChanged;
  final Locale locale;
  final TimePickerEntryMode entryMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      home: Material(
        child: Center(
          child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('X'),
                  onPressed: () async {
                    onChanged(await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                      initialEntryMode: entryMode,
                    ));
                  },
                );
              }
          ),
        ),
      ),
    );
  }
}

Future<Offset> startPicker(
    WidgetTester tester,
    ValueChanged<TimeOfDay> onChanged, {
      TimePickerEntryMode entryMode = TimePickerEntryMode.dial,
    }) async {
  await tester.pumpWidget(_TimePickerLauncher(onChanged: onChanged, locale: const Locale('en', 'US'), entryMode: entryMode));
  await tester.tap(find.text('X'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return entryMode == TimePickerEntryMode.dial ? tester.getCenter(find.byKey(const ValueKey<String>('time-picker-dial'))) : null;
}

Future<void> finishPicker(WidgetTester tester) async {
  final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(tester.element(find.byType(ElevatedButton)));
  await tester.tap(find.text(materialLocalizations.okButtonLabel));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  group('Time picker - Dial', () {
    _tests();
  });

  group('Time picker - Input', () {
    _testsInput();
  });
}

void _tests() {
  testWidgets('tap-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(Offset(center.dx, center.dy - 50.0)); // 12:00 AM
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 0, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(Offset(center.dx + 50.0, center.dy));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 3, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(Offset(center.dx, center.dy + 50.0));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(Offset(center.dx, center.dy + 50.0));
    await tester.tapAt(Offset(center.dx - 50, center.dy));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 9, minute: 0)));
  });

  testWidgets('drag-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour0 = Offset(center.dx, center.dy - 50.0); // 12:00 AM
    final Offset hour3 = Offset(center.dx + 50.0, center.dy);
    final Offset hour6 = Offset(center.dx, center.dy + 50.0);
    final Offset hour9 = Offset(center.dx - 50.0, center.dy);

    TestGesture gesture;

    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour0 - hour3);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, 0);

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour0);
    await gesture.moveBy(hour3 - hour0);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, 3);

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour3);
    await gesture.moveBy(hour6 - hour3);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, equals(6));

    expect(await startPicker(tester, (TimeOfDay time) { result = time; }), equals(center));
    gesture = await tester.startGesture(hour6);
    await gesture.moveBy(hour9 - hour6);
    await gesture.up();
    await finishPicker(tester);
    expect(result.hour, equals(9));
  });

  testWidgets('tap-select switches from hour to minute', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour6 = Offset(center.dx, center.dy + 50.0); // 6:00
    final Offset min45 = Offset(center.dx - 50.0, center.dy); // 45 mins (or 9:00 hours)

    await tester.tapAt(hour6);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(min45);
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
  });

  testWidgets('drag-select switches from hour to minute', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour3 = Offset(center.dx + 50.0, center.dy);
    final Offset hour6 = Offset(center.dx, center.dy + 50.0);
    final Offset hour9 = Offset(center.dx - 50.0, center.dy);

    TestGesture gesture = await tester.startGesture(hour6);
    await gesture.moveBy(hour9 - hour6);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    gesture = await tester.startGesture(hour6);
    await gesture.moveBy(hour3 - hour6);
    await gesture.up();
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 9, minute: 15)));
  });

  testWidgets('tap-select rounds down to nearest 5 minute increment', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour6 = Offset(center.dx, center.dy + 50.0); // 6:00
    final Offset min46 = Offset(center.dx - 50.0, center.dy - 5); // 46 mins

    await tester.tapAt(hour6);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(min46);
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
  });

  testWidgets('tap-select rounds up to nearest 5 minute increment', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour6 = Offset(center.dx, center.dy + 50.0); // 6:00
    final Offset min48 = Offset(center.dx - 50.0, center.dy - 15); // 48 mins

    await tester.tapAt(hour6);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(min48);
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 50)));
  });

  group('haptic feedback', () {
    const Duration kFastFeedbackInterval = Duration(milliseconds: 10);
    const Duration kSlowFeedbackInterval = Duration(milliseconds: 200);
    FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('tap-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('quick successive tap-selects vibrate once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await tester.pump(kFastFeedbackInterval);
      await tester.tapAt(Offset(center.dx, center.dy + 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('slow successive tap-selects vibrate once per tap', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await tester.pump(kSlowFeedbackInterval);
      await tester.tapAt(Offset(center.dx, center.dy + 50.0));
      await tester.pump(kSlowFeedbackInterval);
      await tester.tapAt(Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 3);
    });

    testWidgets('drag-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      final Offset hour0 = Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = Offset(center.dx + 50.0, center.dy);

      final TestGesture gesture = await tester.startGesture(hour3);
      await gesture.moveBy(hour0 - hour3);
      await gesture.up();
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('quick drag-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      final Offset hour0 = Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = Offset(center.dx + 50.0, center.dy);

      final TestGesture gesture = await tester.startGesture(hour3);
      await gesture.moveBy(hour0 - hour3);
      await tester.pump(kFastFeedbackInterval);
      await gesture.moveBy(hour3 - hour0);
      await tester.pump(kFastFeedbackInterval);
      await gesture.moveBy(hour0 - hour3);
      await gesture.up();
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('slow drag-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      final Offset hour0 = Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = Offset(center.dx + 50.0, center.dy);

      final TestGesture gesture = await tester.startGesture(hour3);
      await gesture.moveBy(hour0 - hour3);
      await tester.pump(kSlowFeedbackInterval);
      await gesture.moveBy(hour3 - hour0);
      await tester.pump(kSlowFeedbackInterval);
      await gesture.moveBy(hour0 - hour3);
      await gesture.up();
      await finishPicker(tester);
      expect(feedback.hapticCount, 3);
    });
  });

  const List<String> labels12To11 = <String>['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
  const List<String> labels00To22 = <String>['00', '02', '04', '06', '08', '10', '12', '14', '16', '18', '20', '22'];

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == false', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, false);

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(primaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels12To11);

    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(secondaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels12To11);
  });

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == true', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true);

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
    expect(primaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To22);

    final List<dynamic> secondaryLabels = dialPainter.secondaryLabels as List<dynamic>;
    expect(secondaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To22);
  });

  testWidgets('provides semantics information for AM/PM indicator', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, false);

    expect(semantics, includesNodeWith(label: 'AM', actions: <SemanticsAction>[SemanticsAction.tap]));
    expect(semantics, includesNodeWith(label: 'PM', actions: <SemanticsAction>[SemanticsAction.tap]));

    semantics.dispose();
  });

  testWidgets('provides semantics information for header and footer', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, true);

    expect(semantics, isNot(includesNodeWith(label: ':')));
    expect(semantics.nodesWith(value: '00'), hasLength(1),
        reason: '00 appears once in the header');
    expect(semantics.nodesWith(value: '07'), hasLength(1),
        reason: '07 appears once in the header');
    expect(semantics, includesNodeWith(label: 'CANCEL'));
    expect(semantics, includesNodeWith(label: 'OK'));

    // In 24-hour mode we don't have AM/PM control.
    expect(semantics, isNot(includesNodeWith(label: 'AM')));
    expect(semantics, isNot(includesNodeWith(label: 'PM')));

    semantics.dispose();
  });

  testWidgets('can increment and decrement hours', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    Future<void> actAndExpect({ String initialValue, SemanticsAction action, String finalValue }) async {
      final SemanticsNode elevenHours = semantics.nodesWith(
        value: initialValue,
        ancestor: tester.renderObject(_hourControl).debugSemantics,
      ).single;
      tester.binding.pipelineOwner.semanticsOwner.performAction(elevenHours.id, action);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: _hourControl, matching: find.text(finalValue)),
        findsOneWidget,
      );
    }

    // 12-hour format
    await mediaQueryBoilerplate(tester, false, initialTime: const TimeOfDay(hour: 11, minute: 0));
    await actAndExpect(
      initialValue: '11',
      action: SemanticsAction.increase,
      finalValue: '12',
    );
    await actAndExpect(
      initialValue: '12',
      action: SemanticsAction.increase,
      finalValue: '1',
    );

    // Ensure we preserve day period as we roll over.
    final dynamic pickerState = tester.state(_timePickerDialog);
    expect(pickerState.selectedTime, const TimeOfDay(hour: 1, minute: 0));

    await actAndExpect(
      initialValue: '1',
      action: SemanticsAction.decrease,
      finalValue: '12',
    );
    await tester.pumpWidget(Container()); // clear old boilerplate

    // 24-hour format
    await mediaQueryBoilerplate(tester, true, initialTime: const TimeOfDay(hour: 23, minute: 0));
    await actAndExpect(
      initialValue: '23',
      action: SemanticsAction.increase,
      finalValue: '00',
    );
    await actAndExpect(
      initialValue: '00',
      action: SemanticsAction.increase,
      finalValue: '01',
    );
    await actAndExpect(
      initialValue: '01',
      action: SemanticsAction.decrease,
      finalValue: '00',
    );
    await actAndExpect(
      initialValue: '00',
      action: SemanticsAction.decrease,
      finalValue: '23',
    );

    semantics.dispose();
  });

  testWidgets('can increment and decrement minutes', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    Future<void> actAndExpect({ String initialValue, SemanticsAction action, String finalValue }) async {
      final SemanticsNode elevenHours = semantics.nodesWith(
        value: initialValue,
        ancestor: tester.renderObject(_minuteControl).debugSemantics,
      ).single;
      tester.binding.pipelineOwner.semanticsOwner.performAction(elevenHours.id, action);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: _minuteControl, matching: find.text(finalValue)),
        findsOneWidget,
      );
    }

    await mediaQueryBoilerplate(tester, false, initialTime: const TimeOfDay(hour: 11, minute: 58));
    await actAndExpect(
      initialValue: '58',
      action: SemanticsAction.increase,
      finalValue: '59',
    );
    await actAndExpect(
      initialValue: '59',
      action: SemanticsAction.increase,
      finalValue: '00',
    );

    // Ensure we preserve hour period as we roll over.
    final dynamic pickerState = tester.state(_timePickerDialog);
    expect(pickerState.selectedTime, const TimeOfDay(hour: 11, minute: 0));

    await actAndExpect(
      initialValue: '00',
      action: SemanticsAction.decrease,
      finalValue: '59',
    );
    await actAndExpect(
      initialValue: '59',
      action: SemanticsAction.decrease,
      finalValue: '58',
    );

    semantics.dispose();
  });

  testWidgets('header touch regions are large enough', (WidgetTester tester) async {
    // Ensure picker is displayed in portrait mode.
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1;
    await mediaQueryBoilerplate(tester, false);

    final Size dayPeriodControlSize = tester.getSize(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl'));
    expect(dayPeriodControlSize.width, greaterThanOrEqualTo(48.0));
    // Height should be double the minimum size to account for both AM/PM stacked.
    expect(dayPeriodControlSize.height, greaterThanOrEqualTo(48.0 * 2));

    final Size hourSize = tester.getSize(find.ancestor(
      of: find.text('7'),
      matching: find.byType(InkWell),
    ));
    expect(hourSize.width, greaterThanOrEqualTo(48.0));
    expect(hourSize.height, greaterThanOrEqualTo(48.0));

    final Size minuteSize = tester.getSize(find.ancestor(
      of: find.text('00'),
      matching: find.byType(InkWell),
    ));
    expect(minuteSize.width, greaterThanOrEqualTo(48.0));
    expect(minuteSize.height, greaterThanOrEqualTo(48.0));

    tester.binding.window.physicalSizeTestValue = null;
    tester.binding.window.devicePixelRatioTestValue = null;
  });

  testWidgets('builder parameter', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                      builder: (BuildContext context, Widget child) {
                        return Directionality(
                          textDirection: textDirection,
                          child: child,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    final double ltrOkRight = tester.getBottomRight(find.text('OK')).dx;

    await tester.tap(find.text('OK')); // dismiss the dialog
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildFrame(TextDirection.rtl));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // Verify that the time picker is being laid out RTL.
    // We expect the left edge of the 'OK' button in the RTL
    // layout to match the gap between right edge of the 'OK'
    // button and the right edge of the 800 wide window.
    expect(tester.getBottomLeft(find.text('OK')).dx, 800 - ltrOkRight);
  });

  testWidgets('uses root navigator by default', (WidgetTester tester) async {
    final PickerObserver rootObserver = PickerObserver();
    final PickerObserver nestedObserver = PickerObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.pickerCount, 1);
    expect(nestedObserver.pickerCount, 0);
  });

  testWidgets('uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final PickerObserver rootObserver = PickerObserver();
    final PickerObserver nestedObserver = PickerObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showTimePicker(
                    context: context,
                    useRootNavigator: false,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  );
                },
                child: const Text('Show Picker'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.pickerCount, 0);
    expect(nestedObserver.pickerCount, 1);
  });

  testWidgets('optional text parameters are utilized', (WidgetTester tester) async {
    const String cancelText = 'Custom Cancel';
    const String confirmText = 'Custom OK';
    const String helperText = 'Custom Help';
    await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    child: const Text('X'),
                    onPressed: () async {
                      await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 7, minute: 0),
                        cancelText: cancelText,
                        confirmText: confirmText,
                        helpText: helperText,
                      );
                    },
                  );
                }
            ),
          ),
        )
    ));

    // Open the picker.
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(cancelText), findsOneWidget);
    expect(find.text(confirmText), findsOneWidget);
    expect(find.text(helperText), findsOneWidget);
  });

  testWidgets('OK Cancel button layout', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                      builder: (BuildContext context, Widget child) {
                        return Directionality(
                          textDirection: textDirection,
                          child: child,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('OK')).dx, 638);
    expect(tester.getBottomLeft(find.text('OK')).dx, 610);
    expect(tester.getBottomRight(find.text('CANCEL')).dx, 576);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildFrame(TextDirection.rtl));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('OK')).dx, 162);
    expect(tester.getBottomRight(find.text('OK')).dx, 190);
    expect(tester.getBottomLeft(find.text('CANCEL')).dx, 224);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('text scale affects certain elements and not others', (WidgetTester tester) async {
    await mediaQueryBoilerplate(
      tester,
      false,
      textScaleFactor: 1.0,
      initialTime: const TimeOfDay(hour: 7, minute: 41),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final double minutesDisplayHeight = tester.getSize(find.text('41')).height;
    final double amHeight = tester.getSize(find.text('AM')).height;

    await tester.tap(find.text('OK')); // dismiss the dialog
    await tester.pumpAndSettle();

    // Verify that the time display is not affected by text scale.
    await mediaQueryBoilerplate(
      tester,
      false,
      textScaleFactor: 2.0,
      initialTime: const TimeOfDay(hour: 7, minute: 41),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final double amHeight2x = tester.getSize(find.text('AM')).height;
    expect(tester.getSize(find.text('41')).height, equals(minutesDisplayHeight));
    expect(amHeight2x, greaterThanOrEqualTo(amHeight * 2));

    await tester.tap(find.text('OK')); // dismiss the dialog
    await tester.pumpAndSettle();

    // Verify that text scale for AM/PM is at most 2x.
    await mediaQueryBoilerplate(
      tester,
      false,
      textScaleFactor: 3.0,
      initialTime: const TimeOfDay(hour: 7, minute: 41),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('41')).height, equals(minutesDisplayHeight));
    expect(tester.getSize(find.text('AM')).height, equals(amHeight2x));
  });
}

void _testsInput() {
  testWidgets('Initial entry mode is used', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true, entryMode: TimePickerEntryMode.input);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Initial time is the default', (WidgetTester tester) async {
    TimeOfDay result;
    await startPicker(tester, (TimeOfDay time) { result = time; }, entryMode: TimePickerEntryMode.input);
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 7, minute: 0)));
  });

  testWidgets('Help text is used - Input', (WidgetTester tester) async {
    const String helpText = 'help';
    await mediaQueryBoilerplate(tester, true, entryMode: TimePickerEntryMode.input, helpText: helpText);
    expect(find.text(helpText), findsOneWidget);
  });

  testWidgets('Can toggle to dial entry mode', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true, entryMode: TimePickerEntryMode.input);
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });


  testWidgets('Entered text returns time', (WidgetTester tester) async {
    TimeOfDay result;
    await startPicker(tester, (TimeOfDay time) { result = time; }, entryMode: TimePickerEntryMode.input);
    await tester.enterText(find.byType(TextField).first, '9');
    await tester.enterText(find.byType(TextField).last, '12');
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 9, minute: 12)));
  });

  testWidgets('Toggle to dial mode keeps selected time', (WidgetTester tester) async {
    TimeOfDay result;
    await startPicker(tester, (TimeOfDay time) { result = time; }, entryMode: TimePickerEntryMode.input);
    await tester.enterText(find.byType(TextField).first, '8');
    await tester.enterText(find.byType(TextField).last, '15');
    await tester.tap(find.byIcon(Icons.access_time));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 8, minute: 15)));
  });

  testWidgets('Invalid text prevents dismissing', (WidgetTester tester) async {
    TimeOfDay result;
    await startPicker(tester, (TimeOfDay time) { result = time; }, entryMode: TimePickerEntryMode.input);

    // Invalid hour.
    await tester.enterText(find.byType(TextField).first, '88');
    await tester.enterText(find.byType(TextField).last, '15');
    await finishPicker(tester);
    expect(result, null);

    // Invalid minute.
    await tester.enterText(find.byType(TextField).first, '8');
    await tester.enterText(find.byType(TextField).last, '95');
    await finishPicker(tester);
    expect(result, null);

    await tester.enterText(find.byType(TextField).first, '8');
    await tester.enterText(find.byType(TextField).last, '15');
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 8, minute: 15)));
  });

  // Fixes regression that was reverted in https://github.com/flutter/flutter/pull/64094#pullrequestreview-469836378.
  testWidgets('Ensure hour/minute fields are top-aligned with the separator', (WidgetTester tester) async {
    await startPicker(tester, (TimeOfDay time) { }, entryMode: TimePickerEntryMode.input);
    final double hourFieldTop = tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourTextField')).dy;
    final double minuteFieldTop = tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MinuteTextField')).dy;
    final double separatorTop = tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_StringFragment')).dy;
    expect(hourFieldTop, separatorTop);
    expect(minuteFieldTop, separatorTop);
  });
}

final Finder findDialPaint = find.descendant(
  of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
  matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
);

class PickerObserver extends NavigatorObserver {
  int pickerCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_DialogRoute')) {
      pickerCount++;
    }
    super.didPush(route, previousRoute);
  }
}

Future<void> mediaQueryBoilerplate(
    WidgetTester tester,
    bool alwaysUse24HourFormat, {
      TimeOfDay initialTime = const TimeOfDay(hour: 7, minute: 0),
      double textScaleFactor = 1.0,
      TimePickerEntryMode entryMode = TimePickerEntryMode.dial,
      String helpText,
    }) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData(
          alwaysUse24HourFormat: alwaysUse24HourFormat,
          textScaleFactor: textScaleFactor,
        ),
        child: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<void>(builder: (BuildContext context) {
                  return TextButton(
                    onPressed: () {
                      showTimePicker(
                        context: context,
                        initialTime: initialTime,
                        initialEntryMode: entryMode,
                        helpText: helpText,
                      );
                    },
                    child: const Text('X'),
                  );
                });
              },
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('X'));
  await tester.pumpAndSettle();
}
