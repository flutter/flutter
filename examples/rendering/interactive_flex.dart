// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'lib/solid_color_box.dart';

class Touch {
  final double x;
  final double y;
  const Touch(this.x, this.y);
}

class RenderImageGrow extends RenderImage {
  final Size _startingSize;

  RenderImageGrow(ui.Image image, Size size)
    : _startingSize = size, super(image: image, width: size.width, height: size.height);

  double _growth = 0.0;
  double get growth => _growth;
  void set growth(double value) {
    _growth = value;
    width = _startingSize.width == null ? null : _startingSize.width + growth;
    height = _startingSize.height == null ? null : _startingSize.height + growth;
  }
}

RenderImageGrow image;

final Map<int, Touch> touches = <int, Touch>{};
void handleEvent(event) {
  if (event is ui.PointerEvent) {
    if (event.type == 'pointermove')
      image.growth = math.max(0.0, image.growth + event.x - touches[event.pointer].x);
    touches[event.pointer] = new Touch(event.x, event.y);
  }
  if (event.type == "back") {
    activity.finishCurrentActivity();
  }
}

void main() {
  void addFlexChildSolidColor(RenderFlex parent, Color backgroundColor, { int flex: 0 }) {
    RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
    parent.add(child);
    final FlexParentData childParentData = child.parentData;
    childParentData.flex = flex;
  }

  var row = new RenderFlex(direction: FlexDirection.horizontal);

  // Left cell
  addFlexChildSolidColor(row, const Color(0xFF00D2B8), flex: 1);

  // Resizeable image
  image = new RenderImageGrow(null, new Size(100.0, null));
  imageCache.load("https://www.dartlang.org/logos/dart-logo.png").first.then((ui.Image dartLogo) {
    image.image = dartLogo;
  });

  row.add(new RenderPadding(padding: const EdgeDims.all(10.0), child: image));

  RenderFlex column = new RenderFlex(direction: FlexDirection.vertical);

  // Top cell
  final Color topColor = const Color(0xFF55DDCA);
  addFlexChildSolidColor(column, topColor, flex: 1);

  // The internet is a beautiful place.  https://baconipsum.com/
  String meatyString = """Bacon ipsum dolor amet ham fatback tri-tip, prosciutto
porchetta bacon kevin meatball meatloaf pig beef ribs chicken. Brisket ribeye
andouille leberkas capicola meatloaf. Chicken pig ball tip pork picanha bresaola
alcatra. Pork pork belly alcatra, flank chuck drumstick biltong doner jowl.
Pancetta meatball tongue tenderloin rump tail jowl boudin.""";
  TextSpan text = new StyledTextSpan(
    new TextStyle(color:  const Color(0xFF009900)),
    <TextSpan>[new PlainTextSpan(meatyString)]
  );
  column.add(new RenderPadding(
    padding: const EdgeDims.all(10.0),
    child: new RenderParagraph(text)
  ));

  // Bottom cell
  addFlexChildSolidColor(column, const Color(0xFF0081C6), flex: 2);

  row.add(column);
  final FlexParentData childParentData = column.parentData;
  childParentData.flex = 8;

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: row
  );

  updateTaskDescription('Interactive Flex', topColor);
  new FlutterBinding(root: root);
  ui.window.onEvent = handleEvent;
}
