// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

void main() {
  for (final MaterialType materialType in MaterialType.values) {
    final String selectTimeString;
    final String enterTimeString;
    final String cancelString;
    const String okString = 'OK';
    const String amString = 'AM';
    const String pmString = 'PM';
    switch (materialType) {
      case MaterialType.material2:
        selectTimeString = 'SELECT TIME';
        enterTimeString = 'ENTER TIME';
        cancelString = 'CANCEL';
      case MaterialType.material3:
        selectTimeString = 'Select time';
        enterTimeString = 'Enter time';
        cancelString = 'Cancel';
    }

    group('Dial (${materialType.name})', () {
      testWidgets('tap-select an hour', (WidgetTester tester) async {
        TimeOfDay? result;

        Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time;
        }, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy - 50)); // 12:00 AM
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 0, minute: 0)));

        center = (await startPicker(tester, (TimeOfDay? time) {
          result = time;
        }, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx + 50, center.dy));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 3, minute: 0)));

        center = (await startPicker(tester, (TimeOfDay? time) {
          result = time;
        }, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy + 50));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 0)));

        center = (await startPicker(tester, (TimeOfDay? time) {
          result = time;
        }, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy + 50));
        await tester.tapAt(Offset(center.dx - 50, center.dy));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 9, minute: 0)));
      });

      testWidgets('drag-select an hour', (WidgetTester tester) async {
        late TimeOfDay result;

        final Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, materialType: materialType))!;
        final Offset hour0 = Offset(center.dx, center.dy - 50); // 12:00 AM
        final Offset hour3 = Offset(center.dx + 50, center.dy);
        final Offset hour6 = Offset(center.dx, center.dy + 50);
        final Offset hour9 = Offset(center.dx - 50, center.dy);

        TestGesture gesture;

        gesture = await tester.startGesture(hour3);
        await gesture.moveBy(hour0 - hour3);
        await gesture.up();
        await finishPicker(tester);
        expect(result.hour, 0);

        expect(
          await startPicker(tester, (TimeOfDay? time) {
            result = time!;
          }, materialType: materialType),
          equals(center),
        );
        gesture = await tester.startGesture(hour0);
        await gesture.moveBy(hour3 - hour0);
        await gesture.up();
        await finishPicker(tester);
        expect(result.hour, 3);

        expect(
          await startPicker(tester, (TimeOfDay? time) {
            result = time!;
          }, materialType: materialType),
          equals(center),
        );
        gesture = await tester.startGesture(hour3);
        await gesture.moveBy(hour6 - hour3);
        await gesture.up();
        await finishPicker(tester);
        expect(result.hour, equals(6));

        expect(
          await startPicker(tester, (TimeOfDay? time) {
            result = time!;
          }, materialType: materialType),
          equals(center),
        );
        gesture = await tester.startGesture(hour6);
        await gesture.moveBy(hour9 - hour6);
        await gesture.up();
        await finishPicker(tester);
        expect(result.hour, equals(9));
      });

      testWidgets('tap-select switches from hour to minute', (WidgetTester tester) async {
        late TimeOfDay result;

        final Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, materialType: materialType))!;
        final Offset hour6 = Offset(center.dx, center.dy + 50); // 6:00
        final Offset min45 = Offset(center.dx - 50, center.dy); // 45 mins (or 9:00 hours)

        await tester.tapAt(hour6);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(min45);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
      });

      testWidgets('drag-select switches from hour to minute', (WidgetTester tester) async {
        late TimeOfDay result;

        final Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, materialType: materialType))!;
        final Offset hour3 = Offset(center.dx + 50, center.dy);
        final Offset hour6 = Offset(center.dx, center.dy + 50);
        final Offset hour9 = Offset(center.dx - 50, center.dy);

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
        late TimeOfDay result;

        final Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, materialType: materialType))!;
        final Offset hour6 = Offset(center.dx, center.dy + 50); // 6:00
        final Offset min46 = Offset(center.dx - 50, center.dy - 5); // 46 mins

        await tester.tapAt(hour6);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(min46);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
      });

      testWidgets('tap-select rounds up to nearest 5 minute increment', (WidgetTester tester) async {
        late TimeOfDay result;

        final Offset center = (await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, materialType: materialType))!;
        final Offset hour6 = Offset(center.dx, center.dy + 50); // 6:00
        final Offset min48 = Offset(center.dx - 50, center.dy - 15); // 48 mins

        await tester.tapAt(hour6);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(min48);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 50)));
      });
    });

    group('Dial Haptic Feedback (${materialType.name})', () {
      const Duration kFastFeedbackInterval = Duration(milliseconds: 10);
      const Duration kSlowFeedbackInterval = Duration(milliseconds: 200);
      late FeedbackTester feedback;

      setUp(() {
        feedback = FeedbackTester();
      });

      tearDown(() {
        feedback.dispose();
      });

      testWidgets('tap-select vibrates once', (WidgetTester tester) async {
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy - 50));
        await finishPicker(tester);
        expect(feedback.hapticCount, 1);
      });

      testWidgets('quick successive tap-selects vibrate once', (WidgetTester tester) async {
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy - 50));
        await tester.pump(kFastFeedbackInterval);
        await tester.tapAt(Offset(center.dx, center.dy + 50));
        await finishPicker(tester);
        expect(feedback.hapticCount, 1);
      });

      testWidgets('slow successive tap-selects vibrate once per tap', (WidgetTester tester) async {
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        await tester.tapAt(Offset(center.dx, center.dy - 50));
        await tester.pump(kSlowFeedbackInterval);
        await tester.tapAt(Offset(center.dx, center.dy + 50));
        await tester.pump(kSlowFeedbackInterval);
        await tester.tapAt(Offset(center.dx, center.dy - 50));
        await finishPicker(tester);
        expect(feedback.hapticCount, 3);
      });

      testWidgets('drag-select vibrates once', (WidgetTester tester) async {
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        final Offset hour0 = Offset(center.dx, center.dy - 50);
        final Offset hour3 = Offset(center.dx + 50, center.dy);

        final TestGesture gesture = await tester.startGesture(hour3);
        await gesture.moveBy(hour0 - hour3);
        await gesture.up();
        await finishPicker(tester);
        expect(feedback.hapticCount, 1);
      });

      testWidgets('quick drag-select vibrates once', (WidgetTester tester) async {
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        final Offset hour0 = Offset(center.dx, center.dy - 50);
        final Offset hour3 = Offset(center.dx + 50, center.dy);

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
        final Offset center = (await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType))!;
        final Offset hour0 = Offset(center.dx, center.dy - 50);
        final Offset hour3 = Offset(center.dx + 50, center.dy);

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

    group('Dialog (${materialType.name})', () {
      Material getMaterialFromDialog(WidgetTester tester) {
        return tester.widget<Material>(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first);
      }

      testWidgets('Widgets have correct label capitalization', (WidgetTester tester) async {
        await startPicker(tester, (TimeOfDay? time) {}, materialType: materialType);
        expect(find.text(selectTimeString), findsOneWidget);
        expect(find.text(cancelString), findsOneWidget);
      });

      testWidgets('Widgets have correct label capitalization in input mode', (WidgetTester tester) async {
        await startPicker(tester, (TimeOfDay? time) {},
            entryMode: TimePickerEntryMode.input, materialType: materialType);
        expect(find.text(enterTimeString), findsOneWidget);
        expect(find.text(cancelString), findsOneWidget);
      });

      testWidgets('respects MediaQueryData.alwaysUse24HourFormat == false', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, materialType: materialType);
        const List<String> labels12To11 = <String>['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

        final CustomPaint dialPaint = tester.widget(findDialPaint);
        final dynamic dialPainter = dialPaint.painter;
        // ignore: avoid_dynamic_calls
        final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
        // ignore: avoid_dynamic_calls
        expect(primaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels12To11);

        // ignore: avoid_dynamic_calls
        final List<dynamic> selectedLabels = dialPainter.selectedLabels as List<dynamic>;
        // ignore: avoid_dynamic_calls
        expect(selectedLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels12To11);
      });

      switch (materialType) {
        case MaterialType.material2:
          testWidgets('Dialog size - dial mode', (WidgetTester tester) async {
            addTearDown(tester.view.reset);

            const Size timePickerPortraitSize =  Size(310, 468);
            const Size timePickerLandscapeSize = Size(524, 342);
            const Size timePickerLandscapeSizeM2 = Size(508, 300);
            const EdgeInsets padding = EdgeInsets.fromLTRB(8, 18, 8, 8);
            double width;
            double height;

            // portrait
            tester.view.physicalSize = const Size(800, 800.5);
            tester.view.devicePixelRatio = 1;
            await mediaQueryBoilerplate(tester, materialType: materialType);

            width = timePickerPortraitSize.width + padding.horizontal;
            height = timePickerPortraitSize.height + padding.vertical;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );

            await tester.tap(find.text(okString)); // dismiss the dialog
            await tester.pumpAndSettle();

            // landscape
            tester.view.physicalSize = const Size(800.5, 800);
            tester.view.devicePixelRatio = 1;
            await mediaQueryBoilerplate(
              tester,
              alwaysUse24HourFormat: true,
              materialType: materialType,
            );

            width =  timePickerLandscapeSize.width + padding.horizontal;
            height = timePickerLandscapeSizeM2.height + padding.vertical;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );
          });

          testWidgets('Dialog size - input mode', (WidgetTester tester) async {
            const TimePickerEntryMode entryMode = TimePickerEntryMode.input;
            const Size timePickerInputSize = Size(312, 216);
            const Size dayPeriodPortraitSize = Size(52, 80);
            const EdgeInsets padding = EdgeInsets.fromLTRB(8, 18, 8, 8);
            final double height = timePickerInputSize.height + padding.vertical;
            double width;

            await mediaQueryBoilerplate(
              tester,
              entryMode: entryMode,
              materialType: materialType,
            );

            width = timePickerInputSize.width + padding.horizontal;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );

            await tester.tap(find.text(okString)); // dismiss the dialog
            await tester.pumpAndSettle();

            await mediaQueryBoilerplate(
              tester,
              alwaysUse24HourFormat: true,
              entryMode: entryMode,
              materialType: materialType,
            );
            width = timePickerInputSize.width - dayPeriodPortraitSize.width - 12 + padding.horizontal + 16;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );
          });

          testWidgets('respects MediaQueryData.alwaysUse24HourFormat == true', (WidgetTester tester) async {
            await mediaQueryBoilerplate(tester, alwaysUse24HourFormat: true, materialType: materialType);

            final List<String> labels00To22 = List<String>.generate(12, (int index) {
              return (index * 2).toString().padLeft(2, '0');
            });
            final CustomPaint dialPaint = tester.widget(findDialPaint);
            final dynamic dialPainter = dialPaint.painter;
            // ignore: avoid_dynamic_calls
            final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
            // ignore: avoid_dynamic_calls
            expect(primaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To22);

            // ignore: avoid_dynamic_calls
            final List<dynamic> selectedLabels = dialPainter.selectedLabels as List<dynamic>;
            // ignore: avoid_dynamic_calls
            expect(selectedLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To22);
          });
        case MaterialType.material3:
          testWidgets('Dialog size - dial mode', (WidgetTester tester) async {
            addTearDown(tester.view.reset);

            const Size timePickerPortraitSize =  Size(310, 468);
            const Size timePickerLandscapeSize = Size(524, 342);
            const EdgeInsets padding = EdgeInsets.all(24.0);
            double width;
            double height;

            // portrait
            tester.view.physicalSize = const Size(800, 800.5);
            tester.view.devicePixelRatio = 1;
            await mediaQueryBoilerplate(tester, materialType: materialType);

            width = timePickerPortraitSize.width + padding.horizontal;
            height = timePickerPortraitSize.height + padding.vertical;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );

            await tester.tap(find.text(okString)); // dismiss the dialog
            await tester.pumpAndSettle();

            // landscape
            tester.view.physicalSize = const Size(800.5, 800);
            tester.view.devicePixelRatio = 1;
            await mediaQueryBoilerplate(
              tester,
              alwaysUse24HourFormat: true,
              materialType: materialType,
            );

            width =  timePickerLandscapeSize.width + padding.horizontal;
            height = timePickerLandscapeSize.height + padding.vertical;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );
          });

          testWidgets('Dialog size - input mode', (WidgetTester tester) async {
            final ThemeData theme = ThemeData(useMaterial3: true);
            const TimePickerEntryMode entryMode = TimePickerEntryMode.input;
            const double textScaleFactor = 1.0;
            const Size timePickerMinInputSize = Size(312, 216);
            const Size dayPeriodPortraitSize = Size(52, 80);
            const EdgeInsets padding = EdgeInsets.all(24.0);
            final double height = timePickerMinInputSize.height * textScaleFactor + padding.vertical;
            double width;

            await mediaQueryBoilerplate(
              tester,
              entryMode: entryMode,
              materialType: materialType,
            );

            width = timePickerMinInputSize.width - (theme.useMaterial3 ? 32 : 0) + padding.horizontal;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );

            await tester.tap(find.text(okString)); // dismiss the dialog
            await tester.pumpAndSettle();

            await mediaQueryBoilerplate(
              tester,
              alwaysUse24HourFormat: true,
              entryMode: entryMode,
              materialType: materialType,
            );

            width = timePickerMinInputSize.width - dayPeriodPortraitSize.width - 12 + padding.horizontal;
            expect(
              tester.getSize(find.byWidget(getMaterialFromDialog(tester))),
              Size(width, height),
            );
          });

          testWidgets('respects MediaQueryData.alwaysUse24HourFormat == true', (WidgetTester tester) async {
            await mediaQueryBoilerplate(tester, alwaysUse24HourFormat: true, materialType: materialType);

            final List<String> labels00To23 = List<String>.generate(24, (int index) {
              return index == 0 ? '00' : index.toString();
            });
            final List<bool> inner0To23 = List<bool>.generate(24, (int index) => index >= 12);

            final CustomPaint dialPaint = tester.widget(findDialPaint);
            final dynamic dialPainter = dialPaint.painter;
            // ignore: avoid_dynamic_calls
            final List<dynamic> primaryLabels = dialPainter.primaryLabels as List<dynamic>;
            // ignore: avoid_dynamic_calls
            expect(primaryLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To23);
            // ignore: avoid_dynamic_calls
            expect(primaryLabels.map<bool>((dynamic tp) => tp.inner as bool), inner0To23);

            // ignore: avoid_dynamic_calls
            final List<dynamic> selectedLabels = dialPainter.selectedLabels as List<dynamic>;
            // ignore: avoid_dynamic_calls
            expect(selectedLabels.map<String>((dynamic tp) => tp.painter.text.text as String), labels00To23);
            // ignore: avoid_dynamic_calls
            expect(selectedLabels.map<bool>((dynamic tp) => tp.inner as bool), inner0To23);
          });
      }

      testWidgets('when change orientation, should reflect in render objects', (WidgetTester tester) async {
        addTearDown(tester.view.reset);

        // portrait
        tester.view.physicalSize = const Size(800, 800.5);
        tester.view.devicePixelRatio = 1;
        await mediaQueryBoilerplate(tester, materialType: materialType);

        RenderObject render = tester.renderObject(
          find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodInputPadding'),
        );
        expect((render as dynamic).orientation, Orientation.portrait); // ignore: avoid_dynamic_calls

        // landscape
        tester.view.physicalSize = const Size(800.5, 800);
        tester.view.devicePixelRatio = 1;
        await mediaQueryBoilerplate(tester, tapButton: false, materialType: materialType);

        render = tester.renderObject(
          find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodInputPadding'),
        );
        expect((render as dynamic).orientation, Orientation.landscape); // ignore: avoid_dynamic_calls
      });

      testWidgets('setting orientation should override MediaQuery orientation', (WidgetTester tester) async {
        addTearDown(tester.view.reset);

        // portrait media query
        tester.view.physicalSize = const Size(800, 800.5);
        tester.view.devicePixelRatio = 1;
        await mediaQueryBoilerplate(tester, orientation: Orientation.landscape, materialType: materialType);

        final RenderObject render = tester.renderObject(
          find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodInputPadding'),
        );
        expect((render as dynamic).orientation, Orientation.landscape); // ignore: avoid_dynamic_calls
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
                          builder: (BuildContext context, Widget? child) {
                            return Directionality(
                              textDirection: textDirection,
                              child: child!,
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
        final double ltrOkRight = tester.getBottomRight(find.text(okString)).dx;

        await tester.tap(find.text(okString)); // dismiss the dialog
        await tester.pumpAndSettle();

        await tester.pumpWidget(buildFrame(TextDirection.rtl));
        await tester.tap(find.text('X'));
        await tester.pumpAndSettle();

        // Verify that the time picker is being laid out RTL.
        // We expect the left edge of the 'OK' button in the RTL
        // layout to match the gap between right edge of the 'OK'
        // button and the right edge of the 800 wide view.
        expect(tester.getBottomLeft(find.text(okString)).dx, 800 - ltrOkRight);
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
                },
              ),
            ),
          ),
        ));

        // Open the picker.
        await tester.tap(find.text('X'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text(cancelText), findsOneWidget);
        expect(find.text(confirmText), findsOneWidget);
        expect(find.text(helperText), findsOneWidget);
      });

      testWidgets('OK Cancel button and helpText layout', (WidgetTester tester) async {
        Widget buildFrame(TextDirection textDirection) {
          return MaterialApp(
            theme: ThemeData.light().copyWith(useMaterial3: materialType == MaterialType.material3),
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
                          builder: (BuildContext context, Widget? child) {
                            return Directionality(
                              textDirection: textDirection,
                              child: child!,
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

        switch (materialType) {
          case MaterialType.material2:
            expect(tester.getTopLeft(find.text(selectTimeString)), equals(const Offset(154, 155)));
            expect(tester.getBottomRight(find.text(selectTimeString)), equals(const Offset(281, 165)));
            expect(tester.getBottomRight(find.text(okString)).dx, 644);
            expect(tester.getBottomLeft(find.text(okString)).dx, 616);
            expect(tester.getBottomRight(find.text(cancelString)).dx, 582);
          case MaterialType.material3:
            expect(tester.getTopLeft(find.text(selectTimeString)), equals(const Offset(138, 129)));
            expect(tester.getBottomRight(find.text(selectTimeString)), equals(const Offset(292.0, 143.0)));
            expect(tester.getBottomLeft(find.text(okString)).dx, 616);
            expect(tester.getBottomRight(find.text(cancelString)).dx, 578);
        }

        await tester.tap(find.text(okString));
        await tester.pumpAndSettle();

        await tester.pumpWidget(buildFrame(TextDirection.rtl));
        await tester.tap(find.text('X'));
        await tester.pumpAndSettle();

        switch (materialType) {
          case MaterialType.material2:
            expect(tester.getTopLeft(find.text(selectTimeString)), equals(const Offset(519, 155)));
            expect(tester.getBottomRight(find.text(selectTimeString)), equals(const Offset(646, 165)));
            expect(tester.getBottomLeft(find.text(okString)).dx, 156);
            expect(tester.getBottomRight(find.text(okString)).dx, 184);
            expect(tester.getBottomLeft(find.text(cancelString)).dx, 218);
          case MaterialType.material3:
            expect(tester.getTopLeft(find.text(selectTimeString)), equals(const Offset(508, 129)));
            expect(tester.getBottomRight(find.text(selectTimeString)), equals(const Offset(662, 143)));
            expect(tester.getBottomLeft(find.text(okString)).dx, 156);
            expect(tester.getBottomRight(find.text(okString)).dx, 184);
            expect(tester.getBottomLeft(find.text(cancelString)).dx, 222);
        }

        await tester.tap(find.text(okString));
        await tester.pumpAndSettle();
      });

      testWidgets('text scale affects certain elements and not others', (WidgetTester tester) async {
        await mediaQueryBoilerplate(
          tester,
          initialTime: const TimeOfDay(hour: 7, minute: 41),
          materialType: materialType,
        );

        final double minutesDisplayHeight = tester.getSize(find.text('41')).height;
        final double amHeight = tester.getSize(find.text(amString)).height;

        await tester.tap(find.text(okString)); // dismiss the dialog
        await tester.pumpAndSettle();

        // Verify that the time display is not affected by text scale.
        await mediaQueryBoilerplate(
          tester,
          textScaleFactor: 2,
          initialTime: const TimeOfDay(hour: 7, minute: 41),
          materialType: materialType,
        );

        final double amHeight2x = tester.getSize(find.text(amString)).height;
        expect(tester.getSize(find.text('41')).height, equals(minutesDisplayHeight));
        expect(amHeight2x, greaterThanOrEqualTo(amHeight * 2));

        await tester.tap(find.text(okString)); // dismiss the dialog
        await tester.pumpAndSettle();

        // Verify that text scale for AM/PM is at most 2x.
        await mediaQueryBoilerplate(
          tester,
          textScaleFactor: 3,
          initialTime: const TimeOfDay(hour: 7, minute: 41),
          materialType: materialType,
        );

        expect(tester.getSize(find.text('41')).height, equals(minutesDisplayHeight));
        expect(tester.getSize(find.text(amString)).height, equals(amHeight2x));
      });

      group('showTimePicker avoids overlapping display features', () {
        testWidgets('positioning with anchorPoint', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  // Display has a vertical hinge down the middle
                  data: const MediaQueryData(
                    size: Size(800, 600),
                    displayFeatures: <DisplayFeature>[
                      DisplayFeature(
                        bounds: Rect.fromLTRB(390, 0, 410, 600),
                        type: DisplayFeatureType.hinge,
                        state: DisplayFeatureState.unknown,
                      ),
                    ],
                  ),
                  child: child!,
                );
              },
              home: const Center(child: Text('Test')),
            ),
          );
          final BuildContext context = tester.element(find.text('Test'));

          showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 7, minute: 0),
            anchorPoint: const Offset(1000, 0),
          );

          await tester.pumpAndSettle();
          // Should take the right side of the screen
          expect(tester.getTopLeft(find.byType(TimePickerDialog)), const Offset(410, 0));
          expect(tester.getBottomRight(find.byType(TimePickerDialog)), const Offset(800, 600));
        });

        testWidgets('positioning with Directionality', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  // Display has a vertical hinge down the middle
                  data: const MediaQueryData(
                    size: Size(800, 600),
                    displayFeatures: <DisplayFeature>[
                      DisplayFeature(
                        bounds: Rect.fromLTRB(390, 0, 410, 600),
                        type: DisplayFeatureType.hinge,
                        state: DisplayFeatureState.unknown,
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                );
              },
              home: const Center(child: Text('Test')),
            ),
          );
          final BuildContext context = tester.element(find.text('Test'));

          // By default it should place the dialog on the right screen
          showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 7, minute: 0),
          );

          await tester.pumpAndSettle();
          expect(tester.getTopLeft(find.byType(TimePickerDialog)), const Offset(410, 0));
          expect(tester.getBottomRight(find.byType(TimePickerDialog)), const Offset(800, 600));
        });

        testWidgets('positioning with defaults', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  // Display has a vertical hinge down the middle
                  data: const MediaQueryData(
                    size: Size(800, 600),
                    displayFeatures: <DisplayFeature>[
                      DisplayFeature(
                        bounds: Rect.fromLTRB(390, 0, 410, 600),
                        type: DisplayFeatureType.hinge,
                        state: DisplayFeatureState.unknown,
                      ),
                    ],
                  ),
                  child: child!,
                );
              },
              home: const Center(child: Text('Test')),
            ),
          );
          final BuildContext context = tester.element(find.text('Test'));

          // By default it should place the dialog on the left screen
          showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 7, minute: 0),
          );

          await tester.pumpAndSettle();
          expect(tester.getTopLeft(find.byType(TimePickerDialog)), Offset.zero);
          expect(tester.getBottomRight(find.byType(TimePickerDialog)), const Offset(390, 600));
        });
      });

      group('Works for various view sizes', () {
        for (final Size size in const <Size>[Size(100, 100), Size(300, 300), Size(800, 600)]) {
          testWidgets('Draws dial without overflows at $size', (WidgetTester tester) async {
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);

            await mediaQueryBoilerplate(tester, entryMode: TimePickerEntryMode.input, materialType: materialType);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNot(throwsAssertionError));
          });

          testWidgets('Draws input without overflows at $size', (WidgetTester tester) async {
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);

            await mediaQueryBoilerplate(tester, materialType: materialType);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNot(throwsAssertionError));
          });
        }
      });
    });

    group('Time picker - A11y and Semantics (${materialType.name})', () {
      testWidgets('provides semantics information for AM/PM indicator', (WidgetTester tester) async {
        final SemanticsTester semantics = SemanticsTester(tester);
        await mediaQueryBoilerplate(tester, materialType: materialType);

        expect(
          semantics,
          includesNodeWith(
            label: amString,
            actions: <SemanticsAction>[SemanticsAction.tap],
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.isChecked,
              SemanticsFlag.isInMutuallyExclusiveGroup,
              SemanticsFlag.hasCheckedState,
              SemanticsFlag.isFocusable,
            ],
          ),
        );
        expect(
          semantics,
          includesNodeWith(
            label: pmString,
            actions: <SemanticsAction>[SemanticsAction.tap],
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.isInMutuallyExclusiveGroup,
              SemanticsFlag.hasCheckedState,
              SemanticsFlag.isFocusable,
            ],
          ),
        );

        semantics.dispose();
      });

      testWidgets('provides semantics information for header and footer', (WidgetTester tester) async {
        final SemanticsTester semantics = SemanticsTester(tester);
        await mediaQueryBoilerplate(tester, alwaysUse24HourFormat: true, materialType: materialType);

        expect(semantics, isNot(includesNodeWith(label: ':')));
        expect(
          semantics.nodesWith(value: 'Select minutes 00'),
          hasLength(1),
          reason: '00 appears once in the header',
        );
        expect(
          semantics.nodesWith(value: 'Select hours 07'),
          hasLength(1),
          reason: '07 appears once in the header',
        );
        expect(semantics, includesNodeWith(label: cancelString));
        expect(semantics, includesNodeWith(label: okString));

        // In 24-hour mode we don't have AM/PM control.
        expect(semantics, isNot(includesNodeWith(label: amString)));
        expect(semantics, isNot(includesNodeWith(label: pmString)));

        semantics.dispose();
      });

      testWidgets('provides semantics information for text fields', (WidgetTester tester) async {
        final SemanticsTester semantics = SemanticsTester(tester);
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          accessibleNavigation: true,
          materialType: materialType,
        );

        expect(
          semantics,
          includesNodeWith(
            label: 'Hour',
            value: '07',
            actions: <SemanticsAction>[SemanticsAction.tap],
            flags: <SemanticsFlag>[SemanticsFlag.isTextField, SemanticsFlag.isMultiline],
          ),
        );
        expect(
          semantics,
          includesNodeWith(
            label: 'Minute',
            value: '00',
            actions: <SemanticsAction>[SemanticsAction.tap],
            flags: <SemanticsFlag>[SemanticsFlag.isTextField, SemanticsFlag.isMultiline],
          ),
        );

        semantics.dispose();
      });

      testWidgets('can increment and decrement hours', (WidgetTester tester) async {
        final SemanticsTester semantics = SemanticsTester(tester);

        Future<void> actAndExpect({
          required String initialValue,
          required SemanticsAction action,
          required String finalValue,
        }) async {
          final SemanticsNode elevenHours = semantics
              .nodesWith(
                value: 'Select hours $initialValue',
                ancestor: tester.renderObject(_hourControl).debugSemantics,
              )
              .single;
          tester.binding.pipelineOwner.semanticsOwner!.performAction(elevenHours.id, action);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: _hourControl, matching: find.text(finalValue)),
            findsOneWidget,
          );
        }

        // 12-hour format
        await mediaQueryBoilerplate(
          tester,
          initialTime: const TimeOfDay(hour: 11, minute: 0),
          materialType: materialType,
        );
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
        final dynamic pickerState = tester.state(_timePicker);
        // ignore: avoid_dynamic_calls
        expect(pickerState.selectedTime.value, const TimeOfDay(hour: 1, minute: 0));

        await actAndExpect(
          initialValue: '1',
          action: SemanticsAction.decrease,
          finalValue: '12',
        );
        await tester.pumpWidget(Container()); // clear old boilerplate

        // 24-hour format
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          initialTime: const TimeOfDay(hour: 23, minute: 0),
          materialType: materialType,
        );
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

        Future<void> actAndExpect({
          required String initialValue,
          required SemanticsAction action,
          required String finalValue,
        }) async {
          final SemanticsNode elevenHours = semantics
              .nodesWith(
                value: 'Select minutes $initialValue',
                ancestor: tester.renderObject(_minuteControl).debugSemantics,
              )
              .single;
          tester.binding.pipelineOwner.semanticsOwner!.performAction(elevenHours.id, action);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: _minuteControl, matching: find.text(finalValue)),
            findsOneWidget,
          );
        }

        await mediaQueryBoilerplate(
          tester,
          initialTime: const TimeOfDay(hour: 11, minute: 58),
          materialType: materialType,
        );
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
        final dynamic pickerState = tester.state(_timePicker);
        // ignore: avoid_dynamic_calls
        expect(pickerState.selectedTime.value, const TimeOfDay(hour: 11, minute: 0));

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
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await mediaQueryBoilerplate(tester, materialType: materialType);

        final Size dayPeriodControlSize = tester.getSize(
          find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DayPeriodControl'),
        );
        expect(dayPeriodControlSize.width, greaterThanOrEqualTo(48));
        expect(dayPeriodControlSize.height, greaterThanOrEqualTo(80));

        final Size hourSize = tester.getSize(find.ancestor(
          of: find.text('7'),
          matching: find.byType(InkWell),
        ));
        expect(hourSize.width, greaterThanOrEqualTo(48));
        expect(hourSize.height, greaterThanOrEqualTo(48));

        final Size minuteSize = tester.getSize(find.ancestor(
          of: find.text('00'),
          matching: find.byType(InkWell),
        ));
        expect(minuteSize.width, greaterThanOrEqualTo(48));
        expect(minuteSize.height, greaterThanOrEqualTo(48));
      });
    });

    group('Time picker - Input (${materialType.name})', () {
      testWidgets('Initial entry mode is used', (WidgetTester tester) async {
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          materialType: materialType,
        );
        expect(find.byType(TextField), findsNWidgets(2));
      });

      testWidgets('Initial time is the default', (WidgetTester tester) async {
        late TimeOfDay result;
        await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, entryMode: TimePickerEntryMode.input, materialType: materialType);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 7, minute: 0)));
      });

      testWidgets('Help text is used - Input', (WidgetTester tester) async {
        const String helpText = 'help';
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          helpText: helpText,
          materialType: materialType,
        );
        expect(find.text(helpText), findsOneWidget);
      });

      testWidgets('Help text is used in Material3 - Input', (WidgetTester tester) async {
        const String helpText = 'help';
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          helpText: helpText,
          materialType: materialType,
        );
        expect(find.text(helpText), findsOneWidget);
      });

      testWidgets('Hour label text is used - Input', (WidgetTester tester) async {
        const String hourLabelText = 'Custom hour label';
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          hourLabelText: hourLabelText,
          materialType: materialType,
        );
        expect(find.text(hourLabelText), findsOneWidget);
      });

      testWidgets('Minute label text is used - Input', (WidgetTester tester) async {
        const String minuteLabelText = 'Custom minute label';
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          minuteLabelText: minuteLabelText,
          materialType: materialType,
        );
        expect(find.text(minuteLabelText), findsOneWidget);
      });

      testWidgets('Invalid error text is used - Input', (WidgetTester tester) async {
        const String errorInvalidText = 'Custom validation error';
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          errorInvalidText: errorInvalidText,
          materialType: materialType,
        );
        // Input invalid time (hour) to force validation error
        await tester.enterText(find.byType(TextField).first, '88');
        final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(
          tester.element(find.byType(TextButton).first),
        );
        // Tap the ok button to trigger the validation error with custom translation
        await tester.tap(find.text(materialLocalizations.okButtonLabel));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text(errorInvalidText), findsOneWidget);
      });

      testWidgets('Can switch from input to dial entry mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          materialType: materialType,
        );
        await tester.tap(find.byIcon(Icons.access_time));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('Can switch from dial to input entry mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, alwaysUse24HourFormat: true, materialType: materialType);
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('Can not switch out of inputOnly mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.inputOnly,
          materialType: materialType,
        );
        expect(find.byType(TextField), findsWidgets);
        expect(find.byIcon(Icons.access_time), findsNothing);
      });

      testWidgets('Can not switch out of dialOnly mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.dialOnly,
          materialType: materialType,
        );
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
      });

      testWidgets('Switching to dial entry mode triggers entry callback', (WidgetTester tester) async {
        bool triggeredCallback = false;

        await mediaQueryBoilerplate(
          tester,
          alwaysUse24HourFormat: true,
          entryMode: TimePickerEntryMode.input,
          onEntryModeChange: (TimePickerEntryMode mode) {
            if (mode == TimePickerEntryMode.dial) {
              triggeredCallback = true;
            }
          },
          materialType: materialType,
        );

        await tester.tap(find.byIcon(Icons.access_time));
        await tester.pumpAndSettle();
        expect(triggeredCallback, true);
      });

      testWidgets('Switching to input entry mode triggers entry callback', (WidgetTester tester) async {
        bool triggeredCallback = false;

        await mediaQueryBoilerplate(tester, alwaysUse24HourFormat: true, onEntryModeChange: (TimePickerEntryMode mode) {
          if (mode == TimePickerEntryMode.input) {
            triggeredCallback = true;
          }
        }, materialType: materialType);

        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();
        expect(triggeredCallback, true);
      });

      testWidgets('Can double tap hours (when selected) to enter input mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, materialType: materialType);
        final Finder hourFinder = find.ancestor(
          of: find.text('7'),
          matching: find.byType(InkWell),
        );

        expect(find.byType(TextField), findsNothing);

        // Double tap the hour.
        await tester.tap(hourFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(hourFinder);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('Can not double tap hours (when not selected) to enter input mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, materialType: materialType);
        final Finder hourFinder = find.ancestor(
          of: find.text('7'),
          matching: find.byType(InkWell),
        );
        final Finder minuteFinder = find.ancestor(
          of: find.text('00'),
          matching: find.byType(InkWell),
        );

        expect(find.byType(TextField), findsNothing);

        // Switch to minutes mode.
        await tester.tap(minuteFinder);
        await tester.pumpAndSettle();

        // Double tap the hour.
        await tester.tap(hourFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(hourFinder);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('Can double tap minutes (when selected) to enter input mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, materialType: materialType);
        final Finder minuteFinder = find.ancestor(
          of: find.text('00'),
          matching: find.byType(InkWell),
        );

        expect(find.byType(TextField), findsNothing);

        // Switch to minutes mode.
        await tester.tap(minuteFinder);
        await tester.pumpAndSettle();

        // Double tap the minutes.
        await tester.tap(minuteFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(minuteFinder);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('Can not double tap minutes (when not selected) to enter input mode', (WidgetTester tester) async {
        await mediaQueryBoilerplate(tester, materialType: materialType);
        final Finder minuteFinder = find.ancestor(
          of: find.text('00'),
          matching: find.byType(InkWell),
        );

        expect(find.byType(TextField), findsNothing);

        // Double tap the minutes.
        await tester.tap(minuteFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(minuteFinder);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('Entered text returns time', (WidgetTester tester) async {
        late TimeOfDay result;
        await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, entryMode: TimePickerEntryMode.input, materialType: materialType);
        await tester.enterText(find.byType(TextField).first, '9');
        await tester.enterText(find.byType(TextField).last, '12');
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 9, minute: 12)));
      });

      testWidgets('Toggle to dial mode keeps selected time', (WidgetTester tester) async {
        late TimeOfDay result;
        await startPicker(tester, (TimeOfDay? time) {
          result = time!;
        }, entryMode: TimePickerEntryMode.input, materialType: materialType);
        await tester.enterText(find.byType(TextField).first, '8');
        await tester.enterText(find.byType(TextField).last, '15');
        await tester.tap(find.byIcon(Icons.access_time));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 8, minute: 15)));
      });

      testWidgets('Invalid text prevents dismissing', (WidgetTester tester) async {
        TimeOfDay? result;
        await startPicker(tester, (TimeOfDay? time) {
          result = time;
        }, entryMode: TimePickerEntryMode.input, materialType: materialType);

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
        await startPicker(tester, (TimeOfDay? time) {},
            entryMode: TimePickerEntryMode.input, materialType: materialType);
        final double hourFieldTop =
            tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourTextField')).dy;
        final double minuteFieldTop =
            tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_MinuteTextField')).dy;
        final double separatorTop =
            tester.getTopLeft(find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_StringFragment')).dy;
        expect(hourFieldTop, separatorTop);
        expect(minuteFieldTop, separatorTop);
      });

      testWidgets('Can switch between hour/minute fields using keyboard input action', (WidgetTester tester) async {
        await startPicker(tester, (TimeOfDay? time) {},
            entryMode: TimePickerEntryMode.input, materialType: materialType);

        final Finder hourFinder = find.byType(TextField).first;
        final TextField hourField = tester.widget(hourFinder);
        await tester.tap(hourFinder);
        expect(hourField.focusNode!.hasFocus, isTrue);

        await tester.enterText(find.byType(TextField).first, '08');
        final Finder minuteFinder = find.byType(TextField).last;
        final TextField minuteField = tester.widget(minuteFinder);
        expect(hourField.focusNode!.hasFocus, isFalse);
        expect(minuteField.focusNode!.hasFocus, isTrue);

        expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        expect(hourField.focusNode!.hasFocus, isFalse);
        expect(minuteField.focusNode!.hasFocus, isFalse);
      });
    });

    group('Time picker - Restoration (${materialType.name})', () {
      testWidgets('Time Picker state restoration test - dial mode', (WidgetTester tester) async {
        TimeOfDay? result;
        final Offset center = (await startPicker(
          tester,
          (TimeOfDay? time) {
            result = time;
          },
          restorationId: 'restorable_time_picker',
          materialType: materialType,
        ))!;
        final Offset hour6 = Offset(center.dx, center.dy + 50); // 6:00
        final Offset min45 = Offset(center.dx - 50, center.dy); // 45 mins (or 9:00 hours)

        await tester.tapAt(hour6);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();
        await tester.tapAt(min45);
        await tester.pump(const Duration(milliseconds: 50));
        final TestRestorationData restorationData = await tester.getRestorationData();
        await tester.restartAndRestore();
        // Setting to PM adds 12 hours (18:45)
        await tester.tap(find.text(pmString));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 18, minute: 45)));

        // Test restoring from before PM was selected (6:45)
        await tester.restoreFrom(restorationData);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
      });

      testWidgets('Time Picker state restoration test - input mode', (WidgetTester tester) async {
        TimeOfDay? result;
        await startPicker(
          tester,
          (TimeOfDay? time) {
            result = time;
          },
          entryMode: TimePickerEntryMode.input,
          restorationId: 'restorable_time_picker',
          materialType: materialType,
        );
        await tester.enterText(find.byType(TextField).first, '9');
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();

        await tester.enterText(find.byType(TextField).last, '12');
        await tester.pump(const Duration(milliseconds: 50));
        final TestRestorationData restorationData = await tester.getRestorationData();
        await tester.restartAndRestore();

        // Setting to PM adds 12 hours (21:12)
        await tester.tap(find.text(pmString));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();

        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 21, minute: 12)));

        // Restoring from before PM was set (9:12)
        await tester.restoreFrom(restorationData);
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 9, minute: 12)));
      });

      testWidgets('Time Picker state restoration test - switching modes', (WidgetTester tester) async {
        TimeOfDay? result;
        final Offset center = (await startPicker(
          tester,
          (TimeOfDay? time) {
            result = time;
          },
          restorationId: 'restorable_time_picker',
          materialType: materialType,
        ))!;

        final TestRestorationData restorationData = await tester.getRestorationData();
        // Switch to input mode from dial mode.
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();

        // Select time using input mode controls.
        await tester.enterText(find.byType(TextField).first, '9');
        await tester.enterText(find.byType(TextField).last, '12');
        await tester.pump(const Duration(milliseconds: 50));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 9, minute: 12)));

        // Restoring from dial mode.
        await tester.restoreFrom(restorationData);
        final Offset hour6 = Offset(center.dx, center.dy + 50); // 6:00
        final Offset min45 = Offset(center.dx - 50, center.dy); // 45 mins (or 9:00 hours)

        await tester.tapAt(hour6);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.restartAndRestore();
        await tester.tapAt(min45);
        await tester.pump(const Duration(milliseconds: 50));
        await finishPicker(tester);
        expect(result, equals(const TimeOfDay(hour: 6, minute: 45)));
      });
    });
  }
}

final Finder findDialPaint = find.descendant(
  of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_Dial'),
  matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
);

class PickerObserver extends NavigatorObserver {
  int pickerCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute) {
      pickerCount++;
    }
    super.didPush(route, previousRoute);
  }
}

Future<void> mediaQueryBoilerplate(
  WidgetTester tester, {
  bool alwaysUse24HourFormat = false,
  TimeOfDay initialTime = const TimeOfDay(hour: 7, minute: 0),
  double textScaleFactor = 1,
  TimePickerEntryMode entryMode = TimePickerEntryMode.dial,
  String? helpText,
  String? hourLabelText,
  String? minuteLabelText,
  String? errorInvalidText,
  bool accessibleNavigation = false,
  EntryModeChangeCallback? onEntryModeChange,
  bool tapButton = true,
  required MaterialType materialType,
  Orientation? orientation,
}) async {
  await tester.pumpWidget(
    Builder(builder: (BuildContext context) {
      return Theme(
        data: Theme.of(context).copyWith(useMaterial3: materialType == MaterialType.material3),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: MediaQuery(
            data: MediaQueryData(
              alwaysUse24HourFormat: alwaysUse24HourFormat,
              textScaleFactor: textScaleFactor,
              accessibleNavigation: accessibleNavigation,
              size: tester.view.physicalSize / tester.view.devicePixelRatio,
            ),
            child: Material(
              child: Center(
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
                              hourLabelText: hourLabelText,
                              minuteLabelText: minuteLabelText,
                              errorInvalidText: errorInvalidText,
                              onEntryModeChanged: onEntryModeChange,
                              orientation: orientation,
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
        ),
      );
    }),
  );
  if (tapButton) {
    await tester.tap(find.text('X'));
  }
  await tester.pumpAndSettle();
}

final Finder _hourControl = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_HourControl');
final Finder _minuteControl = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_MinuteControl');
final Finder _timePicker = find.byWidgetPredicate((Widget widget) => '${widget.runtimeType}' == '_TimePicker');

class _TimePickerLauncher extends StatefulWidget {
  const _TimePickerLauncher({
    required this.onChanged,
    this.entryMode = TimePickerEntryMode.dial,
    this.restorationId,
  });

  final ValueChanged<TimeOfDay?> onChanged;
  final TimePickerEntryMode entryMode;
  final String? restorationId;

  @override
  _TimePickerLauncherState createState() => _TimePickerLauncherState();
}

class _TimePickerLauncherState extends State<_TimePickerLauncher> with RestorationMixin {
  @override
  String? get restorationId => widget.restorationId;

  late final RestorableRouteFuture<TimeOfDay?> _restorableTimePickerRouteFuture = RestorableRouteFuture<TimeOfDay?>(
    onComplete: _selectTime,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _timePickerRoute,
        arguments: <String, String>{
          'entry_mode': widget.entryMode.name,
        },
      );
    },
  );

  @pragma('vm:entry-point')
  static Route<TimeOfDay> _timePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    final Map<dynamic, dynamic> args = arguments! as Map<dynamic, dynamic>;
    final TimePickerEntryMode entryMode = TimePickerEntryMode.values.firstWhere(
      (TimePickerEntryMode element) => element.name == args['entry_mode'],
    );
    return DialogRoute<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return TimePickerDialog(
          restorationId: 'time_picker_dialog',
          initialTime: const TimeOfDay(hour: 7, minute: 0),
          initialEntryMode: entryMode,
        );
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableTimePickerRouteFuture, 'time_picker_route_future');
  }

  void _selectTime(TimeOfDay? newSelectedTime) {
    widget.onChanged(newSelectedTime);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              child: const Text('X'),
              onPressed: () async {
                if (widget.restorationId == null) {
                  widget.onChanged(await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                    initialEntryMode: widget.entryMode,
                  ));
                } else {
                  _restorableTimePickerRouteFuture.present();
                }
              },
            );
          },
        ),
      ),
    );
  }
}

// The version of material design layout, etc. to test. Corresponds to
// useMaterial3 true/false in the ThemeData, but used an enum here so that it
// wasn't just a boolean, for easier identification of the name of the mode in
// tests.
enum MaterialType {
  material2,
  material3,
}

Future<Offset?> startPicker(
  WidgetTester tester,
  ValueChanged<TimeOfDay?> onChanged, {
  TimePickerEntryMode entryMode = TimePickerEntryMode.dial,
  String? restorationId,
  required MaterialType materialType,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(useMaterial3: materialType == MaterialType.material3),
    restorationScopeId: 'app',
    locale: const Locale('en', 'US'),
    home: _TimePickerLauncher(
      onChanged: onChanged,
      entryMode: entryMode,
      restorationId: restorationId,
    ),
  ));
  await tester.tap(find.text('X'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return entryMode == TimePickerEntryMode.dial
      ? tester.getCenter(find.byKey(const ValueKey<String>('time-picker-dial')))
      : null;
}

Future<void> finishPicker(WidgetTester tester) async {
  final MaterialLocalizations materialLocalizations = MaterialLocalizations.of(
    tester.element(find.byType(ElevatedButton)),
  );
  await tester.tap(find.text(materialLocalizations.okButtonLabel));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}
