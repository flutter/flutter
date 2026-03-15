// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class RenderObject {
  bool get debugNeedsLayout => false;
  bool get debugNeedsPaint => false;
  bool get debugNeedsCompositedLayerUpdate => false;
  bool get debugNeedsSemanticsUpdate => false;
}
