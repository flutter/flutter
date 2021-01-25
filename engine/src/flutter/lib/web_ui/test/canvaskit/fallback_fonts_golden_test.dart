// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:async';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

import 'package:test/test.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:web_engine_tester/golden_tester.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = const ui.Rect.fromLTRB(0, 0, 500, 250);

Future<void> matchPictureGolden(String goldenFile, CkPicture picture,
    {ui.Rect region = kDefaultRegion, bool write = false}) async {
  final EnginePlatformDispatcher dispatcher =
      ui.window.platformDispatcher as EnginePlatformDispatcher;
  final LayerSceneBuilder sb = LayerSceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(ui.Offset.zero, picture);
  dispatcher.rasterizer!.draw(sb.build().layerTree);
  await matchGoldenFile(goldenFile,
      region: region, maxDiffRatePercent: 0.0, write: write);
}

void testMain() {
  group('Font fallbacks', () {
    setUpCanvasKitTest();

    /// Used to save and restore [ui.window.onPlatformMessage] after each test.
    ui.PlatformMessageCallback? savedCallback;

    setUp(() {
      notoDownloadQueue.downloader = TestDownloader();
      TestDownloader.mockDownloads.clear();
      savedCallback = ui.window.onPlatformMessage;
      skiaFontCollection.debugResetFallbackFonts();
    });

    tearDown(() {
      ui.window.onPlatformMessage = savedCallback;
    });

    test('Roboto is always a fallback font', () {
      expect(skiaFontCollection.globalFontFallbacks, contains('Roboto'));
    });

    test('will download Noto Naskh Arabic if Arabic text is added', () async {
      final Completer<void> fontChangeCompleter = Completer<void>();
      // Intercept the system font change message.
      ui.window.onPlatformMessage = (String name, ByteData? data,
          ui.PlatformMessageResponseCallback? callback) {
        if (name == 'flutter/system') {
          const JSONMessageCodec codec = JSONMessageCodec();
          final dynamic message = codec.decodeMessage(data);
          if (message is Map) {
            if (message['type'] == 'fontsChange') {
              fontChangeCompleter.complete();
            }
          }
        }
        if (savedCallback != null) {
          savedCallback!(name, data, callback);
        }
      };

      TestDownloader.mockDownloads[
              'https://fonts.googleapis.com/css2?family=Noto+Naskh+Arabic+UI'] =
          '''
/* arabic */
@font-face {
  font-family: 'Noto Naskh Arabic UI';
  font-style: normal;
  font-weight: 400;
  src: url(packages/ui/assets/NotoNaskhArabic-Regular.ttf) format('ttf');
  unicode-range: U+0600-06FF, U+200C-200E, U+2010-2011, U+204F, U+2E41, U+FB50-FDFF, U+FE80-FEFC;
}
''';

      expect(skiaFontCollection.globalFontFallbacks, ['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      CkParagraphBuilder pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.addText('مرحبا');

      await fontChangeCompleter.future;

      expect(skiaFontCollection.globalFontFallbacks,
          contains('Noto Naskh Arabic UI 0'));

      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(kDefaultRegion);

      pb = CkParagraphBuilder(
        CkParagraphStyle(
          fontSize: 32,
        ),
      );
      pb.addText('مرحبا');
      final CkParagraph paragraph = pb.build();
      paragraph.layout(ui.ParagraphConstraints(width: 1000));

      canvas.drawParagraph(paragraph, ui.Offset(200, 120));

      await matchPictureGolden(
          'canvaskit_font_fallback_arabic.png', recorder.endRecording());
      // TODO: https://github.com/flutter/flutter/issues/60040
      // TODO: https://github.com/flutter/flutter/issues/71520
    }, skip: isIosSafari || isFirefox);

    test('will gracefully fail if we cannot parse the Google Fonts CSS',
        () async {
      TestDownloader.mockDownloads[
              'https://fonts.googleapis.com/css2?family=Noto+Naskh+Arabic+UI'] =
          'invalid CSS... this should cause our parser to fail';

      expect(skiaFontCollection.globalFontFallbacks, ['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      CkParagraphBuilder pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.addText('مرحبا');

      // Flush microtasks and test that we didn't start any downloads.
      await Future<void>.delayed(Duration.zero);

      expect(notoDownloadQueue.isPending, isFalse);
      expect(skiaFontCollection.globalFontFallbacks, ['Roboto']);
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

class TestDownloader extends NotoDownloader {
  static final Map<String, String> mockDownloads = <String, String>{};
  @override
  Future<String> downloadAsString(String url) async {
    if (mockDownloads.containsKey(url)) {
      return mockDownloads[url]!;
    } else {
      return '';
    }
  }
}
