// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SliverAppBar stretch functions in CustomScrollView with AlwaysScrollableScrollPhysics on Android',
    (WidgetTester tester) async {
      var stretchTriggerCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  flexibleSpace: const FlexibleSpaceBar(title: Text('title')),
                  expandedHeight: 160.0,
                  onStretchTrigger: () async {
                    stretchTriggerCount++;
                  },
                ),
                SliverToBoxAdapter(child: Container(key: const Key('drag'), height: 10.0)),
              ],
            ),
          ),
        ),
      );

      final RenderSliverPinnedPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar),
      );
      expect(header.child!.size.height, equals(160.0));

      // Drag down to stretch the app bar
      final Offset target = tester.getCenter(find.byKey(const Key('drag')));
      final TestGesture gesture = await tester.startGesture(target);
      await gesture.moveBy(const Offset(0.0, 150.0));
      await tester.pump();

      // Verify that the app bar stretched and triggered the callback.
      expect(header.child!.size.height, greaterThan(160.0));
      expect(stretchTriggerCount, equals(1));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
