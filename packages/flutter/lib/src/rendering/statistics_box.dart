// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'object.dart';

class RenderStatisticsBox extends RenderBox {

  RenderStatisticsBox({int optionsMask: 0, int rasterizerThreshold: 0})
    : _optionsMask = optionsMask,
      _rasterizerThreshold = rasterizerThreshold;

  int _optionsMask;
  int get optionsMask => _optionsMask;
  void set optionsMask (int mask) {
    if (mask == _optionsMask) {
      return;
    }
    _optionsMask = mask;
    markNeedsPaint();
  }

  int _rasterizerThreshold;
  int get rasterizerThreshold => _rasterizerThreshold;
  void set rasterizerThreshold (int threshold) {
    if  (threshold == _rasterizerThreshold) {
      return;
    }
    _rasterizerThreshold = threshold;
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
    size = constraints.biggest;
  }

  void paint(PaintingContext context, Offset offset) {
    context.pushStatistics(offset, optionsMask, rasterizerThreshold, size);
  }
}
