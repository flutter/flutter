// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'framework.dart';

/// A [Widget] backed by a platform surface.
class PlatformSurface extends LeafRenderObjectWidget {
  const PlatformSurface({ Key key, @required this.surfaceId }): super(key: key);

  final int surfaceId;

  @override
  PlatformSurfaceBox createRenderObject(BuildContext context) => new PlatformSurfaceBox(surfaceId: surfaceId);

  @override
  void updateRenderObject(BuildContext context, PlatformSurfaceBox renderObject) {
    renderObject.surfaceId = surfaceId;
  }
}
