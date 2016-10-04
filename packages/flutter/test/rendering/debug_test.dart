// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'rendering_tester.dart';
import 'mock_canvas.dart';

void main() {
  test('Describe transform control test', () {
    Matrix4 identity = new Matrix4.identity();
    List<String> description = debugDescribeTransform(identity);
    expect(description, equals(<String>[
      '  [0] 1.0,0.0,0.0,0.0',
      '  [1] 0.0,1.0,0.0,0.0',
      '  [2] 0.0,0.0,1.0,0.0',
      '  [3] 0.0,0.0,0.0,1.0',
    ]));
  });

  test('debugPaintPadding', () {
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), null);
    }, paints..rect(color: debugPaintSpacingColor));
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), new Rect.fromLTRB(11.0, 11.0, 19.0, 19.0));
    }, paints..path(color: debugPaintPaddingColor)..path(color: debugPaintPaddingInnerEdgeColor));
    expect((Canvas canvas) {
      debugPaintPadding(canvas, new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), new Rect.fromLTRB(15.0, 15.0, 15.0, 15.0));
    }, paints..rect(rect: new Rect.fromLTRB(10.0, 10.0, 20.0, 20.0), color: debugPaintSpacingColor));
  });

  test('debugPaintPadding from render objects', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    RenderBox b;
    RenderViewport2 root = new RenderViewport2(
      offset: new ViewportOffset.zero(),
      children: <RenderSliver>[
        s = new RenderSliverPadding(
          padding: new EdgeInsets.all(10.0),
          child: new RenderSliverToBoxAdapter(
            child: b = new RenderPadding(
              padding: new EdgeInsets.all(10.0),
            ),
          ),
        ),
      ],
    );
    layout(root);
    expect(b.debugPaint, paints..rect(color: debugPaintSizeColor)..rect(color: debugPaintSpacingColor));
    expect(b.debugPaint, isNot(paints..path()));
    expect(s.debugPaint, paints..circle(hasMaskFilter: true)..line(hasMaskFilter: true)..path(hasMaskFilter: true)..path(hasMaskFilter: true)
                               ..path(color: debugPaintPaddingColor)..path(color: debugPaintPaddingInnerEdgeColor));
    expect(s.debugPaint, isNot(paints..rect()));
    debugPaintSizeEnabled = false;
  });

  test('debugPaintPadding from render objects', () {
    debugPaintSizeEnabled = true;
    RenderSliver s;
    RenderBox b = new RenderPadding(
      padding: new EdgeInsets.all(10.0),
      child: new RenderViewport2(
        offset: new ViewportOffset.zero(),
        children: <RenderSliver>[
          s = new RenderSliverPadding(
            padding: new EdgeInsets.all(10.0),
          ),
        ],
      ),
    );
    layout(b);
    expect(s.debugPaint, paints..rect(color: debugPaintSpacingColor));
    expect(s.debugPaint, isNot(paints..circle(hasMaskFilter: true)..line(hasMaskFilter: true)..path(hasMaskFilter: true)..path(hasMaskFilter: true)
                                     ..path(color: debugPaintPaddingColor)..path(color: debugPaintPaddingInnerEdgeColor)));
    expect(b.debugPaint, paints..rect(color: debugPaintSizeColor)..path(color: debugPaintPaddingColor)..path(color: debugPaintPaddingInnerEdgeColor));
    expect(b.debugPaint, isNot(paints..rect(color: debugPaintSpacingColor)));
    debugPaintSizeEnabled = false;
  });
}
