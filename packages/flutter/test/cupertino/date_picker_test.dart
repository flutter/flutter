// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Countdown timer picker', () {
    testWidgets('onTimerDurationChanged is not null', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoCountdownTimerPicker(onTimerDurationChanged: null);
        },
        throwsAssertionError,
      );
    });

    testWidgets('initialTimerDuration falls within limit', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            initialTimerDuration: Duration(days: 1),
          );
        },
        throwsAssertionError,
      );

      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            initialTimerDuration: Duration(seconds: -1),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('minuteInterval is positive and is a factor of 60', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            minuteInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
            () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            minuteInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            minuteInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('secondInterval is positive and is a factor of 60', (WidgetTester tester) async {
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
        () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('secondInterval is positive and is a factor of 60', (WidgetTester tester) async {
      expect(
            () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: 0,
          );
        },
        throwsAssertionError,
      );
      expect(
            () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: -1,
          );
        },
        throwsAssertionError,
      );
      expect(
            () {
          new CupertinoCountdownTimerPicker(
            onTimerDurationChanged: (_) {},
            secondInterval: 7,
          );
        },
        throwsAssertionError,
      );
    });

    // Test for text direction.
//    testWidgets('column order depends on text direction', (WidgetTester tester) async {
//      await tester.pumpWidget(
//        new Directionality(
//          textDirection: TextDirection.ltr,
//          child: new CupertinoCountdownTimerPicker(
//            onTimerDurationChanged: (_) {},
//            initialTimerDuration: Duration(hours: 0, minutes: 1, seconds: 2),
//          ),
//        ),
//      );
//
//      // The texts that appear
//      final List<String> texts = <String>['0','hours','1','min','2','sec'];
//
//      Offset lastOffset = tester.getTopLeft(
//          find.widgetWithText(Container, texts[0]));
//
//      for (int i = 1; i < texts.length; i++) {
//        expect(tester.getTopLeft(find.widgetWithText(Container, texts[i])) > lastOffset, true);
//        lastOffset = tester.getTopLeft(find.widgetWithText(Container, texts[i]));
//      }
//    });

    // Test for width fixed.
  });
}