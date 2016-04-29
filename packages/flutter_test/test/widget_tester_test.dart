// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  group('findsOneWidget', () {
    testWidgets('finds exactly one widget', (WidgetTester tester) {
      tester.pumpWidget(new Text('foo'));
      expect(find.text('foo'), findsOneWidget);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) {
      TestFailure failure;
      try {
        expect(find.text('foo'), findsOneWidget);
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
    testWidgets('finds no widgets', (WidgetTester tester) {
      expect(find.text('foo'), findsNothing);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) {
      tester.pumpWidget(new Text('foo'));

      TestFailure failure;
      try {
        expect(find.text('foo'), findsNothing);
      } catch(e) {
        failure = e;
      }

      expect(failure, isNotNull);
      String message = failure.message;

      expect(message, contains('Expected: no matching nodes in the widget tree\n'));
      expect(message, contains('Actual: ?:<exactly one widget with text "foo": Text("foo")>\n'));
      expect(message, contains('Which: means one was found but none were expected\n'));
    });
  });

}
