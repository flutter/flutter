// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// The [ui.RenderingBackend] that the engine is currently using for
/// graphics rendering.
///
/// This value is determined at engine startup and does not change during
/// the lifetime of the application.
///
/// In debug and profile builds, the backend can be influenced by the
/// `--impeller-backend` command-line flag. In release builds, the engine
/// selects the optimal backend for the platform automatically.
///
/// Example:
///
/// ```dart
/// import 'package:flutter/foundation.dart';
/// import 'dart:ui' as ui;
///
/// void checkBackend() {
///   if (defaultRenderingBackend == ui.RenderingBackend.vulkan) {
///     debugPrint('Running with Vulkan');
///   }
/// }
/// ```
///
/// See also:
///
///   * [ui.RenderingBackend], the enum of possible rendering backends.
///   * [ui.PlatformDispatcher.renderingBackend], the underlying engine API.
ui.RenderingBackend get defaultRenderingBackend =>
    ui.PlatformDispatcher.instance.renderingBackend;
