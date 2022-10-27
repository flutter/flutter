// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

import '../canvaskit/common.dart';

/// Initializes the renderer for this test.
void setUpUiTest() {
  if (renderer is CanvasKitRenderer) {
    setUpCanvasKitTest();
  }
}
