// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true);

  test('createImageFromTextureSource with HTMLImageElement and transferOwnership: true', () async {
    final DomHTMLImageElement image = createDomHTMLImageElement();
    // Use a data URL to avoid network issues in tests
    const transparentImage =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    image.src = transparentImage;

    final completer = Completer<void>();
    image.addEventListener(
      'load',
      createDomEventListener((DomEvent event) {
        completer.complete();
      }),
    );
    await completer.future;

    final ui.Image uiImage = await ui_web.createImageFromTextureSource(
      image,
      width: 1,
      height: 1,
      transferOwnership: true,
    );

    expect(uiImage.width, 1);
    expect(uiImage.height, 1);
    uiImage.dispose();
  });

  test('createImageFromTextureSource with ImageBitmap and transferOwnership: true', () async {
    final DomHTMLImageElement image = createDomHTMLImageElement();
    const transparentImage =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    image.src = transparentImage;

    final completer = Completer<void>();
    image.addEventListener(
      'load',
      createDomEventListener((DomEvent event) {
        completer.complete();
      }),
    );
    await completer.future;

    final DomImageBitmap bitmap = await createImageBitmap(image, (x: 0, y: 0, width: 1, height: 1));

    final ui.Image uiImage = await ui_web.createImageFromTextureSource(
      bitmap,
      width: 1,
      height: 1,
      transferOwnership: true,
    );

    expect(uiImage.width, 1);
    expect(uiImage.height, 1);
    uiImage.dispose();
  });
}
