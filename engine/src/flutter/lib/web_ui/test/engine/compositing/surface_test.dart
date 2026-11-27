// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$Surface.dispose', () {
    test('invokes and clears onDispose when disposeResources throws', () {
      final provider = _TestSurfaceProvider();
      final _ThrowingSurface surface = provider.createSurface();

      var onDisposeCount = 0;
      final ui.VoidCallback providerOnDispose = surface.onDispose!;
      surface.onDispose = () {
        onDisposeCount++;
        providerOnDispose();
      };

      expect(surface.dispose, throwsA(same(_ThrowingSurface.error)));

      expect(surface.isDisposed, isTrue);
      expect(surface.disposeResourcesCount, 1);
      expect(onDisposeCount, 1);
      expect(surface.onDispose, isNull);

      // The provider no longer tracks the surface.
      provider.setSkiaResourceCacheMaxBytes(1000000);
      expect(surface.resourceCacheLimitUpdates, 0);

      // Disposing again is a no-op and does not rethrow.
      surface.dispose();
      expect(surface.disposeResourcesCount, 1);
      expect(onDisposeCount, 1);
    });
  });
}

final class _TestSurfaceProvider extends SurfaceProvider<_ThrowingSurface, OnscreenCanvasProvider> {
  _TestSurfaceProvider()
    : super(OnscreenCanvasProvider(), (OnscreenCanvasProvider _) => _ThrowingSurface());
}

final class _ThrowingSurface extends Surface {
  static final StateError error = StateError('disposeResources failed');

  int disposeResourcesCount = 0;
  int resourceCacheLimitUpdates = 0;

  @override
  void disposeResources() {
    disposeResourcesCount++;
    throw error;
  }

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    resourceCacheLimitUpdates++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
