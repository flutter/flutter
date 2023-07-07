// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Fake interface for the logic that this package needs from (web-only) dart:ui.
// This is conditionally exported so the analyzer sees these methods as available.

// ignore: avoid_classes_with_only_static_members
/// Shim for web_ui engine.PlatformViewRegistry
/// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/ui.dart#L62
// ignore: camel_case_types
class platformViewRegistry {
  /// Shim for registerViewFactory
  /// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/ui.dart#L72
  static void registerViewFactory(
      String viewTypeId, dynamic Function(int viewId) viewFactory,
      {bool isVisible = true}) {}
}

// ignore: avoid_classes_with_only_static_members
/// Shim for web_ui engine.AssetManager.
/// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/assets.dart#L12
// ignore: camel_case_types
class webOnlyAssetManager {
  /// Shim for getAssetUrl.
  /// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/assets.dart#L45
  static String getAssetUrl(String asset) {
    return '';
  }
}

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();
