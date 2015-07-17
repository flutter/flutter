// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/sky_binding.dart';

import 'solid_color_box.dart';

void main() {
  var table = new RenderFlex(direction: FlexDirection.vertical);

  void addRow(FlexAlignItems align) {
    TextStyle style = const TextStyle(color: const Color(0xFF000000));
    RenderParagraph paragraph = new RenderParagraph(new InlineStyle(style, [new InlineText("${align}")]));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeDims.only(top: 20.0)));
    var row = new RenderFlex(direction: FlexDirection.horizontal);

    style = new TextStyle(fontSize: 15.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFCCCC)),
      child: new RenderParagraph(new InlineStyle(style, [new InlineText('foo foo foo')]))
    ));
    style = new TextStyle(fontSize: 10.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCFFCC)),
      child: new RenderParagraph(new InlineStyle(style, [new InlineText('foo foo foo')]))
    ));
    style = new TextStyle(fontSize: 25.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCFF)),
      child: new RenderParagraph(new InlineStyle(style, [new InlineText('foo foo foo foo')]))
    ));
    row.add(new RenderSolidColorBox(const Color(0xFFCCFFFF), desiredSize: new Size(30.0, 40.0)));
    row.alignItems = align;
    table.add(row);
    row.parentData.flex = 1;
  }

  addRow(FlexAlignItems.start);
  addRow(FlexAlignItems.end);
  addRow(FlexAlignItems.center);
  addRow(FlexAlignItems.stretch);
  addRow(FlexAlignItems.baseline);

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeDims.symmetric(vertical: 50.0))
  );

  new SkyBinding(root: root);
}
