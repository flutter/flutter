// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:ui' as ui;

/// A registry for factories that create platform views.
class PlatformViewRegistry {
  /// Private constructor so this class can be a singleton.
  PlatformViewRegistry._();

  /// Register [viewTypeId] as being creating by the given [factory].
  bool registerViewFactory(String viewTypeId, PlatformViewFactory factory) {
    // TODO(hterkelsen): This is a temporary change as we migrate the
    //   platform view registry from dart:ui to package:flutter_web_plugins.
    // ignore: undefined_prefixed_name
    return ui.platformViewRegistry.registerViewFactory(viewTypeId, factory)
        as bool;
  }

  /// Returns the view that has been created with the given [id], or `null` if
  /// no such view exists.
  html.Element getCreatedView(int id) {
    // TODO(hterkelsen): This is a temporary change as we migrate the
    //   platform view registry from dart:ui to package:flutter_web_plugins.
    // ignore: undefined_prefixed_name
    return ui.platformViewRegistry.getCreatedView(id) as html.Element;
  }
}

/// A function which takes a unique [id] and creates an HTML element.
typedef PlatformViewFactory = html.Element Function(int viewId);

/// The platform view registry for this app.
final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry._();
