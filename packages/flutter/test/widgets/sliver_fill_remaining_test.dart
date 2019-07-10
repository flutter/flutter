// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverFillRemaining - no siblings', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverFillRemaining(child: Container()),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(50.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(-100.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));

    controller.jumpTo(0.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(600.0));
  });

  testWidgets('SliverFillRemaining - one sibling', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
            SliverFillRemaining(child: Container()),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(500.0));

    controller.jumpTo(50.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(550.0));

    controller.jumpTo(-100.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(400.0)); // (!)

    controller.jumpTo(0.0);
    await tester.pump();
    expect(tester.renderObject<RenderBox>(find.byType(Container)).size.height, equals(500.0));
  });

  testWidgets('SliverFillRemaining does not extend past viewport.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                color: Colors.red,
                height: 150.0,
              ),
            ),
            SliverFillRemaining(
              child: Container(color: Colors.white),
              hasScrollBody: false,
            ),
          ],
        ),
      ),
    );
    expect(controller.offset, 0.0);
    expect(find.byType(Container), findsNWidgets(2));
    controller.jumpTo(150.0);
    await tester.pumpAndSettle();
    expect(controller.offset, 0.0);
    expect(find.byType(Container), findsNWidgets(2));
  });

  testWidgets('SliverFillRemaining scrolls beyond viewport by default.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                color: Colors.red,
                height: 150.0,
              ),
            ),
            SliverFillRemaining(
              child: Container(color: Colors.white),
            ),
          ],
        ),
      ),
    );
    expect(controller.offset, 0.0);
    expect(find.byType(Container), findsNWidgets(2));
    controller.jumpTo(150.0);
    await tester.pumpAndSettle();
    expect(controller.offset, 150.0);
    expect(find.byType(Container), findsOneWidget);
  });
}
