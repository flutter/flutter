// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart';

import '../services/dom.dart';

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

  bool _initialized = false;

  DomElement _getElement() {
    assert(_initialized);
    return ui_web.platformViewRegistry.getViewById(viewId);
  }

  /// Creates the HTML element.
  Future<void> initialize() async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  /// Sets [attributes] on the platform view's HTML element.
  void setAttributes(Map<String, String> attributes) {
    final DomElement element = _getElement();
    for (final MapEntry<String, String> attribute in attributes.entries) {
      element.setAttribute(attribute.key, attribute.value);
    }
  }

  /// Removes [attributeKeys] from the platform view's HTML element.
  void removeAttributes(Iterable<String> attributeKeys) {
    final DomElement element = _getElement();
    attributeKeys.forEach(element.removeAttribute);
  }

  /// Sets [styles] on the platform view's HTML element.
  void setStyles(Map<String, String> styles) {
    final DomElement element = _getElement();
    for (final MapEntry<String, String> style in styles.entries) {
      element.style.setProperty(style.key, style.value);
    }
  }

  /// Removes [styleKeys] from the platform view's HTML element.
  void removeStyles(Iterable<String> styleKeys) {
    final DomElement element = _getElement();
    styleKeys.forEach(element.style.removeProperty);
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}
