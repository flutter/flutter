// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlexibleSpaceBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('X')
            )
          )
        )
      )
    );

    final Finder title = find.text('X');
    Offset center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.dx, lessThan(400.0 - size.width / 2.0));

    // Clear the widget tree to avoid animating between Android and iOS.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('X')
            )
          )
        )
      )
    );

    center = tester.getCenter(title);
    size = tester.getSize(title);
    expect(center.dx, greaterThan(400.0 - size.width / 2.0));
    expect(center.dx, lessThan(400.0 + size.width / 2.0));
  });

  testWidgets('FlexibleSpaceBarSettings provides settings to a FlexibleSpaceBar', (WidgetTester tester) async {
    const double minExtent = 100.0;
    const double initExtent = 200.0;
    const double maxExtent = 300.0;
    const double alpha = 0.5;

    final FlexibleSpaceBarSettings customSettings = FlexibleSpaceBar.createSettings(
      currentExtent: initExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      toolbarOpacity: alpha,
      child: AppBar(
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('title'),
          background:  Text('X2'),
          collapseMode: CollapseMode.pin,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            primary: true,
            slivers: <Widget>[
              SliverPersistentHeader(
                floating: true,
                pinned: true,
                delegate: TestDelegate(settings: customSettings),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 1200.0,
                  color: Colors.orange[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox clipRect = tester.renderObject(find.byType(ClipRect).first);
    final Transform transform = tester.firstWidget(find.byType(Transform));

    // The current (200) is half way between the min (100) and max (300) and the
    // lerp values used to calculate the scale are 1 and 1.5, so we check for 1.25.
    expect(transform.transform.getMaxScaleOnAxis(), 1.25);

    // The space bar rect always starts fully expanded.
    expect(clipRect.size.height, maxExtent);

    final Element actionTextBox = tester.element(find.text('title'));
    final Text textWidget = actionTextBox.widget;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(actionTextBox);

    TextStyle effectiveStyle = textWidget.style;
    effectiveStyle = defaultTextStyle.style.merge(textWidget.style);
    expect(effectiveStyle.color.alpha, 128); // Which is alpha of .5

    // We drag up to fully collapse the space bar.
    await tester.drag(find.byType(Container).first, const Offset(0, -400.0));
    await tester.pumpAndSettle();

    expect(clipRect.size.height, minExtent);
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {

  const TestDelegate({
    this.settings,
  });

  final FlexibleSpaceBarSettings settings;

  @override
  double get maxExtent => settings.maxExtent;

  @override
  double get minExtent => settings.minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return settings;
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}
