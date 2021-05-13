// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

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
      DomRenderer();
      expect(html.document.body!.attributes['flt-renderer'],
          'canvaskit (requested explicitly)');
      expect(html.document.body!.attributes['flt-build-mode'], 'debug');
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
