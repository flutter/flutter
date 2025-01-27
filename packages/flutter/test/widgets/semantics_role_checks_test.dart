// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All semantics roles has checks', () {
    expect(SemanticsRole.values.toSet(), DebugSemanticsRoleChecks.kChecks.keys.toSet());
  });

  group('tab', () {
    testWidgets('failure case, empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(role: SemanticsRole.tab, child: const Text('a tab')),
        ),
      );
      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('failure case, no tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            role: SemanticsRole.tab,
            enabled: true,
            selected: false,
            child: const Text('a tab'),
          ),
        ),
      );
      expect(tester.takeException(), isFlutterError);
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
      expect(tester.takeException(), isFlutterError);
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
      expect(tester.takeException(), isFlutterError);
    });
  });
}
