// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/sliver_persistent_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      '_SliverScrollingPersistentHeader should update stretchConfiguration',
      (final WidgetTester tester) async {
    for (final double stretchTriggerOffset in <double>[10.0, 20.0]) {
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              delegate: TestDelegate(
                stretchConfiguration: OverScrollHeaderStretchConfiguration(
                  stretchTriggerOffset: stretchTriggerOffset,
                ),
              ),
            )
          ],
        ),
      ));
    }

    expect(
        tester.allWidgets.where((final Widget w) =>
            w.runtimeType.toString() == '_SliverScrollingPersistentHeader'),
        isNotEmpty);

    final RenderSliverScrollingPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverScrollingPersistentHeader>()
        .first;
    expect(render.stretchConfiguration?.stretchTriggerOffset, 20);
  });

  testWidgets(
      '_SliverPinnedPersistentHeader should update stretchConfiguration',
      (final WidgetTester tester) async {
    for (final double stretchTriggerOffset in <double>[10.0, 20.0]) {
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: TestDelegate(
                stretchConfiguration: OverScrollHeaderStretchConfiguration(
                  stretchTriggerOffset: stretchTriggerOffset,
                ),
              ),
            )
          ],
        ),
      ));
    }

    expect(
        tester.allWidgets.where((final Widget w) =>
            w.runtimeType.toString() == '_SliverPinnedPersistentHeader'),
        isNotEmpty);

    final RenderSliverPinnedPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverPinnedPersistentHeader>()
        .first;
    expect(render.stretchConfiguration?.stretchTriggerOffset, 20);
  });

  testWidgets(
      '_SliverPinnedPersistentHeader should update showOnScreenConfiguration',
      (final WidgetTester tester) async {
    for (final double maxShowOnScreenExtent in <double>[1000, 2000]) {
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: TestDelegate(
                showOnScreenConfiguration:
                    PersistentHeaderShowOnScreenConfiguration(
                        maxShowOnScreenExtent: maxShowOnScreenExtent),
              ),
            )
          ],
        ),
      ));
    }

    expect(
        tester.allWidgets.where((final Widget w) =>
            w.runtimeType.toString() == '_SliverPinnedPersistentHeader'),
        isNotEmpty);

    final RenderSliverPinnedPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverPinnedPersistentHeader>()
        .first;
    expect(render.showOnScreenConfiguration?.maxShowOnScreenExtent, 2000);
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  TestDelegate({this.stretchConfiguration, this.showOnScreenConfiguration});

  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 200.0;

  @override
  Widget build(
      final BuildContext context, final double shrinkOffset, final bool overlapsContent) {
    return Container(height: maxExtent);
  }

  @override
  bool shouldRebuild(final TestDelegate oldDelegate) => false;

  @override
  final OverScrollHeaderStretchConfiguration? stretchConfiguration;
  @override
  final PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;
}
