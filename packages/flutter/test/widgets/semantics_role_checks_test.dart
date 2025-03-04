// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tab', () {
    testWidgets('failure case, empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(role: SemanticsRole.tab, child: const Text('a tab')),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'A tab needs selected states');
    });

    testWidgets('failure case, no tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(role: SemanticsRole.tab, selected: false, child: const Text('a tab')),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'A tab must have a tap action');
    });

    testWidgets('success case', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.tab,
            selected: false,
            onTap: () {},
            child: const Text('a tab'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('tabBar', () {
    testWidgets('failure case, empty child', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.tabBar,
            child: const ExcludeSemantics(child: Text('something')),
          ),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'a TabBar cannot be empty');
    });

    testWidgets('failure case, non tab child', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.tabBar,
            explicitChildNodes: true,
            child: Semantics(child: const Text('some child')),
          ),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'Children of TabBar must have the tab role');
    });

    testWidgets('Success case', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.tabBar,
            explicitChildNodes: true,
            child: Semantics(
              role: SemanticsRole.tab,
              selected: false,
              onTap: () {},
              child: const Text('some child'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('radioGroup', () {
    testWidgets('failure case, child is not mutually exclusive', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Semantics(
              checked: false,
              inMutuallyExclusiveGroup: false,
              child: const SizedBox.square(dimension: 1),
            ),
          ),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'Radio buttons in a radio group must be in a mutually exclusive group');
    });

    testWidgets('failure case, multiple checked children', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Column(
              children: <Widget>[
                Semantics(
                  checked: true,
                  inMutuallyExclusiveGroup: true,
                  child: const SizedBox.square(dimension: 1),
                ),
                Semantics(
                  checked: true,
                  inMutuallyExclusiveGroup: true,
                  child: const SizedBox.square(dimension: 1),
                ),
              ],
            ),
          ),
        ),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'Radio groups must not have multiple checked children');
    });

    testWidgets('error case, reports first error', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: 'Option A',
                  child: Semantics(checked: true, child: const SizedBox.square(dimension: 1)),
                ),
                Semantics(
                  label: 'Option B',
                  child: Semantics(
                    checked: true,
                    inMutuallyExclusiveGroup: true,
                    child: const SizedBox.square(dimension: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      // The widget tree has multiple errors. The validation walk should stop
      // on the first error.
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'Radio buttons in a radio group must be in a mutually exclusive group');
    });

    testWidgets('success case', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Column(
              children: <Widget>[
                Semantics(
                  checked: false,
                  inMutuallyExclusiveGroup: true,
                  child: const SizedBox.square(dimension: 1),
                ),
                Semantics(
                  checked: true,
                  inMutuallyExclusiveGroup: true,
                  child: const SizedBox.square(dimension: 1),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('success case, radio buttons with labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: 'Option A',
                  child: Semantics(
                    checked: false,
                    inMutuallyExclusiveGroup: true,
                    child: const SizedBox.square(dimension: 1),
                  ),
                ),
                Semantics(
                  label: 'Option B',
                  child: Semantics(
                    checked: true,
                    inMutuallyExclusiveGroup: true,
                    child: const SizedBox.square(dimension: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('success case, radio group with no checkable children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.radioGroup,
            explicitChildNodes: true,
            child: Semantics(toggled: true, child: const SizedBox.square(dimension: 1)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
