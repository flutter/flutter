// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/66305
  RenderStack renderStack = RenderStack();
  renderStack = RenderStack(overflow: Overflow.visible);
  renderStack = RenderStack(overflow: Overflow.clip);
  renderStack = RenderStack(error: '');
  renderStack.overflow;

  // Changes made in https://docs.flutter.dev/release/breaking-changes/clip-behavior
  RenderListWheelViewport renderListWheelViewport = RenderListWheelViewport();
  renderListWheelViewport = RenderListWheelViewport(clipToSize: true);
  renderListWheelViewport = RenderListWheelViewport(clipToSize: false);
  renderListWheelViewport = RenderListWheelViewport(error: '');
  renderListWheelViewport.clipToSize;

  // Change made in https://github.com/flutter/flutter/pull/128522
  RenderParagraph(textScaleFactor: math.min(123, 456));
  RenderParagraph();
  RenderEditable(textScaleFactor: math.min(123, 456));
  RenderEditable();
  // Changes made in https://github.com/flutter/flutter/issues/13044
  RenderViewport renderViewport = RenderViewport();
  renderViewport = RenderViewport(cacheExtent: 1.0);
  renderViewport = RenderViewport(
    cacheExtent: 1.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
  );
  renderViewport = RenderViewport(
    cacheExtent: 2.0,
    cacheExtentStyle: CacheExtentStyle.viewport,
  );

  // Runtime variable (should NOT be migrated)
  CacheExtentStyle cacheExtentStyle = CacheExtentStyle.viewport;
  renderViewport = RenderViewport(
    cacheExtent: 1.0,
    cacheExtentStyle: cacheExtentStyle,
  );

  RenderShrinkWrappingViewport renderShrinkWrappingViewport =
      RenderShrinkWrappingViewport();
  renderShrinkWrappingViewport = RenderShrinkWrappingViewport(cacheExtent: 1.0);
  renderShrinkWrappingViewport = RenderShrinkWrappingViewport(
    cacheExtent: 1.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
  );
  renderShrinkWrappingViewport = RenderShrinkWrappingViewport(
    cacheExtent: 2.0,
    cacheExtentStyle: CacheExtentStyle.viewport,
  );

  // Runtime variable (should NOT be migrated)
  renderShrinkWrappingViewport = RenderShrinkWrappingViewport(
    cacheExtent: 1.0,
    cacheExtentStyle: cacheExtentStyle,
  );
}
