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

  testWidgets('FlexibleSpaceBarSettings works while public', (WidgetTester tester) async {
    const double maxExtent = 300.0;

    final FlexibleSpaceBarSettings customSettings =
    FlexibleSpaceBar.createSettings(
      currentExtent: maxExtent,
      minExtent: 100,
      maxExtent: maxExtent,
      toolbarOpacity: .5,
      child: AppBar(
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('X'),
          background:  Text('X2'),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(
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
      ),
    );

    final RenderBox renderBox = tester.renderObject(find.byType(Positioned));
    expect(renderBox.size.height, maxExtent);
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
