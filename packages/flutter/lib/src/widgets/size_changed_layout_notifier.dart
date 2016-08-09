// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Indicates that the size of one of the descendants of the object receiving
/// this notification has changed, and that therefore any assumptions about that
/// layout are no longer valid.
///
/// See [LayoutChangedNotification].
class SizeChangedLayoutNotificaion extends LayoutChangedNotification {}

/// A widget that automatically dispatches a [SizeChangedLayoutNotifier] when
/// the layout of its child changes.
///
/// Useful especially when having some complex, layout-changing animation within
/// [Material] that is also interactive.
class SizeChangedLayoutNotifier extends SingleChildRenderObjectWidget {
  /// Creates a [SizeChangedLayoutNotifier] that dispatches layout changed
  /// notifications when [child] changes layout.
  SizeChangedLayoutNotifier({
    Key key,
    Widget child
  }) : super(key: key, child: child);

  @override
  _RenderSizeChangedWithCallback createRenderObject(BuildContext context) {
    return new _RenderSizeChangedWithCallback(
      onLayoutChangedCallback: () {
        new SizeChangedLayoutNotificaion().dispatch(context);
      }
    );
  }
}

class _RenderSizeChangedWithCallback extends RenderProxyBox {
  _RenderSizeChangedWithCallback({
    RenderBox child,
    this.onLayoutChangedCallback
  }) : super(child);

  VoidCallback onLayoutChangedCallback;
  Size _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (onLayoutChangedCallback != null && size != _oldSize)
      onLayoutChangedCallback();
    _oldSize = size;
  }
}
