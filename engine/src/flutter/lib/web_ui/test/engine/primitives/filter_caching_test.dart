// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();
  group('Filter Caching', () {
    test('EngineColorFilter implements Expando caching', () {
      const colorFilter = EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.srcOver);

      final BackendColorFilter backendFilter1 = colorFilter.backendFilter;

      expect(backendFilter1, isNotNull);

      // Access it again, should be the exact same instance (cached)
      final BackendColorFilter backendFilter2 = colorFilter.backendFilter;
      expect(backendFilter1, same(backendFilter2));
    });

    test('EngineMaskFilter implements Expando caching', () {
      const maskFilter = EngineMaskFilter.blur(ui.BlurStyle.normal, 5.0);

      final BackendMaskFilter backendFilter1 = maskFilter.backendFilter;

      expect(backendFilter1, isNotNull);

      final BackendMaskFilter backendFilter2 = maskFilter.backendFilter;
      expect(backendFilter1, same(backendFilter2));
    });
  });

  test('EngineImageFilter reuses the backend filter', () {
    final filter = EngineImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);
    final BackendImageFilter backendFilter1 = filter.getBackendFilter(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    final BackendImageFilter backendFilter2 = filter.getBackendFilter(
      defaultBlurTileMode: ui.TileMode.clamp,
    );

    expect(backendFilter1, same(backendFilter2));
  });

  test('EngineComposeImageFilter caches and can safely be disposed with complex compositions', () {
    final blur1 = EngineImageFilter.blur(sigmaX: 1, sigmaY: 1, tileMode: ui.TileMode.clamp);
    final blur2 = EngineImageFilter.blur(sigmaX: 2, sigmaY: 2, tileMode: ui.TileMode.clamp);
    final blur3 = EngineImageFilter.blur(sigmaX: 3, sigmaY: 3, tileMode: ui.TileMode.clamp);

    // Create a composition of 3 filters
    final innerCompose = EngineImageFilter.compose(outer: blur2, inner: blur3);
    final outerCompose = EngineImageFilter.compose(outer: blur1, inner: innerCompose);

    // Cache resolution
    final BackendImageFilter backendFilter1 = outerCompose.getBackendFilter(
      defaultBlurTileMode: ui.TileMode.clamp,
    );
    final BackendImageFilter backendFilter2 = outerCompose.getBackendFilter(
      defaultBlurTileMode: ui.TileMode.clamp,
    );

    expect(backendFilter1, isNotNull);
    expect(backendFilter1, same(backendFilter2));

    // Simulate the finalizer running to ensure disposal works gracefully
    // without crashing the native backend.
    backendFilter1.dispose();

    // Dispose again to ensure double-dispose is safe.
    backendFilter1.dispose();
  });
}
