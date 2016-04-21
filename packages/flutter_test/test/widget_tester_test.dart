// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  group('hasWidget', () {
    test('succeeds', () {
      testWidgets((WidgetTester tester) {
        tester.pumpWidget(new Text('foo'));
        expect(tester, hasWidget(find.text('foo')));
      });
    });

    test('fails with a descriptive message', () {
      testWidgets((WidgetTester tester) {
        TestFailure failure;
        try {
          expect(tester, hasWidget(find.text('foo')));
        } catch(e) {
          failure = e;
        }

        expect(failure, isNotNull);
        String message = failure.message;
        expect(message, contains('Expected: [Finder for text "foo"] exists in the element tree'));
        expect(message, contains("Actual: <Instance of 'WidgetTester'>"));
        expect(message, contains('Which: Does not contain [Finder for text "foo"]'));
      });
    });
  });

  group('doesNotHaveWidget', () {
    test('succeeds', () {
      testWidgets((WidgetTester tester) {
        expect(tester, doesNotHaveWidget(find.text('foo')));
      });
    });

    test('fails with a descriptive message', () {
      testWidgets((WidgetTester tester) {
        tester.pumpWidget(new Text('foo'));

        TestFailure failure;
        try {
          expect(tester, doesNotHaveWidget(find.text('foo')));
        } catch(e) {
          failure = e;
        }

        expect(failure, isNotNull);
        String message = failure.message;
        expect(message, contains('Expected: [Finder for text "foo"] does not exist in the element tree'));
        expect(message, contains("Actual: <Instance of 'WidgetTester'>"));
        expect(message, contains('Which: Contains [Finder for text "foo"]'));
      });
    });
  });
}
