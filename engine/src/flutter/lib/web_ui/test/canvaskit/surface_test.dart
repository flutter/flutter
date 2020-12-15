// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit', () {
    setUpCanvasKitTest();

    test('Surface allocates canvases efficiently', () {
      final Surface surface = Surface(HtmlViewEmbedder());
      final CkSurface original = surface.acquireFrame(ui.Size(9, 19)).skiaSurface;

      // Expect exact requested dimensions.
      expect(original.width(), 9);
      expect(original.height(), 19);

      // Shrinking reuses the existing surface straight-up.
      final CkSurface shrunk = surface.acquireFrame(ui.Size(5, 15)).skiaSurface;
      expect(shrunk, same(original));

      // The first increase will allocate a new surface, but will overallocate
      // by 40% to accommodate future increases.
      final CkSurface firstIncrease = surface.acquireFrame(ui.Size(10, 20)).skiaSurface;
      expect(firstIncrease, isNot(same(original)));

      // Expect overallocated dimensions
      expect(firstIncrease.width(), 14);
      expect(firstIncrease.height(), 28);

      // Subsequent increases within 40% reuse the old surface.
      final CkSurface secondIncrease = surface.acquireFrame(ui.Size(11, 22)).skiaSurface;
      expect(secondIncrease, same(firstIncrease));

      // Increases beyond the 40% limit will cause a new allocation.
      final CkSurface huge = surface.acquireFrame(ui.Size(20, 40)).skiaSurface;
      expect(huge, isNot(same(firstIncrease)));

      // Also over-allocated
      expect(huge.width(), 28);
      expect(huge.height(), 56);

      // Shrink again. Reuse the last allocated surface.
      final CkSurface shrunk2 = surface.acquireFrame(ui.Size(5, 15)).skiaSurface;
      expect(shrunk2, same(huge));
    });

    test(
      'Surface creates new context when WebGL context is lost',
      () async {
        final Surface surface = Surface(HtmlViewEmbedder());
        expect(surface.debugForceNewContext, isTrue);
        final CkSurface before = surface.acquireFrame(ui.Size(9, 19)).skiaSurface;
        expect(surface.debugForceNewContext, isFalse);

        // Pump a timer to flush any microtasks.
        await Future<void>.delayed(Duration.zero);
        final CkSurface afterAcquireFrame = surface.acquireFrame(ui.Size(9, 19)).skiaSurface;
        // Existing context is reused.
        expect(afterAcquireFrame, same(before));

        // Emulate WebGL context loss.
        final html.CanvasElement canvas = surface.htmlElement.children.single as html.CanvasElement;
        final dynamic ctx = canvas.getContext('webgl2');
        final dynamic loseContextExtension = ctx.getExtension('WEBGL_lose_context');
        loseContextExtension.loseContext();

        // Pump a timer to allow the "lose context" event to propagate.
        await Future<void>.delayed(Duration.zero);
        expect(surface.debugForceNewContext, isTrue);
        final CkSurface afterContextLost = surface.acquireFrame(ui.Size(9, 19)).skiaSurface;
        // A new cotext is created.
        expect(afterContextLost, isNot(same(before)));
      },
      // Firefox doesn't have the WEBGL_lose_context extension.
      skip: isFirefox || isIosSafari,
    );
  }, skip: isIosSafari);
}
