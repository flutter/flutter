// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('static image dimensions survive Skwasm image upload', () async {
    debugOverrideJsConfiguration(null);
    final skwasmRenderer = renderer as SkwasmRenderer;
    skwasmRenderer.debugResetRasterizer();

    final ImageSource imageSource = ImageBitmapImageSource(
      await createImageBitmap(createBlankDomImageData(4, 6)),
    );
    final codec = EngineCodec.staticImage(imageSource);
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      try {
        expect(frame.image.width, 4);
        expect(frame.image.height, 6);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
}
