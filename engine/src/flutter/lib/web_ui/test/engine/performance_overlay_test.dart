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
      final LayerSceneBuilder sb1 = LayerSceneBuilder();
      final int baselineWarnings = warnings.length;
      expect(() => sb1.addPerformanceOverlay(0, ui.Rect.zero), returnsNormally);
      final int afterFirstCall = warnings.length;
      // First call may emit 0 (if already warned earlier in another test) or 1 new warning.
      final int deltaFirst = afterFirstCall - baselineWarnings;
      expect(deltaFirst == 0 || deltaFirst == 1, isTrue,
          reason: 'First call should emit at most one warning.');
      if (deltaFirst == 1) {
        expect(
          warnings.last,
          contains('showPerformanceOverlay is not supported on Flutter Web'),
        );
      }

      // Second call (using a new builder instance) should not emit another warning.
      final LayerSceneBuilder sb2 = LayerSceneBuilder();
      final int baselineSecond = warnings.length;
      sb2.addPerformanceOverlay(0, ui.Rect.zero);
      expect(warnings.length, baselineSecond,
          reason: 'Second call should not produce additional warnings.');
    });
  });
}
