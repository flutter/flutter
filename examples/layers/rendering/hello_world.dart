// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to show the text 'Hello, world.' using the underlying
// render tree.

import 'package:flutter/rendering.dart';

void main() {
  // We use RenderingFlutterBinding to attach the render tree to the window.
  RenderingFlutterBinding(
    // The root of our render tree is a RenderPositionedBox, which centers its
    // child both vertically and horizontally.
    root: RenderPositionedBox(
      alignment: Alignment.center,
      // We use a RenderParagraph to display the text 'Hello, world.' without
      // any explicit styling.
      child: RenderParagraph(
        const TextSpan(text: 'Hello, world.'),
        // The text is in English so we specify the text direction as
        // left-to-right. If the text had been in Hebrew or Arabic, we would
        // have specified right-to-left. The Flutter framework does not assume a
        // particular text direction.
        textDirection: TextDirection.ltr,
      ),
    ),
  ).scheduleFrame();
}
