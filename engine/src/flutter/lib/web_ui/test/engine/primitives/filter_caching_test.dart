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
}
