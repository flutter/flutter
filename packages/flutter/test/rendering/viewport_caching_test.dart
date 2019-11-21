// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is separate from viewport_test.dart because we can't use both
// testWidgets and rendering_tester in the same file - testWidgets will
// initialize a binding, which rendering_tester will attempt to re-initialize
// (or vice versa).

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  const double width = 800;
  const double height = 600;
  Rect rectExpandedOnAxis(double value) => Rect.fromLTRB(0.0, 0.0 - value, width, height + value);
  List<RenderSliver> children;

  setUp(() {
    children = <RenderSliver>[
      RenderSliverToBoxAdapter(
        child: RenderSizedBox(const Size(800, 400)),
      ),
    ];
  });

  test('Cache extent - null, no autocache', () async {
    final RenderViewport renderViewport = RenderViewport(
      crossAxisDirection: AxisDirection.left,
      offset: ViewportOffset.zero(),
    );
    layout(renderViewport, phase: EnginePhase.flushSemantics);
    expect(
      renderViewport.describeSemanticsClip(null),
      rectExpandedOnAxis(RenderAbstractViewport.defaultCacheExtent),
    );
  });

  test('Cache extent - 0', () async {
    final RenderViewport renderViewport = RenderViewport(
      crossAxisDirection: AxisDirection.left,
      offset: ViewportOffset.zero(),
      cacheExtent: 0.0,
      children: children,
    );
    layout(renderViewport, phase: EnginePhase.flushSemantics);
    expect(renderViewport.describeSemanticsClip(null), rectExpandedOnAxis(0.0));
  });

  test('Cache extent - 500', () async {
    final RenderViewport renderViewport = RenderViewport(
      crossAxisDirection: AxisDirection.left,
      offset: ViewportOffset.zero(),
      cacheExtent: 500.0,
      children: children,
    );
    layout(renderViewport, phase: EnginePhase.flushSemantics);
    expect(renderViewport.describeSemanticsClip(null), rectExpandedOnAxis(500.0));
  });

  test('Cache extent - auto', () async {
    final RenderViewport renderViewport = RenderViewport(
      crossAxisDirection: AxisDirection.left,
      offset: ViewportOffset.zero(),
      cacheExtent: 500.0,
      autoCache: true,
      children: children,
    );

    expect(renderViewport.cacheExtent, 500);

    layout(renderViewport);

    expect(renderViewport.cacheExtent, height);
    expect(renderViewport.describeSemanticsClip(null), rectExpandedOnAxis(height));
  });
}
