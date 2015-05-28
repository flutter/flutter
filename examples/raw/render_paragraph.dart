// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/render_box.dart';
import 'package:sky/framework/rendering/render_node.dart';
import 'package:sky/framework/rendering/render_flex.dart';
import 'package:sky/framework/rendering/render_paragraph.dart';

class RenderSolidColor extends RenderDecoratedBox {
  final Size desiredSize;
  final int backgroundColor;

  RenderSolidColor(int backgroundColor, { this.desiredSize: const Size.infinite() })
      : backgroundColor = backgroundColor,
        super(decoration: new BoxDecoration(backgroundColor: backgroundColor));

  Size getIntrinsicDimensions(BoxConstraints constraints) {
    return constraints.constrain(desiredSize);
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
  }

  void handlePointer(PointerEvent event) {
    if (event.type == 'pointerdown')
      decoration = new BoxDecoration(backgroundColor: 0xFFFF0000);
    else if (event.type == 'pointerup')
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
  }
}

AppView app;

void main() {
  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.Vertical);

  RenderNode root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: 0xFF606060),
    child: flexRoot
  );

  RenderNode child = new RenderSolidColor(0xFFFFFF00);
  flexRoot.add(child);
  child.parentData.flex = 2;

  // The internet is a beautiful place.  https://baconipsum.com/
  String meatyString = """Bacon ipsum dolor amet ham fatback tri-tip, prosciutto
porchetta bacon kevin meatball meatloaf pig beef ribs chicken. Brisket ribeye
andouille leberkas capicola meatloaf. Chicken pig ball tip pork picanha bresaola
alcatra. Pork pork belly alcatra, flank chuck drumstick biltong doner jowl.
Pancetta meatball tongue tenderloin rump tail jowl boudin.""";

  child = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: 0xFFFFFFFF),
    child: new RenderParagraph(text: meatyString, color: 0xFF009900)
  );
  flexRoot.add(child);
  child.parentData.flex = 1;

  app = new AppView(root);
}
