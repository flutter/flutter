// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
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
      final CkSurface original = surface.acquireRenderSurface(ui.Size(9, 19));

      // Expect exact requested dimensions.
      expect(original.width(), 9);
      expect(original.height(), 19);

      // Shrinking reuses the existing surface straight-up.
      final CkSurface shrunk = surface.acquireRenderSurface(ui.Size(5, 15));
      expect(shrunk, same(original));

      // The first increase will allocate a new surface, but will overallocate
      // by 40% to accommodate future increases.
      final CkSurface firstIncrease = surface.acquireRenderSurface(ui.Size(10, 20));
      expect(firstIncrease, isNot(same(original)));

      // Expect overallocated dimensions
      expect(firstIncrease.width(), 14);
      expect(firstIncrease.height(), 28);

      // Subsequent increases within 40% reuse the old surface.
      final CkSurface secondIncrease = surface.acquireRenderSurface(ui.Size(11, 22));
      expect(secondIncrease, same(firstIncrease));

      // Increases beyond the 40% limit will cause a new allocation.
      final CkSurface huge = surface.acquireRenderSurface(ui.Size(20, 40));
      expect(huge, isNot(same(firstIncrease)));

      // Also over-allocated
      expect(huge.width(), 28);
      expect(huge.height(), 56);

      // Shrink again. Reuse the last allocated surface.
      final CkSurface shrunk2 = surface.acquireRenderSurface(ui.Size(5, 15));
      expect(shrunk2, same(huge));
    });
  }, skip: isIosSafari);
}
