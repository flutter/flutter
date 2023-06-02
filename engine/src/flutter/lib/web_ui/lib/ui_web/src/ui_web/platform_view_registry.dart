// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

/// The platform view registry for this app.
final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry();

/// A registry for factories that create platform views.
class PlatformViewRegistry {
  /// Register [viewTypeId] as being creating by the given [viewFactory].
  /// [viewFactory] can be any function that takes an integer and returns an
  /// `HTMLElement` DOM object.
  bool registerViewFactory(
    String viewTypeId,
    Object Function(int viewId) viewFactory, {
    bool isVisible = true,
  }) {
    return platformViewManager.registerFactory(
      viewTypeId,
      viewFactory,
      isVisible: isVisible,
    );
  }

  /// Returns the view previously created for [viewId].
  ///
  /// Throws if no view has been created for [viewId].
  Object getViewById(int viewId) {
    return platformViewManager.getViewById(viewId);
  }
}
