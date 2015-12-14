// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'lib/solid_color_box.dart';

const TextStyle style = const TextStyle(color: const Color(0xFF000000));

// Attempts to draw
// http://www.w3.org/TR/2015/WD-css-flexbox-1-20150514/images/flex-pack.svg
void main() {
  var table = new RenderFlex(direction: FlexDirection.vertical);

  void addRow(FlexJustifyContent justify) {
    RenderParagraph paragraph = new RenderParagraph(new StyledTextSpan(style, <TextSpan>[new PlainTextSpan("$justify")]));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeDims.only(top: 20.0)));
    RenderFlex row = new RenderFlex(direction: FlexDirection.horizontal);
    row.add(new RenderSolidColorBox(const Color(0xFFFFCCCC), desiredSize: new Size(80.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCFFCC), desiredSize: new Size(64.0, 60.0)));
    row.add(new RenderSolidColorBox(const Color(0xFFCCCCFF), desiredSize: new Size(160.0, 60.0)));
    row.justifyContent = justify;
    table.add(row);
    final FlexParentData rowParentData = row.parentData;
    rowParentData.flex = 1;
  }

  addRow(FlexJustifyContent.start);
  addRow(FlexJustifyContent.end);
  addRow(FlexJustifyContent.center);
  addRow(FlexJustifyContent.spaceBetween);
  addRow(FlexJustifyContent.spaceAround);

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeDims.symmetric(vertical: 50.0))
  );

  new RenderingFlutterBinding(root: root);
}
