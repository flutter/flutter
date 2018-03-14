// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

final Finder _hourControl = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourControl');
final Finder _minuteControl = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_MinuteControl');
final Finder _timePickerDialog = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_TimePickerDialog');

class _TimePickerLauncher extends StatelessWidget {
  const _TimePickerLauncher({ Key key, this.onChanged, this.locale }) : super(key: key);

  final ValueChanged<TimeOfDay> onChanged;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      locale: locale,
      home: new Material(
        child: new Center(
          child: new Builder(
            builder: (BuildContext context) {
              return new RaisedButton(
                child: const Text('X'),
                onPressed: () async {
                  onChanged(await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  ));
                }
              );
            }
          )
        )
      )
    );
  }
}

Future<Offset> startPicker(WidgetTester tester, ValueChanged<TimeOfDay> onChanged) async {
  await tester.pumpWidget(new _TimePickerLauncher(onChanged: onChanged, locale: const Locale('en', 'US')));
  await tester.tap(find.text('X'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return tester.getCenter(find.byKey(const ValueKey<String>('time-picker-dial')));
}

Future<Null> finishPicker(WidgetTester tester) async {
  final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(tester.element(find.byType(RaisedButton)));
  await tester.tap(find.text(materialLocalizations.okButtonLabel));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  group('Time picker', () {
    _tests();
  });
}

void _tests() {
  testWidgets('tap-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Offset(center.dx, center.dy - 50.0)); // 12:00 AM
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 0, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Offset(center.dx + 50.0, center.dy));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 3, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Offset(center.dx, center.dy + 50.0));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 6, minute: 0)));

    center = await startPicker(tester, (TimeOfDay time) { result = time; });
    await tester.tapAt(new Offset(center.dx, center.dy + 50.0));
    await tester.tapAt(new Offset(center.dx - 50, center.dy));
    await finishPicker(tester);
    expect(result, equals(const TimeOfDay(hour: 9, minute: 0)));
  });

  testWidgets('drag-select an hour', (WidgetTester tester) async {
    TimeOfDay result;

    final Offset center = await startPicker(tester, (TimeOfDay time) { result = time; });
    final Offset hour0 = new Offset(center.dx, center.dy - 50.0); // 12:00 AM
    final Offset hour3 = new Offset(center.dx + 50.0, center.dy);
    final Offset hour6 = new Offset(center.dx, center.dy + 50.0);
    final Offset hour9 = new Offset(center.dx - 50.0, center.dy);

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

  group('haptic feedback', () {
    const Duration kFastFeedbackInterval = const Duration(milliseconds: 10);
    const Duration kSlowFeedbackInterval = const Duration(milliseconds: 200);
    FeedbackTester feedback;

    setUp(() {
      feedback = new FeedbackTester();
    });

    tearDown(() {
      feedback?.dispose();
    });

    testWidgets('tap-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(new Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('quick successive tap-selects vibrate once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(new Offset(center.dx, center.dy - 50.0));
      await tester.pump(kFastFeedbackInterval);
      await tester.tapAt(new Offset(center.dx, center.dy + 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('slow successive tap-selects vibrate once per tap', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      await tester.tapAt(new Offset(center.dx, center.dy - 50.0));
      await tester.pump(kSlowFeedbackInterval);
      await tester.tapAt(new Offset(center.dx, center.dy + 50.0));
      await tester.pump(kSlowFeedbackInterval);
      await tester.tapAt(new Offset(center.dx, center.dy - 50.0));
      await finishPicker(tester);
      expect(feedback.hapticCount, 3);
    });

    testWidgets('drag-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      final Offset hour0 = new Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = new Offset(center.dx + 50.0, center.dy);

      final TestGesture gesture = await tester.startGesture(hour3);
      await gesture.moveBy(hour0 - hour3);
      await gesture.up();
      await finishPicker(tester);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('quick drag-select vibrates once', (WidgetTester tester) async {
      final Offset center = await startPicker(tester, (TimeOfDay time) { });
      final Offset hour0 = new Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = new Offset(center.dx + 50.0, center.dy);

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
      final Offset hour0 = new Offset(center.dx, center.dy - 50.0);
      final Offset hour3 = new Offset(center.dx + 50.0, center.dy);

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

  const List<String> labels12To11 = const <String>['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
  const List<String> labels12To11TwoDigit = const <String>['12', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'];
  const List<String> labels00To23 = const <String>['00', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'];

  Future<Null> mediaQueryBoilerplate(WidgetTester tester, bool alwaysUse24HourFormat,
      { TimeOfDay initialTime: const TimeOfDay(hour: 7, minute: 0) }) async {
    await tester.pumpWidget(
      new Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: new MediaQuery(
          data: new MediaQueryData(alwaysUse24HourFormat: alwaysUse24HourFormat),
          child: new Material(
            child: new Directionality(
              textDirection: TextDirection.ltr,
              child: new Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  return new MaterialPageRoute<dynamic>(builder: (BuildContext context) {
                    return new FlatButton(
                      onPressed: () {
                        showTimePicker(context: context, initialTime: initialTime);
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

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == false', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, false);

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryOuterLabels = dialPainter.primaryOuterLabels;
    expect(primaryOuterLabels.map<String>((dynamic tp) => tp.painter.text.text), labels12To11);
    expect(dialPainter.primaryInnerLabels, null);

    final List<dynamic> secondaryOuterLabels = dialPainter.secondaryOuterLabels;
    expect(secondaryOuterLabels.map<String>((dynamic tp) => tp.painter.text.text), labels12To11);
    expect(dialPainter.secondaryInnerLabels, null);
  });

  testWidgets('respects MediaQueryData.alwaysUse24HourFormat == true', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true);

    final CustomPaint dialPaint = tester.widget(findDialPaint);
    final dynamic dialPainter = dialPaint.painter;
    final List<dynamic> primaryOuterLabels = dialPainter.primaryOuterLabels;
    expect(primaryOuterLabels.map<String>((dynamic tp) => tp.painter.text.text), labels00To23);
    final List<dynamic> primaryInnerLabels = dialPainter.primaryInnerLabels;
    expect(primaryInnerLabels.map<String>((dynamic tp) => tp.painter.text.text), labels12To11TwoDigit);

    final List<dynamic> secondaryOuterLabels = dialPainter.secondaryOuterLabels;
    expect(secondaryOuterLabels.map<String>((dynamic tp) => tp.painter.text.text), labels00To23);
    final List<dynamic> secondaryInnerLabels = dialPainter.secondaryInnerLabels;
    expect(secondaryInnerLabels.map<String>((dynamic tp) => tp.painter.text.text), labels12To11TwoDigit);
  });

  testWidgets('provides semantics information for AM/PM indicator', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, false);

    expect(semantics, includesNodeWith(label: 'AM', actions: <SemanticsAction>[SemanticsAction.tap]));
    expect(semantics, includesNodeWith(label: 'PM', actions: <SemanticsAction>[SemanticsAction.tap]));

    semantics.dispose();
  });

  testWidgets('provides semantics information for header and footer', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, true);

    expect(semantics, isNot(includesNodeWith(label: ':')));
    expect(semantics.nodesWith(value: '00'), hasLength(2),
        reason: '00 appears once in the header, then again in the dial');
    expect(semantics.nodesWith(value: '07'), hasLength(2),
        reason: '07 appears once in the header, then again in the dial');
    expect(semantics, includesNodeWith(label: 'CANCEL'));
    expect(semantics, includesNodeWith(label: 'OK'));

    // In 24-hour mode we don't have AM/PM control.
    expect(semantics, isNot(includesNodeWith(label: 'AM')));
    expect(semantics, isNot(includesNodeWith(label: 'PM')));

    semantics.dispose();
  });

  testWidgets('provides semantics information for hours', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, true);

    final CustomPaint dialPaint = tester.widget(find.byKey(const ValueKey<String>('time-picker-dial')));
    final CustomPainter dialPainter = dialPaint.painter;
    final _CustomPainterSemanticsTester painterTester = new _CustomPainterSemanticsTester(tester, dialPainter, semantics);

    painterTester.addLabel('00', 86.0, 12.0, 134.0, 36.0);
    painterTester.addLabel('13', 129.0, 23.5, 177.0, 47.5);
    painterTester.addLabel('14', 160.5, 55.0, 208.5, 79.0);
    painterTester.addLabel('15', 172.0, 98.0, 220.0, 122.0);
    painterTester.addLabel('16', 160.5, 141.0, 208.5, 165.0);
    painterTester.addLabel('17', 129.0, 172.5, 177.0, 196.5);
    painterTester.addLabel('18', 86.0, 184.0, 134.0, 208.0);
    painterTester.addLabel('19', 43.0, 172.5, 91.0, 196.5);
    painterTester.addLabel('20', 11.5, 141.0, 59.5, 165.0);
    painterTester.addLabel('21', 0.0, 98.0, 48.0, 122.0);
    painterTester.addLabel('22', 11.5, 55.0, 59.5, 79.0);
    painterTester.addLabel('23', 43.0, 23.5, 91.0, 47.5);
    painterTester.addLabel('12', 86.0, 48.0, 134.0, 72.0);
    painterTester.addLabel('01', 111.0, 54.7, 159.0, 78.7);
    painterTester.addLabel('02', 129.3, 73.0, 177.3, 97.0);
    painterTester.addLabel('03', 136.0, 98.0, 184.0, 122.0);
    painterTester.addLabel('04', 129.3, 123.0, 177.3, 147.0);
    painterTester.addLabel('05', 111.0, 141.3, 159.0, 165.3);
    painterTester.addLabel('06', 86.0, 148.0, 134.0, 172.0);
    painterTester.addLabel('07', 61.0, 141.3, 109.0, 165.3);
    painterTester.addLabel('08', 42.7, 123.0, 90.7, 147.0);
    painterTester.addLabel('09', 36.0, 98.0, 84.0, 122.0);
    painterTester.addLabel('10', 42.7, 73.0, 90.7, 97.0);
    painterTester.addLabel('11', 61.0, 54.7, 109.0, 78.7);

    painterTester.assertExpectations();
    semantics.dispose();
  });

  testWidgets('provides semantics information for minutes', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await mediaQueryBoilerplate(tester, true);
    await tester.tap(_minuteControl);
    await tester.pumpAndSettle();

    final CustomPaint dialPaint = tester.widget(find.byKey(const ValueKey<String>('time-picker-dial')));
    final CustomPainter dialPainter = dialPaint.painter;
    final _CustomPainterSemanticsTester painterTester = new _CustomPainterSemanticsTester(tester, dialPainter, semantics);

    painterTester.addLabel('00', 86.0, 12.0, 134.0, 36.0);
    painterTester.addLabel('05', 129.0, 23.5, 177.0, 47.5);
    painterTester.addLabel('10', 160.5, 55.0, 208.5, 79.0);
    painterTester.addLabel('15', 172.0, 98.0, 220.0, 122.0);
    painterTester.addLabel('20', 160.5, 141.0, 208.5, 165.0);
    painterTester.addLabel('25', 129.0, 172.5, 177.0, 196.5);
    painterTester.addLabel('30', 86.0, 184.0, 134.0, 208.0);
    painterTester.addLabel('35', 43.0, 172.5, 91.0, 196.5);
    painterTester.addLabel('40', 11.5, 141.0, 59.5, 165.0);
    painterTester.addLabel('45', 0.0, 98.0, 48.0, 122.0);
    painterTester.addLabel('50', 11.5, 55.0, 59.5, 79.0);
    painterTester.addLabel('55', 43.0, 23.5, 91.0, 47.5);

    painterTester.assertExpectations();
    semantics.dispose();
  });

  testWidgets('picks the right dial ring from widget configuration', (WidgetTester tester) async {
    await mediaQueryBoilerplate(tester, true, initialTime: const TimeOfDay(hour: 12, minute: 0));
    dynamic dialPaint = tester.widget(findDialPaint);
    expect('${dialPaint.painter.activeRing}', '_DialRing.inner');

    await tester.pumpWidget(new Container()); // make sure previous state isn't reused

    await mediaQueryBoilerplate(tester, true, initialTime: const TimeOfDay(hour: 0, minute: 0));
    dialPaint = tester.widget(findDialPaint);
    expect('${dialPaint.painter.activeRing}', '_DialRing.outer');
  });

  testWidgets('can increment and decrement hours', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    Future<Null> actAndExpect({ String initialValue, SemanticsAction action, String finalValue }) async {
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
    await tester.pumpWidget(new Container()); // clear old boilerplate

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
  });

  testWidgets('can increment and decrement minutes', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    Future<Null> actAndExpect({ String initialValue, SemanticsAction action, String finalValue }) async {
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
  });
}

final Finder findDialPaint = find.descendant(
  of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
  matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
);

class _SemanticsNodeExpectation {
  final String label;
  final double left;
  final double top;
  final double right;
  final double bottom;

  _SemanticsNodeExpectation(this.label, this.left, this.top, this.right, this.bottom);
}

class _CustomPainterSemanticsTester {
  _CustomPainterSemanticsTester(this.tester, this.painter, this.semantics);

  final WidgetTester tester;
  final CustomPainter painter;
  final SemanticsTester semantics;
  final PaintPattern expectedLabels = paints;
  final List<_SemanticsNodeExpectation> expectedNodes = <_SemanticsNodeExpectation>[];

  void addLabel(String label, double left, double top, double right, double bottom) {
    expectedNodes.add(new _SemanticsNodeExpectation(label, left, top, right, bottom));
  }

  void assertExpectations() {
    final TestRecordingCanvas canvasRecording = new TestRecordingCanvas();
    painter.paint(canvasRecording, const Size(220.0, 220.0));
    final List<ui.Paragraph> paragraphs = canvasRecording.invocations
      .where((RecordedInvocation recordedInvocation) {
        return recordedInvocation.invocation.memberName == #drawParagraph;
      })
      .map<ui.Paragraph>((RecordedInvocation recordedInvocation) {
        return recordedInvocation.invocation.positionalArguments.first;
      })
      .toList();

    final PaintPattern expectedLabels = paints;
    int i = 0;

    for (_SemanticsNodeExpectation expectation in expectedNodes) {
      expect(semantics, includesNodeWith(value: expectation.label));
      final Iterable<SemanticsNode> dialLabelNodes = semantics
          .nodesWith(value: expectation.label)
          .where((SemanticsNode node) => node.tags?.contains(const SemanticsTag('dial-label')) ?? false);
      expect(dialLabelNodes, hasLength(1), reason: 'Expected exactly one label ${expectation.label}');
      final Rect rect = new Rect.fromLTRB(expectation.left, expectation.top, expectation.right, expectation.bottom);
      expect(dialLabelNodes.single.rect, within(distance: 1.0, from: rect),
        reason: 'This is checking the node rectangle for label ${expectation.label}');

      final ui.Paragraph paragraph = paragraphs[i++];

      // The label text paragraph and the semantics node share the same center,
      // but have different sizes.
      final Offset center = dialLabelNodes.single.rect.center;
      final Offset topLeft = center.translate(
        -paragraph.width / 2.0,
        -paragraph.height / 2.0,
      );

      expectedLabels.paragraph(
        paragraph: paragraph,
        offset: within<Offset>(distance: 1.0, from: topLeft),
      );
    }
    expect(tester.renderObject(findDialPaint), expectedLabels);
  }
}
