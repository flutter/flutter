// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dom.dart';
import '../platform_views/slots.dart';
import 'surface.dart';

/// A surface containing a platform view, which is an HTML element.
class PersistedPlatformView extends PersistedLeafSurface {
  final int viewId;
  final double dx;
  final double dy;
  final double width;
  final double height;

  PersistedPlatformView(this.viewId, this.dx, this.dy, this.width, this.height);

  @override
  DomElement createElement() {
    return createPlatformViewSlot(viewId);
  }

  @override
  void apply() {
    // See `_compositeWithParams` in the HtmlViewEmbedder for the canvaskit equivalent.
    rootElement!.style
      ..transform = 'translate(${dx}px, ${dy}px)'
      ..width = '${width}px'
      ..height = '${height}px'
      ..position = 'absolute';
  }

  // Platform Views can only be updated if their viewId matches.
  @override
  bool canUpdateAsMatch(PersistedSurface oldSurface) {
    if (super.canUpdateAsMatch(oldSurface)) {
      // super checks the runtimeType of the surface, so we can just cast...
      return viewId == ((oldSurface as PersistedPlatformView).viewId);
    }
    return false;
  }

  @override
  double matchForUpdate(PersistedPlatformView existingSurface) {
    return existingSurface.viewId == viewId ? 0.0 : 1.0;
  }

  @override
  void update(PersistedPlatformView oldSurface) {
    assert(
      viewId == oldSurface.viewId,
      'PersistedPlatformView with different viewId should never be updated. Check the canUpdateAsMatch method.',
    );
    super.update(oldSurface);
    // Only update if the view has been resized
    if (dx != oldSurface.dx ||
        dy != oldSurface.dy ||
        width != oldSurface.width ||
        height != oldSurface.height) {
      // A change in any of the dimensions is performed by calling apply.
      apply();
    }
  }
}
