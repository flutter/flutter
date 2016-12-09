// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Should be able to hit with positive paint offset', () {
    RenderBox green = new RenderDecoratedBox(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF00FF00)
      ));

    RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0)),
      child: green);

    RenderBox red = new RenderDecoratedBox(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ),
      child: size);

    RenderViewport viewport = new RenderViewport(child: red, paintOffset: const Offset(0.0, 10.0));
    layout(viewport);

    HitTestResult result;

    result = new HitTestResult();
    renderer.renderView.hitTest(result, position: const Point(15.0, 0.0));
    expect(result.path.first.target.runtimeType, equals(RenderView));

    result = new HitTestResult();
    renderer.renderView.hitTest(result, position: const Point(15.0, 15.0));
    expect(result.path.first.target, equals(green));
  });
}
