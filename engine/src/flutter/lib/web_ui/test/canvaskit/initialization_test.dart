// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit', () {
    setUpCanvasKitTest();

    test('populates flt-renderer and flt-build-mode', () {
      FlutterViewEmbedder();
      expect(domDocument.body!.getAttribute('flt-renderer'),
          'canvaskit (requested explicitly)');
      expect(domDocument.body!.getAttribute('flt-build-mode'), 'debug');
    });
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
