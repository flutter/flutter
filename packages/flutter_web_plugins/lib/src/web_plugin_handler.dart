// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

/// The `ui.webOnlySetPluginHandler` function below is only defined in the Web dart:ui.
void setPluginHandler(Future<void> Function(String, ByteData?, ui.PlatformMessageResponseCallback?) handler) {
  // ignore: undefined_function, avoid_dynamic_calls
  ui.webOnlySetPluginHandler(handler);
}
