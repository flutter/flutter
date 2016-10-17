// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findsOneWidget', () {
    testWidgets('finds exactly one widget', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));
      expect(find.text('foo'), findsOneWidget);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      TestFailure failure;
      try {
        expect(find.text('foo', skipOffstage: false), findsOneWidget);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      String message = failure.message;
      expect(message, contains('Expected: exactly one matching node in the widget tree\n'));
      expect(message, contains('Actual: ?:<zero widgets with text "foo">\n'));
      expect(message, contains('Which: means none were found but one was expected\n'));
    });
  });

  group('findsNothing', () {
    testWidgets('finds no widgets', (WidgetTester tester) async {
      expect(find.text('foo'), findsNothing);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));

      TestFailure failure;
      try {
        expect(find.text('foo', skipOffstage: false), findsNothing);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      String message = failure.message;

      expect(message, contains('Expected: no matching nodes in the widget tree\n'));
      expect(message, contains('Actual: ?:<exactly one widget with text "foo": Text("foo")>\n'));
      expect(message, contains('Which: means one was found but none were expected\n'));
    });

    testWidgets('fails with a descriptive message when skipping', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));

      TestFailure failure;
      try {
        expect(find.text('foo'), findsNothing);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      String message = failure.message;

      expect(message, contains('Expected: no matching nodes in the widget tree\n'));
      expect(message, contains('Actual: ?:<exactly one widget with text "foo" (ignoring offstage widgets): Text("foo")>\n'));
      expect(message, contains('Which: means one was found but none were expected\n'));
    });

    testWidgets('pumping', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));
      int count;

      AnimationController test = new AnimationController(
        duration: const Duration(milliseconds: 5100),
        vsync: tester,
      );
      count = await tester.pumpUntilNoTransientCallbacks(const Duration(seconds: 1));
      expect(count, 0);

      test.forward(from: 0.0);
      count = await tester.pumpUntilNoTransientCallbacks(const Duration(seconds: 1));
      // 1 frame at t=0, starting the animation
      // 1 frame at t=1
      // 1 frame at t=2
      // 1 frame at t=3
      // 1 frame at t=4
      // 1 frame at t=5
      // 1 frame at t=6, ending the animation
      expect(count, 7);

      test.forward(from: 0.0);
      await tester.pump(); // starts the animation
      count = await tester.pumpUntilNoTransientCallbacks(const Duration(seconds: 1));
      expect(count, 6);

      test.forward(from: 0.0);
      await tester.pump(); // starts the animation
      await tester.pump(); // has no effect
      count = await tester.pumpUntilNoTransientCallbacks(const Duration(seconds: 1));
      expect(count, 6);
    });
  });

  group('find.byElementPredicate', () {
    testWidgets('fails with a custom description in the message', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));

      String customDescription = 'custom description';
      TestFailure failure;
      try {
        expect(find.byElementPredicate((_) => false, description: customDescription), findsOneWidget);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(failure.message, contains('Actual: ?:<zero widgets with $customDescription'));
    });
  });

  group('find.byWidgetPredicate', () {
    testWidgets('fails with a custom description in the message', (WidgetTester tester) async {
      await tester.pumpWidget(new Text('foo'));

      String customDescription = 'custom description';
      TestFailure failure;
      try {
        expect(find.byWidgetPredicate((_) => false, description: customDescription), findsOneWidget);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(failure.message, contains('Actual: ?:<zero widgets with $customDescription'));
    });
  });
}
