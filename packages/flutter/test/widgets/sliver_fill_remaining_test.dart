// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverFillRemaining - no siblings', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            new SliverFillRemaining(child: new Container()),
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
    final ScrollController controller = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            const SliverToBoxAdapter(child: const SizedBox(height: 100.0)),
            new SliverFillRemaining(child: new Container()),
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
}
