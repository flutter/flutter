// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'dart:math' as math;

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/sky_binding.dart';

import 'solid_color_box.dart';

class Touch {
  final double x;
  final double y;
  const Touch(this.x, this.y);
}

class RenderImageGrow extends RenderImage {
  final Size _startingSize;

  RenderImageGrow(String src, Size size) : _startingSize = size, super(src, size);

  double _growth = 0.0;
  double get growth => _growth;
  void set growth(double value) {
    _growth = value;
    double newWidth = _startingSize.width == null ? null : _startingSize.width + growth;
    double newHeight = _startingSize.height == null ? null : _startingSize.height + growth;
    requestedSize = new Size(newWidth, newHeight);
  }
}

RenderImageGrow image;

Map<int, Touch> touches = new Map();
void handleEvent(event) {
  if (event is PointerEvent) {
      if (event.type == 'pointermove')
        image.growth = math.max(0.0, image.growth + event.x - touches[event.pointer].x);
    touches[event.pointer] = new Touch(event.x, event.y);
  }
}

void main() {
  void addFlexChildSolidColor(RenderFlex parent, Color backgroundColor, { int flex: 0 }) {
    RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
    parent.add(child);
    child.parentData.flex = flex;
  }

  var row = new RenderFlex(direction: FlexDirection.horizontal);

  // Left cell
  addFlexChildSolidColor(row, const Color(0xFF00D2B8), flex: 1);

  // Resizeable image
  image = new RenderImageGrow("https://www.dartlang.org/logos/dart-logo.png",
                              new Size(100.0, null));
  var padding = new RenderPadding(padding: const EdgeDims.all(10.0), child: image);
  row.add(padding);

  RenderFlex column = new RenderFlex(direction: FlexDirection.vertical);

  // Top cell
  addFlexChildSolidColor(column, const Color(0xFF55DDCA), flex: 1);

  // The internet is a beautiful place.  https://baconipsum.com/
  String meatyString = """Bacon ipsum dolor amet ham fatback tri-tip, prosciutto
porchetta bacon kevin meatball meatloaf pig beef ribs chicken. Brisket ribeye
andouille leberkas capicola meatloaf. Chicken pig ball tip pork picanha bresaola
alcatra. Pork pork belly alcatra, flank chuck drumstick biltong doner jowl.
Pancetta meatball tongue tenderloin rump tail jowl boudin.""";
  var text = new InlineStyle(
      new TextStyle(color:  const Color(0xFF009900)),
      [new InlineText(meatyString)]);
  padding = new RenderPadding(
      padding: const EdgeDims.all(10.0),
      child: new RenderParagraph(text));
  column.add(padding);

  // Bottom cell
  addFlexChildSolidColor(column, const Color(0xFF0081C6), flex: 2);

  row.add(column);
  column.parentData.flex = 8;

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: row
  );

  new SkyBinding(root: root);
  view.setEventCallback(handleEvent);
}
