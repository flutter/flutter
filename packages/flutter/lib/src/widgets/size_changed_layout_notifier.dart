// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Indicates that the size of one of the descendants of the object receiving
/// this notification has changed, and that therefore any assumptions about that
/// layout are no longer valid.
///
/// See [LayoutChangedNotification] for additional discussion of layout
/// notifications such as this one.
class SizeChangedLayoutNotification extends LayoutChangedNotification { }

/// A widget that automatically dispatches a [SizeChangedLayoutNotifier] when
/// the layout of its child changes.
///
/// Useful especially when having some complex, layout-changing animation within
/// [Material] that is also interactive.
///
/// The notification is not sent for the initial layout (since the size doesn't
/// change in that case, it's just established).
class SizeChangedLayoutNotifier extends SingleChildRenderObjectWidget {
  /// Creates a [SizeChangedLayoutNotifier] that dispatches layout changed
  /// notifications when [child] changes layout size.
  SizeChangedLayoutNotifier({
    Key key,
    Widget child
  }) : super(key: key, child: child);

  @override
  _RenderSizeChangedWithCallback createRenderObject(BuildContext context) {
    return new _RenderSizeChangedWithCallback(
      onLayoutChangedCallback: () {
        new SizeChangedLayoutNotification().dispatch(context);
      }
    );
  }
}

class _RenderSizeChangedWithCallback extends RenderProxyBox {
  _RenderSizeChangedWithCallback({
    RenderBox child,
    this.onLayoutChangedCallback
  }) : super(child) {
    assert(onLayoutChangedCallback != null);
  }

  // There's a 1:1 relationship between the _RenderSizeChangedWithCallback and
  // the `context` that is captured by the closure created by createRenderObject
  // above to assign to onLayoutChangedCallback, and thus we know that the
  // onLayoutChangedCallback will never change nor need to change.

  final VoidCallback onLayoutChangedCallback;

  Size _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (_oldSize != null && size != _oldSize)
      onLayoutChangedCallback();
    _oldSize = size;
  }
}
