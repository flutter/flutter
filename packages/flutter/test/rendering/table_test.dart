// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

RenderBox sizedBox(double width, double height) {
  return new RenderConstrainedBox(
    additionalConstraints: new BoxConstraints.tight(new Size(width, height))
  );
}

void main() {
  test('Table control test; tight', () {
    RenderTable table;
    layout(table = new RenderTable());

    expect(table.size.width, equals(800.0));
    expect(table.size.height, equals(600.0));
  });

  test('Table control test; loose', () {
    RenderTable table;
    layout(new RenderPositionedBox(child: table = new RenderTable()));

    expect(table.size, equals(const Size(800.0, 0.0)));
  });

  test('Table test: combinations', () {
    RenderTable table;
    layout(new RenderPositionedBox(child: table = new RenderTable(
      columns: 5,
      rows: 5,
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic
    )));

    expect(table.size, equals(const Size(800.0, 0.0)));

    table.setChild(2, 4, sizedBox(100.0, 200.0));

    pumpFrame();

    expect(table.size, equals(new Size(800.0, 200.0)));

    table.setChild(0, 0, sizedBox(10.0, 30.0));
    table.setChild(1, 0, sizedBox(20.0, 20.0));
    table.setChild(2, 0, sizedBox(30.0, 10.0));

    pumpFrame();

    expect(table.size, equals(new Size(800.0, 230.0)));
  });
}
