// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

void main() {
  testWidgets('InkWell gestures control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new InkWell(
          onTap: () {
            log.add('tap');
          },
          onDoubleTap: () {
            log.add('double-tap');
          },
          onLongPress: () {
            log.add('long-press');
          },
        ),
      ),
    ));

    await tester.tap(find.byType(InkWell), pointer: 1);

    expect(log, isEmpty);

    await tester.pump(const Duration(seconds: 1));

    expect(log, equals(<String>['tap']));
    log.clear();

    await tester.tap(find.byType(InkWell), pointer: 2);
    await tester.tap(find.byType(InkWell), pointer: 3);

    expect(log, equals(<String>['double-tap']));
    log.clear();

    await tester.longPress(find.byType(InkWell), pointer: 4);

    expect(log, equals(<String>['long-press']));
  });

  group('feedback', () {
    FeedbackTester feedback;

    setUp(() {
      feedback = new FeedbackTester();
    });

    testWidgets('enabled (default)', (WidgetTester tester) async {
      await tester.pumpWidget(new Material(
        child: new Center(
          child: new InkWell(
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);

      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 2);
      expect(feedback.hapticCount, 1);
    });

    testWidgets('disabled', (WidgetTester tester) async {
      await tester.pumpWidget(new Material(
        child: new Center(
          child: new InkWell(
            onTap: () {},
            onLongPress: () {},
            enableFeedback: false,
          ),
        ),
      ));
      await tester.tap(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);

      await tester.longPress(find.byType(InkWell), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });
  });
}
