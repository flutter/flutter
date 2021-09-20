// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  late DateTime firstDate;
  late DateTime lastDate;
  late DateTime? currentDate;
  late DateTimeRange? initialDateRange;
  late DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar;

  String? cancelText;
  String? confirmText;
  String? errorInvalidRangeText;
  String? errorFormatText;
  String? errorInvalidText;
  String? fieldStartHintText;
  String? fieldEndHintText;
  String? fieldStartLabelText;
  String? fieldEndLabelText;
  String? helpText;
  String? saveText;

  setUp(() {
    firstDate = DateTime(2015, DateTime.january, 1);
    lastDate = DateTime(2016, DateTime.december, 31);
    currentDate = null;
    initialDateRange = DateTimeRange(
      start: DateTime(2016, DateTime.january, 15),
      end: DateTime(2016, DateTime.january, 25),
    );
    initialEntryMode = DatePickerEntryMode.calendar;

    cancelText = null;
    confirmText = null;
    errorInvalidRangeText = null;
    errorFormatText = null;
    errorInvalidText = null;
    fieldStartHintText = null;
    fieldEndHintText = null;
    fieldStartLabelText = null;
    fieldEndLabelText = null;
    helpText = null;
    saveText = null;
  });

  Future<void> preparePicker(
    WidgetTester tester,
    Future<void> Function(Future<DateTimeRange?> date) callback, {
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    late BuildContext buttonContext;
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () {
                buttonContext = context;
              },
              child: const Text('Go'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('Go'));
    expect(buttonContext, isNotNull);

    final Future<DateTimeRange?> range = showDateRangePicker(
      context: buttonContext,
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      initialEntryMode: initialEntryMode,
      cancelText: cancelText,
      confirmText: confirmText,
      errorInvalidRangeText: errorInvalidRangeText,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldStartHintText: fieldStartHintText,
      fieldEndHintText: fieldEndHintText,
      fieldStartLabelText: fieldStartLabelText,
      fieldEndLabelText: fieldEndLabelText,
      helpText: helpText,
      saveText: saveText,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox(),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await callback(range);
  }

  testWidgets('Save and help text is used', (WidgetTester tester) async {
    helpText = 'help';
    saveText = 'make it so';
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      expect(find.text(helpText!), findsOneWidget);
      expect(find.text(saveText!), findsOneWidget);
    });
  });

  testWidgets('Initial date is the default', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.text('SAVE'));
      expect(
        await range,
        DateTimeRange(
          start: DateTime(2016, DateTime.january, 15),
          end: DateTime(2016, DateTime.january, 25),
        ),
      );
    });
  });

  testWidgets('Last month header should be visible if last date is selected', (WidgetTester tester) async {
    firstDate = DateTime(2015, DateTime.january, 1);
    lastDate = DateTime(2016, DateTime.december, 31);
    initialDateRange = DateTimeRange(
      start: lastDate,
      end: lastDate,
    );
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      // December header should be showing, but no November
      expect(find.text('December 2016'), findsOneWidget);
      expect(find.text('November 2016'), findsNothing);
    });
  });

  testWidgets('First month header should be visible if first date is selected', (WidgetTester tester) async {
    firstDate = DateTime(2015, DateTime.january, 1);
    lastDate = DateTime(2016, DateTime.december, 31);
    initialDateRange = DateTimeRange(
      start: firstDate,
      end: firstDate,
    );
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      // January and February headers should be showing, but no March
      expect(find.text('January 2015'), findsOneWidget);
      expect(find.text('February 2015'), findsOneWidget);
      expect(find.text('March 2015'), findsNothing);
    });
  });

  testWidgets('Current month header should be visible if no date is selected', (WidgetTester tester) async {
    firstDate = DateTime(2015, DateTime.january, 1);
    lastDate = DateTime(2016, DateTime.december, 31);
    currentDate = DateTime(2016, DateTime.september, 1);
    initialDateRange = null;

    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      // September and October headers should be showing, but no August
      expect(find.text('September 2016'), findsOneWidget);
      expect(find.text('October 2016'), findsOneWidget);
      expect(find.text('August 2016'), findsNothing);
    });
  });

  testWidgets('Can cancel', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.byIcon(Icons.close));
      expect(await range, isNull);
    });
  });

  testWidgets('Can select a range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('14').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 14),
      ));
    });
  });

  testWidgets('Tapping earlier date resets selected range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('11').first);
      await tester.tap(find.text('15').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 11),
        end: DateTime(2016, DateTime.january, 15),
      ));
    });
  });

  testWidgets('Can select single day range', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('SAVE'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 12),
      ));
    });
  });

  testWidgets('Cannot select a day outside bounds', (WidgetTester tester) async {
    initialDateRange = DateTimeRange(
      start: DateTime(2017, DateTime.january, 13),
      end: DateTime(2017, DateTime.january, 15),
    );
    firstDate = DateTime(2017, DateTime.january, 12);
    lastDate = DateTime(2017, DateTime.january, 16);
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      // Earlier than firstDate. Should be ignored.
      await tester.tap(find.text('10'));
      // Later than lastDate. Should be ignored.
      await tester.tap(find.text('20'));
      await tester.tap(find.text('SAVE'));
      // We should still be on the initial date.
      expect(await range, initialDateRange);
    });
  });

  testWidgets('Can switch from calendar to input entry mode', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  testWidgets('Can switch from input to calendar entry mode', (WidgetTester tester) async {
    initialEntryMode = DatePickerEntryMode.input;
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('Can not switch out of calendarOnly mode', (WidgetTester tester) async {
    initialEntryMode = DatePickerEntryMode.calendarOnly;
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });

  testWidgets('Can not switch out of inputOnly mode', (WidgetTester tester) async {
    initialEntryMode = DatePickerEntryMode.inputOnly;
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });
  });

  testWidgets('Input only mode should validate date', (WidgetTester tester) async {
    initialEntryMode = DatePickerEntryMode.inputOnly;
    errorInvalidText = 'oops';
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.enterText(find.byType(TextField).at(0), '08/08/2014');
      await tester.enterText(find.byType(TextField).at(1), '08/08/2014');
      expect(find.text(errorInvalidText!), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(errorInvalidText!), findsNWidgets(2));
    });
  });

  testWidgets('Switching to input mode keeps selected date', (WidgetTester tester) async {
    await preparePicker(tester, (Future<DateTimeRange?> range) async {
      await tester.tap(find.text('12').first);
      await tester.tap(find.text('14').first);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      expect(await range, DateTimeRange(
        start: DateTime(2016, DateTime.january, 12),
        end: DateTime(2016, DateTime.january, 14),
      ));
    });
  });

  group('Toggle from input entry mode validates dates', () {
    setUp(() {
      initialEntryMode = DatePickerEntryMode.input;
    });

    testWidgets('Invalid start date', (WidgetTester tester) async {
      // Invalid start date should have neither a start nor end date selected in
      // calendar mode
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/1918');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2016');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        expect(find.text('Start Date'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
      });
    });

    testWidgets('Invalid end date', (WidgetTester tester) async {
      // Invalid end date should only have a start date selected
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/24/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2050');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        expect(find.text('Dec 24'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
      });
    });

    testWidgets('Invalid range', (WidgetTester tester) async {
      // Start date after end date should just use the start date
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/24/2016');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        expect(find.text('Dec 25'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
      });
    });
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
                     showDateRangePicker(
                       context: context,
                       firstDate:DateTime(2001, DateTime.january, 1),
                       lastDate: DateTime(2031, DateTime.december, 31),
                       builder: (BuildContext context, Widget? child) {
                         return Directionality(
                           textDirection: textDirection,
                           child: child ?? const SizedBox(),
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

    Future<void> showOkCancelDialog(TextDirection textDirection) async {
      await tester.pumpWidget(buildFrame(textDirection));
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
    }

    Future<void> dismissOkCancelDialog() async {
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
    }

    await showOkCancelDialog(TextDirection.ltr);
    expect(tester.getBottomRight(find.text('OK')).dx, 622);
    expect(tester.getBottomLeft(find.text('OK')).dx, 594);
    expect(tester.getBottomRight(find.text('CANCEL')).dx, 560);
    await dismissOkCancelDialog();

    await showOkCancelDialog(TextDirection.rtl);
    expect(tester.getBottomRight(find.text('OK')).dx, 206);
    expect(tester.getBottomLeft(find.text('OK')).dx, 178);
    expect(tester.getBottomRight(find.text('CANCEL')).dx, 324);
    await dismissOkCancelDialog();
  });

  group('Haptic feedback', () {
    const Duration hapticFeedbackInterval = Duration(milliseconds: 10);
    late FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
      initialDateRange = DateTimeRange(
        start: DateTime(2017, DateTime.january, 15),
        end: DateTime(2017, DateTime.january, 17),
      );
      firstDate = DateTime(2017, DateTime.january, 10);
      lastDate = DateTime(2018, DateTime.january, 20);
    });

    tearDown(() {
      feedback.dispose();
    });

    testWidgets('Selecting dates vibrates', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.tap(find.text('10').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 1);
        await tester.tap(find.text('12').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 2);
        await tester.tap(find.text('14').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 3);
      });
    });

    testWidgets('Tapping unselectable date does not vibrate', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.tap(find.text('8').first);
        await tester.pump(hapticFeedbackInterval);
        expect(feedback.hapticCount, 0);
      });
    });
  });

  group('Keyboard navigation', () {
    testWidgets('Can toggle to calendar entry mode', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        expect(find.byType(TextField), findsNothing);
        // Navigate to the entry toggle button and activate it
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        // Should be in the input mode
        expect(find.byType(TextField), findsNWidgets(2));
      });
    });

    testWidgets('Can navigate date grid with arrow keys', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        // Navigate to the grid
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Navigate from Jan 15 to Jan 18 with arrow keys
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Activate it to select the beginning of the range
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate to Jan 29
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Activate it to select the end of the range
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate out of the grid and to the OK button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        // Activate OK
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Should have selected Jan 18 - Jan 29
        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.january, 18),
          end: DateTime(2016, DateTime.january, 29),
        ));
      });
    });

    testWidgets('Navigating with arrow keys scrolls as needed', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        // Jan and Feb headers should be showing, but no March
        expect(find.text('January 2016'), findsOneWidget);
        expect(find.text('February 2016'), findsOneWidget);
        expect(find.text('March 2016'), findsNothing);

        // Navigate to the grid
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        // Navigate from Jan 15 to Jan 18 with arrow keys
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // Activate it to select the beginning of the range
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate to Mar 17
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Jan should have scrolled off, Mar should be visible
        expect(find.text('January 2016'), findsNothing);
        expect(find.text('February 2016'), findsOneWidget);
        expect(find.text('March 2016'), findsOneWidget);

        // Activate it to select the end of the range
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate out of the grid and to the OK button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        // Activate OK
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Should have selected Jan 18 - Mar 17
        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.january, 18),
          end: DateTime(2016, DateTime.march, 17),
        ));
      });
    });

    testWidgets('RTL text direction reverses the horizontal arrow key navigation', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        // Navigate to the grid
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        // Navigate from Jan 15 to 19 with arrow keys
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Activate it
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate to Jan 21
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Activate it
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Navigate out of the grid and to the OK button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        // Activate OK
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Should have selected Jan 19 - Mar 21
        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.january, 19),
          end: DateTime(2016, DateTime.january, 21),
        ));
      }, textDirection: TextDirection.rtl);
    });
  });

  group('Input mode', () {
    setUp(() {
      firstDate = DateTime(2015, DateTime.january, 1);
      lastDate = DateTime(2017, DateTime.december, 31);
      initialDateRange = DateTimeRange(
        start: DateTime(2017, DateTime.january, 15),
        end: DateTime(2017, DateTime.january, 17),
      );
      initialEntryMode = DatePickerEntryMode.input;
    });

    testWidgets('Initial entry mode is used', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        expect(find.byType(TextField), findsNWidgets(2));
      });
    });

    testWidgets('All custom strings are used', (WidgetTester tester) async {
      initialDateRange = null;
      cancelText = 'nope';
      confirmText = 'yep';
      fieldStartHintText = 'hint1';
      fieldEndHintText = 'hint2';
      fieldStartLabelText = 'label1';
      fieldEndLabelText = 'label2';
      helpText = 'help';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        expect(find.text(cancelText!), findsOneWidget);
        expect(find.text(confirmText!), findsOneWidget);
        expect(find.text(fieldStartHintText!), findsOneWidget);
        expect(find.text(fieldEndHintText!), findsOneWidget);
        expect(find.text(fieldStartLabelText!), findsOneWidget);
        expect(find.text(fieldEndLabelText!), findsOneWidget);
        expect(find.text(helpText!), findsOneWidget);
      });
    });

    testWidgets('Initial date is the default', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.tap(find.text('OK'));
        expect(await range, DateTimeRange(
          start: DateTime(2017, DateTime.january, 15),
          end: DateTime(2017, DateTime.january, 17),
        ));
      });
    });

    testWidgets('Can toggle to calendar entry mode', (WidgetTester tester) async {
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        expect(find.byType(TextField), findsNWidgets(2));
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
      });
    });

    testWidgets('Toggle to calendar mode keeps selected date', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/27/2016');
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAVE'));

        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.december, 25),
          end: DateTime(2016, DateTime.december, 27),
        ));
      });
    });

    testWidgets('Entered text returns range', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/27/2016');
        await tester.tap(find.text('OK'));

        expect(await range, DateTimeRange(
          start: DateTime(2016, DateTime.december, 25),
          end: DateTime(2016, DateTime.december, 27),
        ));
      });
    });

    testWidgets('Too short entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorFormatText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/25');
        await tester.enterText(find.byType(TextField).at(1), '12/25');
        expect(find.text(errorFormatText!), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText!), findsNWidgets(2));
      });
    });

    testWidgets('Bad format entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorFormatText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '20202014');
        await tester.enterText(find.byType(TextField).at(1), '20212014');
        expect(find.text(errorFormatText!), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorFormatText!), findsNWidgets(2));
      });
    });

    testWidgets('Invalid entered text shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '08/08/2014');
        await tester.enterText(find.byType(TextField).at(1), '08/08/2014');
        expect(find.text(errorInvalidText!), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidText!), findsNWidgets(2));
      });
    });

    testWidgets('End before start date shows error', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidRangeText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2016');
        expect(find.text(errorInvalidRangeText!), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidRangeText!), findsOneWidget);
      });
    });

    testWidgets('Error text only displayed for invalid date', (WidgetTester tester) async {
      initialDateRange = null;
      errorInvalidText = 'oops';
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '01/01/2018');
        expect(find.text(errorInvalidText!), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text(errorInvalidText!), findsOneWidget);
      });
    });

    testWidgets('End before start date does not get passed to calendar mode', (WidgetTester tester) async {
      initialDateRange = null;
      await preparePicker(tester, (Future<DateTimeRange?> range) async {
        await tester.enterText(find.byType(TextField).at(0), '12/27/2016');
        await tester.enterText(find.byType(TextField).at(1), '12/25/2016');

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Save button should be disabled, so dialog should still be up
        // with the first date selected, but no end date
        expect(find.text('Dec 27'), findsOneWidget);
        expect(find.text('End Date'), findsOneWidget);
      });
    });

    testWidgets('InputDecorationTheme is honored', (WidgetTester tester) async {

      // Given a custom paint for an input decoration, extract the border and
      // fill color and test them against the expected values.
      void _testInputDecorator(CustomPaint decoratorPaint, InputBorder expectedBorder, Color expectedContainerColor) {
        final dynamic/*_InputBorderPainter*/ inputBorderPainter = decoratorPaint.foregroundPainter;
        // ignore: avoid_dynamic_calls
        final dynamic/*_InputBorderTween*/ inputBorderTween = inputBorderPainter.border;
        // ignore: avoid_dynamic_calls
        final Animation<double> animation = inputBorderPainter.borderAnimation as Animation<double>;
        // ignore: avoid_dynamic_calls
        final InputBorder actualBorder = inputBorderTween.evaluate(animation) as InputBorder;
        // ignore: avoid_dynamic_calls
        final Color containerColor = inputBorderPainter.blendedColor as Color;

        expect(actualBorder, equals(expectedBorder));
        expect(containerColor, equals(expectedContainerColor));
      }

      late BuildContext buttonContext;
      const InputBorder border = InputBorder.none;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light().copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: border,
          ),
        ),
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  buttonContext = context;
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Go'));
      expect(buttonContext, isNotNull);

      showDateRangePicker(
        context: buttonContext,
        initialDateRange: initialDateRange,
        firstDate: firstDate,
        lastDate: lastDate,
        initialEntryMode: DatePickerEntryMode.input,
      );
      await tester.pumpAndSettle();

      final Finder borderContainers = find.descendant(
        of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_BorderContainer'),
        matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
      );

      // Test the start date text field
      _testInputDecorator(tester.widget(borderContainers.first), border, Colors.transparent);

      // Test the end date text field
      _testInputDecorator(tester.widget(borderContainers.last), border, Colors.transparent);
    });
  });

  testWidgets('DatePickerDialog is state restorable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        restorationScopeId: 'app',
        home: _RestorableDateRangePickerDialogTestWidget(),
      ),
    );

    // The date range picker should be closed.
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text('1/1/2021 to 5/1/2021'), findsOneWidget);

    // Open the date range picker.
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);

    final TestRestorationData restorationData = await tester.getRestorationData();
    await tester.restartAndRestore();

    // The date range picker should be open after restoring.
    expect(find.byType(DateRangePickerDialog), findsOneWidget);

    // Close the date range picker.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // The date range picker should be closed, the text value updated to the
    // newly selected date.
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text('1/1/2021 to 5/1/2021'), findsOneWidget);

    // The date range picker should be open after restoring.
    await tester.restoreFrom(restorationData);
    expect(find.byType(DateRangePickerDialog), findsOneWidget);

    // // Select a different date and close the date range picker.
    await tester.tap(find.text('12').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();

    // Restart after the new selection. It should remain selected.
    await tester.restartAndRestore();

    // Close the date range picker.
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    // The date range picker should be closed, the text value updated to the
    // newly selected date.
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text('12/1/2021 to 14/1/2021'), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/33615

  testWidgets('DateRangePickerDialog state restoration - DatePickerEntryMode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        restorationScopeId: 'app',
        home: _RestorableDateRangePickerDialogTestWidget(
          datePickerEntryMode: DatePickerEntryMode.calendarOnly,
        ),
      ),
    );

    // The date range picker should be closed.
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text('1/1/2021 to 5/1/2021'), findsOneWidget);

    // Open the date range picker.
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);

    // Only in calendar mode and cannot switch out.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);

    final TestRestorationData restorationData = await tester.getRestorationData();
    await tester.restartAndRestore();

    // The date range picker should be open after restoring.
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    // Only in calendar mode and cannot switch out.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);

    // Tap on the barrier.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // The date range picker should be closed, the text value should be the same
    // as before.
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.text('1/1/2021 to 5/1/2021'), findsOneWidget);

    // The date range picker should be open after restoring.
    await tester.restoreFrom(restorationData);
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    // Only in calendar mode and cannot switch out.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/33615
}

class _RestorableDateRangePickerDialogTestWidget extends StatefulWidget {
  const _RestorableDateRangePickerDialogTestWidget({
    Key? key,
    this.datePickerEntryMode = DatePickerEntryMode.calendar,
  }) : super(key: key);

  final DatePickerEntryMode datePickerEntryMode;

  @override
  _RestorableDateRangePickerDialogTestWidgetState createState() => _RestorableDateRangePickerDialogTestWidgetState();
}

class _RestorableDateRangePickerDialogTestWidgetState extends State<_RestorableDateRangePickerDialogTestWidget> with RestorationMixin {
  @override
  String? get restorationId => 'scaffold_state';

  final RestorableDateTimeN _startDate = RestorableDateTimeN(DateTime(2021, 1, 1));
  final RestorableDateTimeN _endDate = RestorableDateTimeN(DateTime(2021, 1, 5));
  late final RestorableRouteFuture<DateTimeRange?> _restorableDateRangePickerRouteFuture = RestorableRouteFuture<DateTimeRange?>(
    onComplete: _selectDateRange,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _dateRangePickerRoute,
        arguments: <String, dynamic>{
          'datePickerEntryMode': widget.datePickerEntryMode.index,
        },
      );
    },
  );

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_startDate, 'start_date');
    registerForRestoration(_endDate, 'end_date');
    registerForRestoration(_restorableDateRangePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDateRange(DateTimeRange? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _startDate.value = newSelectedDate.start;
        _endDate.value = newSelectedDate.end;
      });
    }
  }

  static Route<DateTimeRange?> _dateRangePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTimeRange?>(
      context: context,
      builder: (BuildContext context) {
        final Map<dynamic, dynamic> args = arguments! as Map<dynamic, dynamic>;
        return DateRangePickerDialog(
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.values[args['datePickerEntryMode'] as int],
          firstDate: DateTime(2021, 1, 1),
          currentDate: DateTime(2021, 1, 25),
          lastDate: DateTime(2022, 1, 1),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? startDateTime = _startDate.value;
    final DateTime? endDateTime = _endDate.value;
    // Example: "25/7/1994"
    final String startDateTimeString = '${startDateTime?.day}/${startDateTime?.month}/${startDateTime?.year}';
    final String endDateTimeString = '${endDateTime?.day}/${endDateTime?.month}/${endDateTime?.year}';
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                _restorableDateRangePickerRouteFuture.present();
              },
              child: const Text('X'),
            ),
            Text('$startDateTimeString to $endDateTimeString'),
          ],
        ),
      ),
    );
  }
}
