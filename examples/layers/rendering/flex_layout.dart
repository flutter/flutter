// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use flex layout directly in the underlying render
// tree.

import 'package:flutter/rendering.dart';

import 'src/solid_color_box.dart';

void main() {
  final RenderFlex table = new RenderFlex(direction: Axis.vertical, textDirection: TextDirection.ltr);

  void addAlignmentRow(CrossAxisAlignment crossAxisAlignment) {
    TextStyle style = const TextStyle(color: const Color(0xFF000000));
    final RenderParagraph paragraph = new RenderParagraph(
      new TextSpan(style: style, text: '$crossAxisAlignment'),
      textDirection: TextDirection.ltr,
    );
    table.add(new RenderPadding(child: paragraph, padding: const EdgeInsets.only(top: 20.0)));
    final RenderFlex row = new RenderFlex(crossAxisAlignment: crossAxisAlignment, textBaseline: TextBaseline.alphabetic, textDirection: TextDirection.ltr);
    style = const TextStyle(fontSize: 15.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: const BoxDecoration(color: const Color(0x7FFFCCCC)),
      child: new RenderParagraph(
        new TextSpan(style: style, text: 'foo foo foo'),
        textDirection: TextDirection.ltr,
      ),
    ));
    style = const TextStyle(fontSize: 10.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: const BoxDecoration(color: const Color(0x7FCCFFCC)),
      child: new RenderParagraph(
        new TextSpan(style: style, text: 'foo foo foo'),
        textDirection: TextDirection.ltr,
      ),
    ));
    final RenderFlex subrow = new RenderFlex(crossAxisAlignment: crossAxisAlignment, textBaseline: TextBaseline.alphabetic, textDirection: TextDirection.ltr);
    style = const TextStyle(fontSize: 25.0, color: const Color(0xFF000000));
    subrow.add(new RenderDecoratedBox(
      decoration: const BoxDecoration(color: const Color(0x7FCCCCFF)),
      child: new RenderParagraph(
        new TextSpan(style: style, text: 'foo foo foo foo'),
        textDirection: TextDirection.ltr,
      ),
    ));
    subrow.add(new RenderSolidColorBox(const Color(0x7FCCFFFF), desiredSize: const Size(30.0, 40.0)));
    row.add(subrow);
    table.add(row);
    final FlexParentData rowParentData = row.parentData;
    rowParentData.flex = 1;
  }

  addAlignmentRow(CrossAxisAlignment.start);
  addAlignmentRow(CrossAxisAlignment.end);
  addAlignmentRow(CrossAxisAlignment.center);
  addAlignmentRow(CrossAxisAlignment.stretch);
  addAlignmentRow(CrossAxisAlignment.baseline);

  void addJustificationRow(MainAxisAlignment justify) {
    const TextStyle style = const TextStyle(color: const Color(0xFF000000));
    final RenderParagraph paragraph = new RenderParagraph(
      new TextSpan(style: style, text: '$justify'),
      textDirection: TextDirection.ltr,
    );
    table.add(new RenderPadding(child: paragraph, padding: const EdgeInsets.only(top: 20.0)));
    final RenderFlex row = new RenderFlex(direction: Axis.horizontal, textDirection: TextDirection.ltr);
    row.add(new RenderSolidColorBox(const Color(0xFFFFCCCC), desiredSize: const Size(80.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCFFCC), desiredSize: const Size(64.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCCCFF), desiredSize: const Size(160.0, 60.0)));
    row.mainAxisAlignment = justify;
    table.add(row);
    final FlexParentData rowParentData = row.parentData;
    rowParentData.flex = 1;
  }

  addJustificationRow(MainAxisAlignment.start);
  addJustificationRow(MainAxisAlignment.end);
  addJustificationRow(MainAxisAlignment.center);
  addJustificationRow(MainAxisAlignment.spaceBetween);
  addJustificationRow(MainAxisAlignment.spaceAround);

  final RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: const BoxDecoration(color: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: const EdgeInsets.symmetric(vertical: 50.0)),
  );

  new RenderingFlutterBinding(root: root);
}
