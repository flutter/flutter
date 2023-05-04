// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
