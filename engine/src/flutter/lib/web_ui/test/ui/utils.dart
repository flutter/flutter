// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_stub.dart' if (dart.library.ffi) 'package:ui/src/engine/skwasm/skwasm_impl.dart';

import '../canvaskit/common.dart';

/// Initializes the renderer for this test.
Future<void> setUpUiTest() async {
  if (isCanvasKit) {
    setUpCanvasKitTest();
  } else if (isHtml) {
    await initializeEngine();
  }
}

/// Returns [true] if this test is running in the CanvasKit renderer.
bool get isCanvasKit => renderer is CanvasKitRenderer;

/// Returns [true] if this test is running in the HTML renderer.
bool get isHtml => renderer is HtmlRenderer;

bool get isSkwasm => renderer is SkwasmRenderer;
