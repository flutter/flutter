// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../foo/fake_render_box.dart';

mixin ARenderBoxMixin on RenderBox {
  @override
  void computeMaxIntrinsicWidth() {  }

  @override
  void computeMinIntrinsicWidth() => computeMaxIntrinsicWidth();

  @override
  void computeMinIntrinsicHeight() {
    final void Function() f = computeMaxIntrinsicWidth;
    f();
  }
}

class RenderBoxSubclass1 extends RenderBox {
  @override
  void computeDryLayout() {
    computeDistanceToActualBaseline();
  }

  @override
  void computeDistanceToActualBaseline() {
    computeMaxIntrinsicHeight();
  }
}

class RenderBoxSubclass2 extends RenderBox with ARenderBoxMixin {
  @override
  void computeMaxIntrinsicWidth() {
    super.computeMinIntrinsicHeight();
    super.computeMaxIntrinsicWidth();
  }
}
