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

  for(FlexAlignItems alignItems in FlexAlignItems.values) {
    TextStyle style = const TextStyle(color: const Color(0xFF000000));
    RenderParagraph paragraph = new RenderParagraph(new RenderStyled(style, [new RenderText("${alignItems}")]));
    table.add(new RenderPadding(child: paragraph, padding: new EdgeDims.only(top: 20.0)));
    var row = new RenderFlex(alignItems: alignItems, textBaseline: TextBaseline.alphabetic);

    style = new TextStyle(fontSize: 15.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FFFCCCC)),
      child: new RenderParagraph(new RenderStyled(style, [new RenderText('foo foo foo')]))
    ));
    style = new TextStyle(fontSize: 10.0, color: const Color(0xFF000000));
    row.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCFFCC)),
      child: new RenderParagraph(new RenderStyled(style, [new RenderText('foo foo foo')]))
    ));
    var subrow = new RenderFlex(alignItems: alignItems, textBaseline: TextBaseline.alphabetic);
    style = new TextStyle(fontSize: 25.0, color: const Color(0xFF000000));
    subrow.add(new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const Color(0x7FCCCCFF)),
      child: new RenderParagraph(new RenderStyled(style, [new RenderText('foo foo foo foo')]))
    ));
    subrow.add(new RenderSolidColorBox(const Color(0x7FCCFFFF), desiredSize: new Size(30.0, 40.0)));
    row.add(subrow);
    table.add(row);
    row.parentData.flex = 1;
  }

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeDims.symmetric(vertical: 50.0))
  );

  new SkyBinding(root: root);
}
