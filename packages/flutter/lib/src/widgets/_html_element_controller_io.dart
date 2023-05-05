// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// Controls an HTML platform view.
///
/// Used by [HtmlElementView] to create HTML elements and set their attributes
/// and styles.
class HtmlElementViewController extends PlatformViewController {
  /// Creates a new [HtmlElementViewController] for a platform view of type
  /// [viewType].
  HtmlElementViewController(
    this.viewId,
    this.viewType,
  );

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// Creates the HTML element.
  Future<void> initialize() async {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  /// Sets [attributes] on the platform view's HTML element.
  void setAttributes(Map<String, String> attributes) {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  /// Removes [attributeKeys] from the platform view's HTML element.
  void removeAttributes(Iterable<String> attributeKeys) {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  /// Sets [styles] on the platform view's HTML element.
  void setStyles(Map<String, String> styles) {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  /// Removes [styleKeys] from the platform view's HTML element.
  void removeStyles(Iterable<String> styleKeys) {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  @override
  Future<void> clearFocus() async {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }

  @override
  Future<void> dispose() async {
    throw UnimplementedError('This should not be reachable on non-web platforms');
  }
}
