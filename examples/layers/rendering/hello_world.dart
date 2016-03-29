// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to show the text 'Hello, world.' using the underlying
// render tree.

import 'package:flutter/rendering.dart';

void main() {
  // We use RenderingFlutterBinding to attach the render tree to the window.
  new RenderingFlutterBinding(
    // The root of our render tree is a RenderPositionedBox, which centers its
    // child both vertically and horizontally.
    root: new RenderPositionedBox(
      alignment: FractionalOffset.center,
      // We use a RenderParagraph to display the text 'Hello, world.' without
      // any explicit styling.
      child: new RenderParagraph(new TextSpan(text: 'Hello, world.'))
    )
  );
}
