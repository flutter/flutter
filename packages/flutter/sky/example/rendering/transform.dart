// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  RenderDecoratedBox green = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00))
  );
  RenderConstrainedBox box = new RenderConstrainedBox(
    additionalConstraints: new BoxConstraints.tight(const sky.Size(200.0, 200.0)),
    child: green
  );

  Matrix4 transform = new Matrix4.identity();
  RenderTransform spin = new RenderTransform(
      transform: transform, child: box);
  spin.rotateZ(1.0);

  RenderFlex flex = new RenderFlex();
  flex.add(spin);
  new SkyBinding(root: flex);
}
