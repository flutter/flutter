// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

void main() {
  var coloredBox = new RenderDecoratedBox(
    decoration: new BoxDecoration(
      gradient: new RadialGradient(
        center: Point.origin, radius: 500.0,
        colors: <Color>[Colors.yellow[500], Colors.blue[500]]),
      boxShadow: elevationToShadow[8])
  );
  var paddedBox = new RenderPadding(
    padding: const EdgeDims.all(50.0),
    child: coloredBox);
  new FlutterBinding(root: new RenderDecoratedBox(
    decoration: const BoxDecoration(
      backgroundColor: const Color(0xFFFFFFFF)
    ),
    child: paddedBox
  ));
}
