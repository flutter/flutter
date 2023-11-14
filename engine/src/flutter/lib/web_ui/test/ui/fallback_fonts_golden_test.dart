// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = ui.Rect.fromLTRB(0, 0, 100, 100);

void testMain() {
  group('Font fallbacks', () {
    setUpUnitTests(
      emulateTesterEnvironment: false,
      setUpTestViewDimensions: false,
    );

    setUp(() {
      debugDisableFontFallbacks = false;
    });

    /// Used to save and restore [ui.PlatformDispatcher.onPlatformMessage] after each test.
    ui.PlatformMessageCallback? savedCallback;

    final List<String> downloadedFontFamilies = <String>[];

    setUp(() {
      renderer.fontCollection.debugResetFallbackFonts();
      renderer.fontCollection.fontFallbackManager!.downloadQueue.fallbackFontUrlPrefixOverride = 'assets/fallback_fonts/';
      renderer.fontCollection.fontFallbackManager!.downloadQueue.debugOnLoadFontFamily
        = (String family) => downloadedFontFamilies.add(family);
      savedCallback = ui.PlatformDispatcher.instance.onPlatformMessage;
    });

    tearDown(() {
      downloadedFontFamilies.clear();
      ui.PlatformDispatcher.instance.onPlatformMessage = savedCallback;
    });

    test('Roboto is always a fallback font', () {
      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks, contains('Roboto'));
    });

    test('will download Noto Sans Arabic if Arabic text is added', () async {
      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.addText('مرحبا');
      pb.build().layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();

      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks,
          contains('Noto Sans Arabic'));

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 32));
      pb.addText('مرحبا');
      pb.pop();
      final ui.Paragraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      canvas.drawParagraph(paragraph, ui.Offset.zero);
      await drawPictureUsingCurrentRenderer(recorder.endRecording());

      await matchGoldenFile(
        'ui_font_fallback_arabic.png',
        region: kDefaultRegion,
      );
      // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
    });

    test('will put the Noto Color Emoji font before other fallback fonts in the list',
        () async {
      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // Arabic fallback font.
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.addText('مرحبا');
      pb.build().layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();

      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks,
          <String>['Roboto', 'Noto Sans Arabic']);

      pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 26));
      pb.addText('Hello 😊 مرحبا');
      pb.pop();
      final ui.Paragraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();

      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks, <String>[
        'Roboto',
        'Noto Color Emoji',
        'Noto Sans Arabic',
      ]);
    });

    test('will download Noto Color Emojis and Noto Symbols if no matching Noto Font',
        () async {
      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks, <String>['Roboto']);

      // Creating this paragraph should cause us to start to download the
      // fallback font.
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.addText('Hello 😊');
      pb.build().layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();

      expect(renderer.fontCollection.fontFallbackManager!.globalFontFallbacks,
          contains('Noto Color Emoji'));

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(),
      );
      pb.pushStyle(ui.TextStyle(fontSize: 26));
      pb.addText('Hello 😊');
      pb.pop();
      final ui.Paragraph paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));

      canvas.drawParagraph(paragraph, ui.Offset.zero);
      await drawPictureUsingCurrentRenderer(recorder.endRecording());

      await matchGoldenFile(
        'ui_font_fallback_emoji.png',
        region: kDefaultRegion,
      );
      // TODO(hterkelsen): https://github.com/flutter/flutter/issues/71520
    });

    /// Attempts to render [text] and verifies that [expectedFamilies] are downloaded.
    ///
    /// Then it does the same, but asserts that the families aren't downloaded again
    /// (because they already exist in memory).
    Future<void> checkDownloadedFamiliesForString(String text, List<String> expectedFamilies) async {
      // Try rendering text that requires fallback fonts, initially before the fonts are loaded.
      ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle());
      pb.addText(text);
      pb.build().layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();
      expect(
        downloadedFontFamilies,
        expectedFamilies,
      );

      // Do the same thing but this time with loaded fonts.
      downloadedFontFamilies.clear();
      pb = ui.ParagraphBuilder(ui.ParagraphStyle());
      pb.addText(text);
      pb.build().layout(const ui.ParagraphConstraints(width: 1000));

      await renderer.fontCollection.fontFallbackManager!.debugWhenIdle();
      expect(downloadedFontFamilies, isEmpty);
    }

    // Regression test for https://github.com/flutter/flutter/issues/75836
    // When we had this bug our font fallback resolution logic would end up in an
    // infinite loop and this test would freeze and time out.
    test(
        'can find fonts for two adjacent unmatched code points from different fonts',
        () async {
      await checkDownloadedFamiliesForString('ヽಠ', <String>[
        'Noto Sans SC',
        'Noto Sans Kannada',
      ]);
    });

    test('can find glyph for 2/3 symbol', () async {
      await checkDownloadedFamiliesForString('⅔', <String>[
        'Noto Sans',
      ]);
    });

    // https://github.com/flutter/devtools/issues/6149
    test('can find glyph for treble clef', () async {
      await checkDownloadedFamiliesForString('𝄞', <String>[
        'Noto Music',
      ]);
    });

    test('findMinimumFontsForCodePoints for all supported code points', () async {
      // Collect all supported code points from all fallback fonts in the Noto
      // font tree.
      final Set<String> testedFonts = <String>{};
      final Set<int> supportedUniqueCodePoints = <int>{};
      renderer.fontCollection.fontFallbackManager!.codePointToComponents
          .forEachRange((int start, int end, FallbackFontComponent component) {
        if (component.fonts.isNotEmpty) {
          bool componentHasEnabledFont = false;
          for (final NotoFont font in component.fonts) {
            if (font.enabled) {
              testedFonts.add(font.name);
              componentHasEnabledFont = true;
            }
          }
          if (componentHasEnabledFont) {
            for (int codePoint = start; codePoint <= end; codePoint++) {
              supportedUniqueCodePoints.add(codePoint);
            }
          }
        }
      });

      expect(
          supportedUniqueCodePoints.length, greaterThan(10000)); // sanity check
      expect(
          testedFonts,
          unorderedEquals(<String>{
            'Noto Color Emoji',
            'Noto Music',
            'Noto Sans',
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

      // Construct random paragraphs out of supported code points.
      final math.Random random = math.Random(0);
      final List<int> supportedCodePoints = supportedUniqueCodePoints.toList()
        ..shuffle(random);
      const int paragraphLength = 3;
      const int totalTestSize = 1000;

      for (int batchStart = 0;
          batchStart < totalTestSize;
          batchStart += paragraphLength) {
        final int batchEnd =
            math.min(batchStart + paragraphLength, supportedCodePoints.length);
        final Set<int> codePoints = <int>{};
        for (int i = batchStart; i < batchEnd; i += 1) {
          codePoints.add(supportedCodePoints[i]);
        }
        final Set<NotoFont> fonts = <NotoFont>{};
        for (final int codePoint in codePoints) {
          final List<NotoFont> fontsForPoint = renderer
              .fontCollection.fontFallbackManager!.codePointToComponents
              .lookup(codePoint)
              .fonts;

          // All code points are extracted from the same tree, so there must
          // be at least one font supporting each code point
          expect(fontsForPoint, isNotEmpty);
          fonts.addAll(fontsForPoint);
        }

        try {
          renderer.fontCollection.fontFallbackManager!
              .findFontsForMissingCodePoints(codePoints.toList());
        } catch (e) {
          print(
            'findFontsForMissingCodePoints failed:\n'
            '  Code points: ${codePoints.join(', ')}\n'
            '  Fonts: ${fonts.map((NotoFont f) => f.name).join(', ')}',
          );
          rethrow;
        }
      }
    });
  },
  // HTML renderer doesn't use the fallback font manager.
  skip: isHtml,
  timeout: const Timeout.factor(4));
}
