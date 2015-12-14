// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'lib/solid_color_box.dart';

void main() {
  RenderFlex table = new RenderFlex(direction: FlexDirection.vertical);

  for (FlexAlignItems alignItems in FlexAlignItems.values) {
    TextStyle style = const TextStyle(color: const Color(0xFF000000));
    RenderParagraph paragraph = new RenderParagraph(new StyledTextSpan(style, <TextSpan>[new PlainTextSpan("$alignItems")]));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeDims.only(top: 20.0)));
    RenderFlex row = new RenderFlex(alignItems: alignItems, textBaseline: TextBaseline.alphabetic);
    style = new TextStyle(fontSize: 15.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FFFCCCC)),
      child: new RenderParagraph(new StyledTextSpan(style, <TextSpan>[new PlainTextSpan('foo foo foo')]))
    ));
    style = new TextStyle(fontSize: 10.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCFFCC)),
      child: new RenderParagraph(new StyledTextSpan(style, <TextSpan>[new PlainTextSpan('foo foo foo')]))
    ));
    RenderFlex subrow = new RenderFlex(alignItems: alignItems, textBaseline: TextBaseline.alphabetic);
    style = new TextStyle(fontSize: 25.0, color: const Color(0xFF000000));
    subrow.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCCCFF)),
      child: new RenderParagraph(new StyledTextSpan(style, <TextSpan>[new PlainTextSpan('foo foo foo foo')]))
    ));
    subrow.add(new RenderSolidColorBox(const Color(0x7FCCFFFF), desiredSize: new Size(30.0, 40.0)));
    row.add(subrow);
    table.add(row);
    final FlexParentData rowParentData = row.parentData;
    rowParentData.flex = 1;
  }

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeDims.symmetric(vertical: 50.0))
  );

  new RenderingFlutterBinding(root: root);
}
