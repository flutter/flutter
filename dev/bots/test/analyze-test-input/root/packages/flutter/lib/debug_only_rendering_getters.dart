// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unnecessary_statements

import '../../foo/fake_render_object.dart';

class MyRenderObject extends RenderObject {
  void testDebugGettersInAssert() {
    // OK: inside assert.
    assert(!debugNeedsLayout);
    assert(!debugNeedsPaint);
    assert(!debugNeedsCompositedLayerUpdate);
    assert(!debugNeedsSemanticsUpdate);
  }

  void testDebugGettersInAssertClosure() {
    // OK: inside assert closure.
    assert(() {
      return !debugNeedsPaint;
    }());
  }

  void testDebugGettersWithIgnore() {
    // OK: flutter_ignore directive.
    debugNeedsLayout; // flutter_ignore: debug_only_rendering_getter (see analyze.dart)
  }
}

void testExternalAccess(MyRenderObject obj) {
  // Bad: outside assert.
  obj.debugNeedsLayout; // ERROR: obj.debugNeedsLayout
  obj.debugNeedsPaint; // ERROR: obj.debugNeedsPaint
  obj.debugNeedsCompositedLayerUpdate; // ERROR: obj.debugNeedsCompositedLayerUpdate
  obj.debugNeedsSemanticsUpdate; // ERROR: obj.debugNeedsSemanticsUpdate
}

void testExternalAccessInAssert(MyRenderObject obj) {
  // OK: inside assert.
  assert(!obj.debugNeedsLayout);
}
