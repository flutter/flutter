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
}
