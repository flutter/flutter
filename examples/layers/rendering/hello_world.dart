// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

void main() {
  new RenderingFlutterBinding(
    root: new RenderPositionedBox(
      alignment: const FractionalOffset(0.5, 0.5),
      child: new RenderParagraph(new PlainTextSpan('Hello, world.'))
    )
  );
}
