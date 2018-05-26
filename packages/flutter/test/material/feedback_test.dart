// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main () {
  const Duration kWaitDuration = const Duration(seconds: 1);

  FeedbackTester feedback;

  setUp(() {
    feedback = new FeedbackTester();
  });

  tearDown(() {
    feedback?.dispose();
  });

  group('Feedback on Android', () {

    testWidgets('forTap', (WidgetTester tester) async {
      await tester.pumpWidget(new TestWidget(
        tapHandler: (BuildContext context) {
          return () => Feedback.forTap(context);
        },
      ));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 1);
    });

    testWidgets('forTap Wrapper', (WidgetTester tester) async {
      int callbackCount = 0;
      final VoidCallback callback = () {
        callbackCount++;
      };

      await tester.pumpWidget(new TestWidget(
        tapHandler: (BuildContext context) {
          return Feedback.wrapForTap(callback, context);
        },
      ));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);
      expect(callbackCount, 0);

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 1);
      expect(callbackCount, 1);
    });

    testWidgets('forLongPress', (WidgetTester tester) async {
      await tester.pumpWidget(new TestWidget(
        longPressHandler: (BuildContext context) {
          return () => Feedback.forLongPress(context);
        },
      ));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);

      await tester.longPress(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 1);
      expect(feedback.clickSoundCount, 0);
    });

    testWidgets('forLongPress Wrapper', (WidgetTester tester) async {
      int callbackCount = 0;
      final VoidCallback callback = () {
        callbackCount++;
      };

      await tester.pumpWidget(new TestWidget(
        longPressHandler: (BuildContext context) {
          return Feedback.wrapForLongPress(callback, context);
        },
      ));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);
      expect(callbackCount, 0);

      await tester.longPress(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 1);
      expect(feedback.clickSoundCount, 0);
      expect(callbackCount, 1);
    });

  });

  group('Feedback on iOS', () {
    testWidgets('forTap', (WidgetTester tester) async {
      await tester.pumpWidget(new Theme(
        data: new ThemeData(platform: TargetPlatform.iOS),
        child: new TestWidget(
          tapHandler: (BuildContext context) {
            return () => Feedback.forTap(context);
          },
        ),
      ));

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);
    });

    testWidgets('forLongPress', (WidgetTester tester) async {
      await tester.pumpWidget(new Theme(
        data: new ThemeData(platform: TargetPlatform.iOS),
        child: new TestWidget(
          longPressHandler: (BuildContext context) {
            return () => Feedback.forLongPress(context);
          },
        ),
      ));

      await tester.longPress(find.text('X'));
      await tester.pumpAndSettle(kWaitDuration);
      expect(feedback.hapticCount, 0);
      expect(feedback.clickSoundCount, 0);
    });
  });
}

class TestWidget extends StatelessWidget {

  const TestWidget({
    this.tapHandler: nullHandler,
    this.longPressHandler: nullHandler,
  });

  final HandlerCreator tapHandler;
  final HandlerCreator longPressHandler;

  static VoidCallback nullHandler(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
        onTap: tapHandler(context),
        onLongPress: longPressHandler(context),
        child: const Text('X', textDirection: TextDirection.ltr),
    );
  }
}

typedef VoidCallback HandlerCreator(BuildContext context);
