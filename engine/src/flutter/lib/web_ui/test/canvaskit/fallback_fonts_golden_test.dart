// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = ui.Rect.fromLTRB(0, 0, 100, 50);

void testMain() {
  group('Font fallbacks', () {
    setUpCanvasKitTest();

    /// Used to save and restore [ui.window.onPlatformMessage] after each test.
    ui.PlatformMessageCallback? savedCallback;

    setUp(() {
      FontFallbackData.debugReset();
      notoDownloadQueue.downloader = TestDownloader();
      TestDownloader.mockDownloads.clear();
      final String notoSansArabicUrl = fallbackFonts
          .singleWhere((NotoFont font) => font.name == 'Noto Sans Arabic')
          .url;
      final String notoEmojiUrl = fallbackFonts
          .singleWhere((NotoFont font) => font.name == 'Noto Color Emoji')
          .url;
      TestDownloader.mockDownloads[notoSansArabicUrl] =
          '/assets/fonts/NotoNaskhArabic-Regular.ttf';
      TestDownloader.mockDownloads[notoEmojiUrl] =
          '/assets/fonts/NotoColorEmoji.ttf';
      savedCallback = ui.window.onPlatformMessage;
    });

    tearDown(() {
      ui.window.onPlatformMessage = savedCallback;
    });

    test('Roboto is always a fallback font', () {
      expect(FontFallbackData.instance.globalFontFallbacks, contains('Roboto'));
    });

    test('will download Noto Sans Arabic if Arabic text is added', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      expect(FontFallbackData.instance.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      CkParagraphBuilder pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.addText('مرحبا');

      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();

      expect(FontFallbackData.instance.globalFontFallbacks,
          contains('Noto Sans Arabic'));

      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(kDefaultRegion);

      pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 32));
      pb.addText('مرحبا');
      pb.pop();
      final CkParagraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      canvas.drawParagraph(paragraph, ui.Offset.zero);

      await matchPictureGolden(
        'canvaskit_font_fallback_arabic.png',
        recorder.endRecording(),
        region: kDefaultRegion,
      );
      // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
    }, skip: isSafari || isFirefox);

    test('will put the Noto Emoji font before other fallback fonts in the list',
        () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      expect(FontFallbackData.instance.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // Arabic fallback font.
      CkParagraphBuilder pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.addText('مرحبا');

      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();

      expect(FontFallbackData.instance.globalFontFallbacks,
          <String>['Roboto', 'Noto Sans Arabic']);

      pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 26));
      pb.addText('Hello 😊 مرحبا');
      pb.pop();
      final CkParagraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();

      expect(FontFallbackData.instance.globalFontFallbacks, <String>[
        'Roboto',
        'Noto Color Emoji',
        'Noto Sans Arabic',
      ]);
    });

    test('will download Noto Emojis and Noto Symbols if no matching Noto Font',
        () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      expect(FontFallbackData.instance.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      CkParagraphBuilder pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.addText('Hello 😊');

      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();

      expect(FontFallbackData.instance.globalFontFallbacks,
          contains('Noto Color Emoji'));

      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(kDefaultRegion);

      pb = CkParagraphBuilder(
        CkParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 26));
      pb.addText('Hello 😊');
      pb.pop();
      final CkParagraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      canvas.drawParagraph(paragraph, ui.Offset.zero);

      await matchPictureGolden(
        'canvaskit_font_fallback_emoji.png',
        recorder.endRecording(),
        region: kDefaultRegion,
      );
      // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
    }, skip: isSafari || isFirefox);

    // Regression test for https://github.com/flutter/flutter/issues/75836
    // When we had this bug our font fallback resolution logic would end up in an
    // infinite loop and this test would freeze and time out.
    test(
        'Can find fonts for two adjacent unmatched code units from different fonts',
        () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      final LoggingDownloader loggingDownloader =
          LoggingDownloader(NotoDownloader());
      notoDownloadQueue.downloader = loggingDownloader;
      // Try rendering text that requires fallback fonts, initially before the fonts are loaded.

      CkParagraphBuilder(CkParagraphStyle()).addText('ヽಠ');
      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();
      expect(
        loggingDownloader.log,
        <String>[
          'Noto Sans SC',
          'Noto Sans Kannada',
        ],
      );

      // Do the same thing but this time with loaded fonts.
      loggingDownloader.log.clear();
      CkParagraphBuilder(CkParagraphStyle()).addText('ヽಠ');
      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();
      expect(loggingDownloader.log, isEmpty);
    });

    test('can find glyph for 2/3 symbol', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      final LoggingDownloader loggingDownloader =
          LoggingDownloader(NotoDownloader());
      notoDownloadQueue.downloader = loggingDownloader;
      // Try rendering text that requires fallback fonts, initially before the fonts are loaded.

      CkParagraphBuilder(CkParagraphStyle()).addText('⅔');
      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();
      expect(
        loggingDownloader.log,
        <String>[
          'Noto Sans',
        ],
      );

      // Do the same thing but this time with loaded fonts.
      loggingDownloader.log.clear();
      CkParagraphBuilder(CkParagraphStyle()).addText('⅔');
      rasterizer.debugRunPostFrameCallbacks();
      await notoDownloadQueue.debugWhenIdle();
      expect(loggingDownloader.log, isEmpty);
    });

    test('findMinimumFontsForCodeunits for all supported code units', () async {
      final LoggingDownloader loggingDownloader =
          LoggingDownloader(NotoDownloader());
      notoDownloadQueue.downloader = loggingDownloader;

      // Collect all supported code units from all fallback fonts in the Noto
      // font tree.
      final Set<String> testedFonts = <String>{};
      final Set<int> supportedUniqueCodeUnits = <int>{};
      final IntervalTree<NotoFont> notoTree =
          FontFallbackData.instance.notoTree;
      for (final NotoFont font in fallbackFonts) {
        testedFonts.add(font.name);
        for (final CodeunitRange range in font.computeUnicodeRanges()) {
          for (int codeUnit = range.start; codeUnit < range.end; codeUnit++) {
            supportedUniqueCodeUnits.add(codeUnit);
          }
        }
      }

      expect(
          supportedUniqueCodeUnits.length, greaterThan(10000)); // sanity check
      expect(
          testedFonts,
          unorderedEquals(<String>{
            'Noto Sans',
            'Noto Color Emoji',
            'Noto Sans Symbols',
            'Noto Sans Symbols 2',
            'Noto Sans Adlam',
            'Noto Sans Anatolian Hieroglyphs',
            'Noto Sans Arabic',
            'Noto Sans Armenian',
            'Noto Sans Avestan',
            'Noto Sans Balinese',
            'Noto Sans Bamum',
            'Noto Sans Bassa Vah',
            'Noto Sans Batak',
            'Noto Sans Bengali',
            'Noto Sans Bhaiksuki',
            'Noto Sans Brahmi',
            'Noto Sans Buginese',
            'Noto Sans Buhid',
            'Noto Sans Canadian Aboriginal',
            'Noto Sans Carian',
            'Noto Sans Caucasian Albanian',
            'Noto Sans Chakma',
            'Noto Sans Cham',
            'Noto Sans Cherokee',
            'Noto Sans Coptic',
            'Noto Sans Cuneiform',
            'Noto Sans Cypriot',
            'Noto Sans Deseret',
            'Noto Sans Devanagari',
            'Noto Sans Duployan',
            'Noto Sans Egyptian Hieroglyphs',
            'Noto Sans Elbasan',
            'Noto Sans Elymaic',
            'Noto Sans Georgian',
            'Noto Sans Glagolitic',
            'Noto Sans Gothic',
            'Noto Sans Grantha',
            'Noto Sans Gujarati',
            'Noto Sans Gunjala Gondi',
            'Noto Sans Gurmukhi',
            'Noto Sans HK',
            'Noto Sans Hanunoo',
            'Noto Sans Hatran',
            'Noto Sans Hebrew',
            'Noto Sans Imperial Aramaic',
            'Noto Sans Indic Siyaq Numbers',
            'Noto Sans Inscriptional Pahlavi',
            'Noto Sans Inscriptional Parthian',
            'Noto Sans JP',
            'Noto Sans Javanese',
            'Noto Sans KR',
            'Noto Sans Kaithi',
            'Noto Sans Kannada',
            'Noto Sans Kayah Li',
            'Noto Sans Kharoshthi',
            'Noto Sans Khmer',
            'Noto Sans Khojki',
            'Noto Sans Khudawadi',
            'Noto Sans Lao',
            'Noto Sans Lepcha',
            'Noto Sans Limbu',
            'Noto Sans Linear A',
            'Noto Sans Linear B',
            'Noto Sans Lisu',
            'Noto Sans Lycian',
            'Noto Sans Lydian',
            'Noto Sans Mahajani',
            'Noto Sans Malayalam',
            'Noto Sans Mandaic',
            'Noto Sans Manichaean',
            'Noto Sans Marchen',
            'Noto Sans Masaram Gondi',
            'Noto Sans Math',
            'Noto Sans Mayan Numerals',
            'Noto Sans Medefaidrin',
            'Noto Sans Meetei Mayek',
            'Noto Sans Meroitic',
            'Noto Sans Miao',
            'Noto Sans Modi',
            'Noto Sans Mongolian',
            'Noto Sans Mro',
            'Noto Sans Multani',
            'Noto Sans Myanmar',
            'Noto Sans NKo',
            'Noto Sans Nabataean',
            'Noto Sans New Tai Lue',
            'Noto Sans Newa',
            'Noto Sans Nushu',
            'Noto Sans Ogham',
            'Noto Sans Ol Chiki',
            'Noto Sans Old Hungarian',
            'Noto Sans Old Italic',
            'Noto Sans Old North Arabian',
            'Noto Sans Old Permic',
            'Noto Sans Old Persian',
            'Noto Sans Old Sogdian',
            'Noto Sans Old South Arabian',
            'Noto Sans Old Turkic',
            'Noto Sans Oriya',
            'Noto Sans Osage',
            'Noto Sans Osmanya',
            'Noto Sans Pahawh Hmong',
            'Noto Sans Palmyrene',
            'Noto Sans Pau Cin Hau',
            'Noto Sans Phags Pa',
            'Noto Sans Phoenician',
            'Noto Sans Psalter Pahlavi',
            'Noto Sans Rejang',
            'Noto Sans Runic',
            'Noto Sans SC',
            'Noto Sans Saurashtra',
            'Noto Sans Sharada',
            'Noto Sans Shavian',
            'Noto Sans Siddham',
            'Noto Sans Sinhala',
            'Noto Sans Sogdian',
            'Noto Sans Sora Sompeng',
            'Noto Sans Soyombo',
            'Noto Sans Sundanese',
            'Noto Sans Syloti Nagri',
            'Noto Sans Syriac',
            'Noto Sans TC',
            'Noto Sans Tagalog',
            'Noto Sans Tagbanwa',
            'Noto Sans Tai Le',
            'Noto Sans Tai Tham',
            'Noto Sans Tai Viet',
            'Noto Sans Takri',
            'Noto Sans Tamil',
            'Noto Sans Tamil Supplement',
            'Noto Sans Telugu',
            'Noto Sans Thaana',
            'Noto Sans Thai',
            'Noto Sans Tifinagh',
            'Noto Sans Tirhuta',
            'Noto Sans Ugaritic',
            'Noto Sans Vai',
            'Noto Sans Wancho',
            'Noto Sans Warang Citi',
            'Noto Sans Yi',
            'Noto Sans Zanabazar Square',
          }));

      // Construct random paragraphs out of supported code units.
      final math.Random random = math.Random(0);
      final List<int> supportedCodeUnits = supportedUniqueCodeUnits.toList()
        ..shuffle(random);
      const int paragraphLength = 3;
      const int totalTestSize = 1000;

      for (int batchStart = 0;
          batchStart < totalTestSize;
          batchStart += paragraphLength) {
        final int batchEnd =
            math.min(batchStart + paragraphLength, supportedCodeUnits.length);
        final Set<int> codeUnits = <int>{};
        for (int i = batchStart; i < batchEnd; i += 1) {
          codeUnits.add(supportedCodeUnits[i]);
        }
        final Set<NotoFont> fonts = <NotoFont>{};
        for (final int codeUnit in codeUnits) {
          final List<NotoFont> fontsForUnit = notoTree.intersections(codeUnit);

          // All code units are extracted from the same tree, so there must
          // be at least one font supporting each code unit
          expect(fontsForUnit, isNotEmpty);
          fonts.addAll(fontsForUnit);
        }

        try {
          findMinimumFontsForCodeUnits(codeUnits, fonts);
        } catch (e) {
          print(
            'findMinimumFontsForCodeunits failed:\n'
            '  Code units: ${codeUnits.join(', ')}\n'
            '  Fonts: ${fonts.map((NotoFont f) => f.name).join(', ')}',
          );
          rethrow;
        }
      }
    });
  }, skip: isSafari);
}

class TestDownloader extends NotoDownloader {
  // Where to redirect downloads to.
  static final Map<String, String> mockDownloads = <String, String>{};
  @override
  Future<String> downloadAsString(String url,
      {String? debugDescription}) async {
    if (mockDownloads.containsKey(url)) {
      url = mockDownloads[url]!;
      final Uri uri = Uri.parse(url);
      expect(uri.isScheme('http'), isFalse);
      expect(uri.isScheme('https'), isFalse);
      return super.downloadAsString(url);
    } else {
      return '';
    }
  }

  @override
  Future<ByteBuffer> downloadAsBytes(String url, {String? debugDescription}) {
    if (mockDownloads.containsKey(url)) {
      url = mockDownloads[url]!;
      final Uri uri = Uri.parse(url);
      expect(uri.isScheme('http'), isFalse);
      expect(uri.isScheme('https'), isFalse);
      return super.downloadAsBytes(url);
    } else {
      return Future<ByteBuffer>.value(Uint8List(0).buffer);
    }
  }
}

class LoggingDownloader implements NotoDownloader {
  LoggingDownloader(this.delegate);

  final List<String> log = <String>[];

  final NotoDownloader delegate;

  @override
  Future<void> debugWhenIdle() {
    return delegate.debugWhenIdle();
  }

  @override
  Future<ByteBuffer> downloadAsBytes(String url, {String? debugDescription}) {
    log.add(debugDescription ?? url);
    return delegate.downloadAsBytes(url);
  }

  @override
  Future<String> downloadAsString(String url, {String? debugDescription}) {
    log.add(debugDescription ?? url);
    return delegate.downloadAsString(url);
  }

  @override
  int get debugActiveDownloadCount => delegate.debugActiveDownloadCount;
}
