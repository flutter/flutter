// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/rendering/box.dart';

class RenderSolidColorBox extends RenderDecoratedBox {
  final Size desiredSize;
  final Color backgroundColor;

  RenderSolidColorBox(Color backgroundColor, { this.desiredSize: Size.infinite })
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
      decoration = new BoxDecoration(backgroundColor: const Color(0xFFFF0000));
    else if (event.type == 'pointerup')
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
  }
}