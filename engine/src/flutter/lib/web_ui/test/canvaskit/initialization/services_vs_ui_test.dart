// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('services are initalized separately from UI', () async {
    expect(scheduleFrameCallback, isNull);
    expect(windowFlutterCanvasKit, isNull);

    expect(findGlassPane(), isNull);
    expect(RawKeyboard.instance, isNull);
    expect(KeyboardBinding.instance, isNull);
    expect(PointerBinding.instance, isNull);

    // After initializing services the UI should remain intact.
    await initializeEngineServices();
    expect(scheduleFrameCallback, isNotNull);
    expect(windowFlutterCanvasKit, isNotNull);

    expect(findGlassPane(), isNull);
    expect(RawKeyboard.instance, isNull);
    expect(KeyboardBinding.instance, isNull);
    expect(PointerBinding.instance, isNull);

    // Now UI should be taken over by Flutter.
    await initializeEngineUi();
    expect(findGlassPane(), isNotNull);
    expect(RawKeyboard.instance, isNotNull);
    expect(KeyboardBinding.instance, isNotNull);
    expect(PointerBinding.instance, isNotNull);
  });
}

DomElement? findGlassPane() {
  return domDocument.querySelector('flt-glass-pane');
}
