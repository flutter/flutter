// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  setUp(() async {
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  test('Picture.toImage().toByteData()', () async {
    final EnginePictureRecorder recorder = PictureRecorder();
    final RecordingCanvas canvas =
        recorder.beginRecording(Rect.fromLTRB(0, 0, 2, 2));
    canvas.drawColor(Color(0xFFCCDD00), BlendMode.srcOver);
    final Picture testPicture = recorder.endRecording();
    final Image testImage = await testPicture.toImage(2, 2);
    final ByteData bytes =
        await testImage.toByteData(format: ImageByteFormat.rawRgba);
    expect(
      bytes.buffer.asUint32List(),
      <int>[0xFF00DDCC, 0xFF00DDCC, 0xFF00DDCC, 0xFF00DDCC],
    );

    final ByteData pngBytes =
        await testImage.toByteData(format: ImageByteFormat.png);

    // PNG-encoding is browser-specific, but the header is standard. We only
    // test the header.
    final List<int> pngHeader = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    expect(
      pngBytes.buffer.asUint8List().sublist(0, pngHeader.length),
      pngHeader,
    );
  });
}
