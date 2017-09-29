// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'layer.dart';
import 'object.dart';

/// A [RenderBox] backed by a platform surface.
class PlatformSurfaceBox extends RenderBox {
  PlatformSurfaceBox({ int surfaceId }) : _surfaceId = surfaceId;

  int _surfaceId;

  set surfaceId(int value) {
    if (value != _surfaceId) {
      _surfaceId = value;
      markNeedsPaint();
    }
  }

  int get surfaceId => _surfaceId;

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }


  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_surfaceId == null) {
      return;
    }
    context.addLayer(new PlatformSurfaceLayer(
      rect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      surfaceId: _surfaceId,
    ));
  }
}
