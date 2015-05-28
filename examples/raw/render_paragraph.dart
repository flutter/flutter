// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/layout2.dart';

class RenderParagraph extends RenderDecoratedBox {
  final String text;
  LayoutRoot _layoutRoot = new LayoutRoot();
  Document _document;

  RenderParagraph(String this.text) :
   super(new BoxDecoration(backgroundColor: 0xFFFFFFFF)) {
    _document = new Document();
    _layoutRoot.rootElement = _document.createElement('p');
    _layoutRoot.rootElement.appendChild(_document.createText(this.text));
  }

  void performLayout() {
    _layoutRoot.maxWidth = constraints.maxWidth;
    _layoutRoot.minWidth = constraints.minWidth;
    _layoutRoot.layout();
    width = _layoutRoot.rootElement.width;
    height = _layoutRoot.rootElement.height;
  }

  void hitTestChildren(HitTestResult result, { double x, double y }) {
    // defaultHitTestChildren(result, x: x, y: y);
  }

  void paint(RenderNodeDisplayList canvas) {
    super.paint(canvas);
    _layoutRoot.paint(canvas);
  }
}

class RenderSolidColor extends RenderDecoratedBox {
  final double desiredHeight;
  final double desiredWidth;
  final int backgroundColor;

  RenderSolidColor(int backgroundColor, { this.desiredHeight: double.INFINITY,
                                          this.desiredWidth: double.INFINITY })
      : backgroundColor = backgroundColor,
        super(new BoxDecoration(backgroundColor: backgroundColor));

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             height: desiredHeight,
                                             width: desiredWidth);
  }

  void performLayout() {
    width = constraints.constrainWidth(desiredWidth);
    height = constraints.constrainHeight(desiredHeight);
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
  var root = new RenderFlex(
      direction: FlexDirection.Vertical,
      decoration: new BoxDecoration(backgroundColor: 0xFF000000));

  RenderNode child = new RenderSolidColor(0xFFFFFF00);
  root.add(child);
  child.parentData.flex = 2;

  // The internet is a beautiful place.  https://baconipsum.com/
  String meatyString = """Bacon ipsum dolor amet ham fatback tri-tip, prosciutto
porchetta bacon kevin meatball meatloaf pig beef ribs chicken. Brisket ribeye
andouille leberkas capicola meatloaf. Chicken pig ball tip pork picanha bresaola
alcatra. Pork pork belly alcatra, flank chuck drumstick biltong doner jowl.
Pancetta meatball tongue tenderloin rump tail jowl boudin.""";

  child = new RenderParagraph(meatyString);
  root.add(child);
  child.parentData.flex = 1;

  app = new AppView(root);
}
