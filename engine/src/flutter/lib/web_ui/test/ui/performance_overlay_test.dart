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
  group('LayerSceneBuilder.addPerformanceOverlay', () {
    final List<String> warnings = <String>[];
    late void Function(String) oldPrintWarning;

    setUpAll(() {
      oldPrintWarning = printWarning;
      printWarning = (String warning) {
        warnings.add(warning);
      };
    });

    tearDownAll(() {
      printWarning = oldPrintWarning;
    });

    test('does not throw and warns only once per page load', () {
      final sb1 = ui.SceneBuilder();
      warnings.clear();
      expect(() => sb1.addPerformanceOverlay(0, ui.Rect.zero), returnsNormally);
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('showPerformanceOverlay is not supported on Flutter Web'));

      final sb2 = ui.SceneBuilder();
      warnings.clear();
      expect(() => sb2.addPerformanceOverlay(0, ui.Rect.zero), returnsNormally);
      expect(warnings, isEmpty, reason: 'Second call should not produce additional warnings.');
    });
  });
}
