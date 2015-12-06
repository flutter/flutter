// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'edge_dims.dart';

export 'edge_dims.dart' show EdgeDims;

// This group of classes is intended for painting in cartesian coordinates.

abstract class Decoration {
  const Decoration();
  bool debugAssertValid() => true;
  EdgeDims get padding => null;
  Decoration lerpFrom(Decoration a, double t) => this;
  Decoration lerpTo(Decoration b, double t) => b;
  bool hitTest(ui.Size size, ui.Point position) => true;
  bool get needsListeners => false;
  void addChangeListener(ui.VoidCallback listener) { assert(false); }
  void removeChangeListener(ui.VoidCallback listener) { assert(false); }
  BoxPainter createBoxPainter();
  String toString([String prefix = '']) => '$prefix$runtimeType';
}

abstract class BoxPainter {
  void paint(ui.Canvas canvas, ui.Rect rect);
}
