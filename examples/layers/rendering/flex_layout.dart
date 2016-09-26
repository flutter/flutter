// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use flex layout directly in the underlying render
// tree.

import 'package:flutter/rendering.dart';

import 'src/solid_color_box.dart';

void main() {
  RenderFlex table = new RenderFlex(direction: Axis.vertical);

  void addAlignmentRow(CrossAxisAlignment crossAxisAlignment) {
    TextStyle style = const TextStyle(color: const Color(0xFF000000));
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(style: style, text: '$crossAxisAlignment'));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeInsets.only(top: 20.0)));
    RenderFlex row = new RenderFlex(crossAxisAlignment: crossAxisAlignment, textBaseline: TextBaseline.alphabetic);
    style = new TextStyle(fontSize: 15.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FFFCCCC)),
      child: new RenderParagraph(new TextSpan(style: style, text: 'foo foo foo'))
    ));
    style = new TextStyle(fontSize: 10.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCFFCC)),
      child: new RenderParagraph(new TextSpan(style: style, text: 'foo foo foo'))
    ));
    RenderFlex subrow = new RenderFlex(crossAxisAlignment: crossAxisAlignment, textBaseline: TextBaseline.alphabetic);
    style = new TextStyle(fontSize: 25.0, color: const Color(0xFF000000));
    subrow.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCCCFF)),
      child: new RenderParagraph(new TextSpan(style: style, text: 'foo foo foo foo'))
    ));
    subrow.add(new RenderSolidColorBox(const Color(0x7FCCFFFF), desiredSize: new Size(30.0, 40.0)));
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
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(style: style, text: '$justify'));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeInsets.only(top: 20.0)));
    RenderFlex row = new RenderFlex(direction: Axis.horizontal);
    row.add(new RenderSolidColorBox(const Color(0xFFFFCCCC), desiredSize: new Size(80.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCFFCC), desiredSize: new Size(64.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCCCFF), desiredSize: new Size(160.0, 60.0)));
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

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeInsets.symmetric(vertical: 50.0))
  );

  new RenderingFlutterBinding(root: root);
}
