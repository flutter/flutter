// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandable', () {
    testWidgets('success case, no actions', (WidgetTester tester) async {
      await tester.pumpWidget(Semantics(expanded: false, child: const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('success case, collapsed with expand action', (WidgetTester tester) async {
      await tester.pumpWidget(Semantics(expanded: false, onExpand: () {}, child: const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('success case, expanded with collapse action', (WidgetTester tester) async {
      await tester.pumpWidget(
        Semantics(expanded: true, onCollapse: () {}, child: const SizedBox()),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure case, both expand and collapse actions are set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Semantics(expanded: false, onExpand: () {}, onCollapse: () {}, child: const SizedBox()),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(
        error.message,
        'An expandable node cannot have both expand and collapse actions set at the same time.',
      );
    });

    testWidgets('failure case, expanded with expand action', (WidgetTester tester) async {
      await tester.pumpWidget(Semantics(expanded: true, onExpand: () {}, child: const SizedBox()));
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'An expanded node cannot have an expand action.');
    });

    testWidgets('failure case, collapsed with collapse action', (WidgetTester tester) async {
      await tester.pumpWidget(
        Semantics(expanded: false, onCollapse: () {}, child: const SizedBox()),
      );
      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(error.message, 'A collapsed node cannot have a collapse action.');
    });
  });
}
