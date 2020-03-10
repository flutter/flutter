// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  group('Available semantic scroll actions', () {
    // Regression tests for https://github.com/flutter/flutter/issues/52032.
    testWidgets('forward vertical', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 150,
                child: Text('Tile $index'),
              );
            },
          ),
        ),
      );

      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp]));

      // Jump to the end.
      controller.jumpTo(10 * 150.0);
      await tester.pumpAndSettle();
      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollDown]));

      semantics.dispose();
    });

    testWidgets('reverse vertical', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            reverse: true,
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 150,
                child: Text('Tile $index'),
              );
            },
          ),
        ),
      );

      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollDown]));

      // Jump to the end.
      controller.jumpTo(10 * 150.0);
      await tester.pumpAndSettle();
      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp]));

      semantics.dispose();
    });

    testWidgets('forward horizontal', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 150,
                child: Text('Tile $index'),
              );
            },
          ),
        ),
      );

      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollLeft]));

      // Jump to the end.
      controller.jumpTo(10 * 150.0);
      await tester.pumpAndSettle();
      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollRight]));

      semantics.dispose();
    });

    testWidgets('reverse horizontal', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 150,
                child: Text('Tile $index'),
              );
            },
          ),
        ),
      );

      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollRight]));

      // Jump to the end.
      controller.jumpTo(10 * 150.0);
      await tester.pumpAndSettle();
      expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollLeft]));

      semantics.dispose();
    });
  });
}
