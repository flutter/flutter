// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('H5vcc patched CanvasKit', () {
    int getH5vccSkSurfaceCalledCount = 0;

    setUpAll(() async {
      // Set `window.h5vcc` to PatchedH5vcc which uses a downloaded CanvasKit.
      final CanvasKit downloadedCanvasKit = await downloadCanvasKit();
      debugH5vccSetter = PatchedH5vcc(canvasKit: downloadedCanvasKit);

      // Monkey-patch the getH5vccSkSurface function of
      // `window.h5vcc.canvasKit`.
      js_util.setProperty(h5vcc!.canvasKit!, 'getH5vccSkSurface', allowInterop(() {
        getH5vccSkSurfaceCalledCount++;

        // Returns a fake [SkSurface] object with a minimal implementation.
        return js_util.jsify(<String, dynamic>{
          'dispose': allowInterop(() {})
        });
      }));
    });

    setUpCanvasKitTest();

    setUp(() {
      getH5vccSkSurfaceCalledCount = 0;
    });

    test('sets useH5vccCanvasKit', () {
      expect(useH5vccCanvasKit, true);
    });

    test('API includes patched getH5vccSkSurface', () {
      expect(canvasKit.getH5vccSkSurface, isNotNull);
    });

    test('Surface acquireFrame uses getH5vccSkSurface', () {
      final Surface surface = SurfaceFactory.instance.getOverlay()!;
      surface.acquireFrame(ui.Size.zero);
      expect(getH5vccSkSurfaceCalledCount, 1);

      // No <canvas> element should be created.
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelectorAll('canvas'),
        isEmpty,
      );
    });
  }, testOn: 'chrome');
}

@JS()
@anonymous
@staticInterop
class PatchedH5vcc implements H5vcc {
  external factory PatchedH5vcc({CanvasKit canvasKit});
}
