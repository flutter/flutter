// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/flex.dart';

AppView app;

void main() {
  var coloredBox = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFF00))
  );
  var shadow = const BoxShadow(
      color: const Color(0xFFEEEEEE), offset: const Size(5.0, 5.0), blur: 5.0);
  var shadowBox = new RenderShadowedBox(shadow: shadow, child: coloredBox);
  var paddedBox = new RenderPadding(padding: const EdgeDims.all(30.0),
      child: shadowBox);
  app = new AppView(paddedBox);
}
