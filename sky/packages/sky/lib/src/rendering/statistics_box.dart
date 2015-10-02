// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/object.dart';

class StatisticsBox extends RenderBox {

  StatisticsBox({int optionsMask: 0}) : _optionsMask = optionsMask;

  int _optionsMask;
  int get optionsMask => _optionsMask;
  void set optionsMask (int mask) {
    if (mask == _optionsMask) {
      return;
    }
    _optionsMask = mask;
    markNeedsPaint();
  }

  bool get sizedByParent => true;

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.minWidth;
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.maxWidth;
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.minHeight;
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.maxHeight;
  }

  void performResize() {
    size = constraints.constrain(Size.infinite);
  }

  void paint(PaintingContext context, Offset offset) {
    context.paintStatistics(optionsMask, offset, size);
  }
}
