// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:ui';
import 'dart:ui_web' as ui_web;

/// The web implementation of [viewportOrigin].
///
/// Returns the top-left corner of the element that hosts [view], in CSS pixels
/// relative to the top-left corner of the browser viewport.
///
/// Returns [Offset.zero] if [view] has no host element.
///
/// See also:
///
///  * `_view_utils_io.dart`, which has the dart:io implementation
Offset viewportOrigin(FlutterView view) {
  final JSAny? hostElement = ui_web.views.getHostElement(view.viewId);
  if (hostElement == null) {
    return Offset.zero;
  }
  final _DOMRect rect = (hostElement as _Element).getBoundingClientRect();
  return Offset(rect.left, rect.top);
}

/// A DOM `Element`.
extension type _Element._(JSObject _) implements JSObject {
  external _DOMRect getBoundingClientRect();
}

/// A DOM `DOMRect`.
extension type _DOMRect._(JSObject _) implements JSObject {
  external double get left;
  external double get top;
}
