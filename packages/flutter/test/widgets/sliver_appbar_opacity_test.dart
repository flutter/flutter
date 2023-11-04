// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('!pinned && !floating && !bottom ==> fade opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: false,
          floating: false,
          bottom: false,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });

  testWidgetsWithLeakTracking('!pinned && !floating && bottom ==> fade opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: false,
          floating: false,
          bottom: true,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });

  testWidgetsWithLeakTracking('!pinned && floating && !bottom ==> fade opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: false,
          floating: true,
          bottom: false,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });

  testWidgetsWithLeakTracking('!pinned && floating && bottom ==> fade opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: false,
          floating: true,
          bottom: true,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });

  testWidgetsWithLeakTracking('pinned && !floating && !bottom ==> 1.0 opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: true,
          floating: false,
          bottom: false,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 1.0);
  });

  testWidgetsWithLeakTracking('pinned && !floating && bottom ==> 1.0 opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: true,
          floating: false,
          bottom: true,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 1.0);
  });

  testWidgetsWithLeakTracking('pinned && floating && !bottom ==> 1.0 opacity', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/25000.

    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        _TestWidget(
          pinned: true,
          floating: true,
          bottom: false,
          controller: controller,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 1.0);
  });

  testWidgetsWithLeakTracking('pinned && floating && bottom && extraToolbarHeight == 0.0 ==> fade opacity', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/25993.

    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _TestWidget(
        pinned: true,
        floating: true,
        bottom: true,
        controller: controller,
      ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });

  testWidgetsWithLeakTracking('pinned && floating && bottom && extraToolbarHeight != 0.0 ==> 1.0 opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _TestWidget(
        pinned: true,
        floating: true,
        bottom: true,
        collapsedHeight: 100.0,
        controller: controller,
      ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 1.0);
  });

  testWidgetsWithLeakTracking('!pinned && !floating && !bottom && extraToolbarHeight != 0.0 ==> fade opacity', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    const double collapsedHeight = 100.0;
    await tester.pumpWidget(
        _TestWidget(
          pinned: false,
          floating: false,
          bottom: false,
          controller: controller,
          collapsedHeight: collapsedHeight,
        ),
    );

    final RenderParagraph render = tester.renderObject(find.text('Hallo Welt!!1'));
    expect(render.text.style!.color!.opacity, 1.0);

    controller.jumpTo(collapsedHeight);
    await tester.pumpAndSettle();
    expect(render.text.style!.color!.opacity, 0.0);
  });
}

class _TestWidget extends StatelessWidget {

  const _TestWidget({
    required this.pinned,
    required this.floating,
    required this.bottom,
    this.controller,
    this.collapsedHeight,
  });

  final bool pinned;
  final bool floating;
  final bool bottom;
  final ScrollController? controller;
  final double? collapsedHeight;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CustomScrollView(
        controller: controller,
        slivers: <Widget>[
          SliverAppBar(
            pinned: pinned,
            floating: floating,
            expandedHeight: 120.0,
            collapsedHeight: collapsedHeight,
            title: const Text('Hallo Welt!!1'),
            bottom: !bottom ? null :  PreferredSize(
              preferredSize: const Size.fromHeight(35.0),
              child: Container(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(List<Widget>.generate(20, (int i) {
              return SizedBox(
                height: 100.0,
                child: Text('Tile $i'),
              );
            })),
          ),
        ],
      ),
    );
  }

}
