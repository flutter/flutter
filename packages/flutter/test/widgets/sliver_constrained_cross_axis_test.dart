// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverConstrainedCrossAxis basic test', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSliverConstrainedCrossAxis(extent: 50));

    final RenderBox box = tester.renderObject(find.byType(Container));
    expect(box.size.height, 100);
    expect(box.size.width, 50);
  });

  testWidgets('SliverConstrainedCrossAxis updates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSliverConstrainedCrossAxis(extent: 50));

    final RenderBox box1 = tester.renderObject(find.byType(Container));
    expect(box1.size.height, 100);
    expect(box1.size.width, 50);

    await tester.pumpWidget(_buildSliverConstrainedCrossAxis(extent: 80));

    final RenderBox box2 = tester.renderObject(find.byType(Container));
    expect(box2.size.height, 100);
    expect(box2.size.width, 80);
  });
}

Widget _buildSliverConstrainedCrossAxis({required double extent, GlobalKey? key}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: CustomScrollView(
      slivers: <Widget>[
        SliverConstrainedCrossAxis(
          extent: extent,
          sliver: SliverToBoxAdapter(
            key: key,
            child: Container(height: 100),
          ),
        ),
      ],
    ),
  );
}
