// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js' as js;

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
      debugH5vccSetter = PatchedH5vcc(downloadedCanvasKit);

      // Monkey-patch the getH5vccSkSurface function of
      // `window.h5vcc.canvasKit`.
      js.context['h5vcc']['canvasKit']['getH5vccSkSurface'] = () {
        getH5vccSkSurfaceCalledCount++;

        // Returns a fake [SkSurface] object with a minimal implementation.
        return js.JsObject.jsify(<String, dynamic>{
          'dispose': () {}
        });
      };
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
      final Surface surface = SurfaceFactory.instance.getSurface();
      surface.acquireFrame(ui.Size.zero);
      expect(getH5vccSkSurfaceCalledCount, 1);

      // No <canvas> element should be created.
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelectorAll<html.Element>('canvas'),
        isEmpty,
      );
    });
  }, testOn: 'chrome');
}

class PatchedH5vcc implements H5vcc {
  @override
  final CanvasKit canvasKit;

  PatchedH5vcc(this.canvasKit);
}
