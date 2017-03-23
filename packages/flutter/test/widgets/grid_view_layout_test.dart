// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Empty GridView', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[
      new DecoratedBox(decoration: const BoxDecoration()),
      new DecoratedBox(decoration: const BoxDecoration()),
      new DecoratedBox(decoration: const BoxDecoration()),
      new DecoratedBox(decoration: const BoxDecoration())
    ];

    await tester.pumpWidget(new Center(
      child: new Container(
        width: 200.0,
        child: new GridView.extent(
          maxCrossAxisExtent: 100.0,
          shrinkWrap: true,
          children: children,
        ),
      ),
    ));

    children.forEach((Widget child) {
      final RenderBox box = tester.renderObject(find.byConfig(child));
      expect(box.size.width, equals(100.0), reason: "child width");
      expect(box.size.height, equals(100.0), reason: "child height");
    });

    final RenderBox grid = tester.renderObject(find.byType(GridView));
    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(200.0), reason: "grid height");

    expect(grid.debugNeedsLayout, false);

    await tester.pumpWidget(new Center(
      child: new Container(
        width: 200.0,
        child: new GridView.extent(
          maxCrossAxisExtent: 60.0,
          shrinkWrap: true,
          children: children,
        ),
      ),
    ));

    children.forEach((Widget child) {
      final RenderBox box = tester.renderObject(find.byConfig(child));
      expect(box.size.width, equals(50.0), reason: "child width");
      expect(box.size.height, equals(50.0), reason: "child height");
    });

    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(50.0), reason: "grid height");
  });
}
