// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

class RenderSolidColorBox extends RenderDecoratedBox {
  final Size desiredSize;
  final Color backgroundColor;

  RenderSolidColorBox(Color backgroundColor, { this.desiredSize: Size.infinite })
      : backgroundColor = backgroundColor,
        super(decoration: new BoxDecoration(backgroundColor: backgroundColor));

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainHeight(
      this.desiredSize == Size.infinite ? 0.0 : desiredSize.width
    );
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(
      this.desiredSize == Size.infinite ? 0.0 : desiredSize.width
    );
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(
      this.desiredSize == Size.infinite ? 0.0 : desiredSize.height
    );
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(
      this.desiredSize == Size.infinite ? 0.0 : desiredSize.height
    );
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
  }

  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      decoration = new BoxDecoration(backgroundColor: const Color(0xFFFF0000));
    } else if (event is PointerUpEvent) {
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
    }
  }
}
