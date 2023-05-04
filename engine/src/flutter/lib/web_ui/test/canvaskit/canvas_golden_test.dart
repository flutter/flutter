// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:web_engine_tester/golden_tester.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect kDefaultRegion = ui.Rect.fromLTRB(0, 0, 500, 250);

void testMain() {
  group('CkCanvas', () {
    setUpCanvasKitTest();

    setUp(() {
      expect(notoDownloadQueue.downloader.debugActiveDownloadCount, 0);
      expect(notoDownloadQueue.isPending, isFalse);

      // We render some color emojis in this test.
      final FlutterConfiguration config = FlutterConfiguration()
        ..setUserConfiguration(
        js_util.jsify(<String, Object?>{
          'useColorEmoji': true,
        }) as JsFlutterConfiguration);
      debugSetConfiguration(config);


      FontFallbackData.debugReset();
      notoDownloadQueue.downloader.fallbackFontUrlPrefixOverride = 'assets/fallback_fonts/';
    });

    tearDown(() {
      expect(notoDownloadQueue.downloader.debugActiveDownloadCount, 0);
      expect(notoDownloadQueue.isPending, isFalse);
    });

    test('renders using non-recording canvas if weak refs are supported',
        () async {
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(kDefaultRegion);
      expect(canvas.runtimeType, CkCanvas);
      drawTestPicture(canvas);
      await matchPictureGolden(
        'canvaskit_picture.png',
        recorder.endRecording(),
        region: kDefaultRegion,
      );
    });

    test('text styles - default', () async {
      await testTextStyle('default');
    });

    test('text styles - center aligned', () async {
      await testTextStyle('center aligned',
          paragraphTextAlign: ui.TextAlign.center);
    });

    test('text styles - right aligned', () async {
      await testTextStyle('right aligned',
          paragraphTextAlign: ui.TextAlign.right);
    });

    test('text styles - rtl', () async {
      await testTextStyle('rtl', paragraphTextDirection: ui.TextDirection.rtl);
    });

    test('text styles - multiline', () async {
      await testTextStyle('multiline', layoutWidth: 50);
    });

    test('text styles - max lines', () async {
      await testTextStyle('max lines', paragraphMaxLines: 1, layoutWidth: 50);
    });

    test('text styles - ellipsis', () async {
      await testTextStyle('ellipsis',
          paragraphMaxLines: 1, paragraphEllipsis: '...', layoutWidth: 60);
    });

    test('text styles - paragraph font family', () async {
      await testTextStyle('paragraph font family', paragraphFontFamily: 'Ahem');
    });

    test('text styles - paragraph font size', () async {
      await testTextStyle('paragraph font size', paragraphFontSize: 22);
    });

    test('text styles - paragraph height', () async {
      await testTextStyle('paragraph height',
          layoutWidth: 50, paragraphHeight: 1.5);
    });

    test('text styles - paragraph text height behavior', () async {
      await testTextStyle('paragraph text height behavior',
          layoutWidth: 50,
          paragraphHeight: 1.5,
          paragraphTextHeightBehavior: const ui.TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ));
    });

    test('text styles - paragraph weight', () async {
      await testTextStyle('paragraph weight',
          paragraphFontWeight: ui.FontWeight.w900);
    });

    test('text style - paragraph font style', () async {
      await testTextStyle(
        'paragraph font style',
        paragraphFontStyle: ui.FontStyle.italic,
      );
    });

    // TODO(yjbanov): locales specified in paragraph styles don't work:
    //                https://github.com/flutter/flutter/issues/74687
    // TODO(yjbanov): spaces are not rendered correctly:
    //                https://github.com/flutter/flutter/issues/74742
    test('text styles - paragraph locale zh_CN', () async {
      await testTextStyle('paragraph locale zh_CN',
          outerText: '次 化 刃 直 入 令',
          innerText: '',
          paragraphLocale: const ui.Locale('zh', 'CN'));
    });

    test('text styles - paragraph locale zh_TW', () async {
      await testTextStyle('paragraph locale zh_TW',
          outerText: '次 化 刃 直 入 令',
          innerText: '',
          paragraphLocale: const ui.Locale('zh', 'TW'));
    });

    test('text styles - paragraph locale ja', () async {
      await testTextStyle('paragraph locale ja',
          outerText: '次 化 刃 直 入 令',
          innerText: '',
          paragraphLocale: const ui.Locale('ja'));
    });

    test('text styles - paragraph locale ko', () async {
      await testTextStyle('paragraph locale ko',
          outerText: '次 化 刃 直 入 令',
          innerText: '',
          paragraphLocale: const ui.Locale('ko'));
    });

    test('text styles - color', () async {
      await testTextStyle('color', color: const ui.Color(0xFF009900));
    });

    test('text styles - decoration', () async {
      await testTextStyle('decoration',
          decoration: ui.TextDecoration.underline);
    });

    test('text styles - decoration style', () async {
      await testTextStyle('decoration style',
          decoration: ui.TextDecoration.underline,
          decorationStyle: ui.TextDecorationStyle.dashed);
    });

    test('text styles - decoration thickness', () async {
      await testTextStyle('decoration thickness',
          decoration: ui.TextDecoration.underline, decorationThickness: 5.0);
    });

    test('text styles - font weight', () async {
      await testTextStyle('font weight', fontWeight: ui.FontWeight.w900);
    });

    test('text styles - font style', () async {
      await testTextStyle('font style', fontStyle: ui.FontStyle.italic);
    });

    // TODO(yjbanov): not sure how to test this.
    test('text styles - baseline', () async {
      await testTextStyle('baseline',
          textBaseline: ui.TextBaseline.ideographic);
    });

    test('text styles - font family', () async {
      await testTextStyle('font family', fontFamily: 'Ahem');
    });

    test('text styles - non-existent font family', () async {
      await testTextStyle('non-existent font family',
          fontFamily: 'DoesNotExist');
    });

    test('text styles - family fallback', () async {
      await testTextStyle('family fallback',
          fontFamily: 'DoesNotExist', fontFamilyFallback: <String>['Ahem']);
    });

    test('text styles - font size', () async {
      await testTextStyle('font size', fontSize: 24);
    });

    // A regression test for the special case when CanvasKit would default to
    // a positive font size when Flutter specifies zero.
    //
    // See: https://github.com/flutter/flutter/issues/98248
    test('text styles - zero font size', () async {
      // This only sets the inner text style, but not the paragraph style, so
      // "Hello" should be visible, but "World!" should disappear.
      await testTextStyle('zero font size', fontSize: 0);

      // This sets the paragraph font size to zero, but the inner text gets
      // an explicit non-zero size that should override paragraph properties,
      // so this time "Hello" should disappear, but "World!" should still be
      // visible.
      await testTextStyle('zero paragraph font size', paragraphFontSize: 0, fontSize: 14);
    });

    test('text styles - letter spacing', () async {
      await testTextStyle('letter spacing', letterSpacing: 5);
    });

    test('text styles - word spacing', () async {
      await testTextStyle('word spacing',
          innerText: 'Beautiful World!', wordSpacing: 25);
    });

    test('text styles - height', () async {
      await testTextStyle('height', height: 2);
    });

    test('text styles - leading distribution', () async {
      await testTextStyle('half leading',
          height: 20,
          fontSize: 10,
          leadingDistribution: ui.TextLeadingDistribution.even);
      await testTextStyle(
        'half leading inherited from paragraph',
        height: 20,
        fontSize: 10,
        paragraphTextHeightBehavior: const ui.TextHeightBehavior(
          leadingDistribution: ui.TextLeadingDistribution.even,
        ),
      );
      await testTextStyle(
        'text style half leading overrides paragraph style half leading',
        height: 20,
        fontSize: 10,
        leadingDistribution: ui.TextLeadingDistribution.proportional,
        paragraphTextHeightBehavior: const ui.TextHeightBehavior(
          leadingDistribution: ui.TextLeadingDistribution.even,
        ),
      );
    });

    // TODO(yjbanov): locales specified in text styles don't work:
    //                https://github.com/flutter/flutter/issues/74687
    // TODO(yjbanov): spaces are not rendered correctly:
    //                https://github.com/flutter/flutter/issues/74742
    test('text styles - locale zh_CN', () async {
      await testTextStyle('locale zh_CN',
          innerText: '次 化 刃 直 入 令',
          outerText: '',
          locale: const ui.Locale('zh', 'CN'));
    });

    test('text styles - locale zh_TW', () async {
      await testTextStyle('locale zh_TW',
          innerText: '次 化 刃 直 入 令',
          outerText: '',
          locale: const ui.Locale('zh', 'TW'));
    });

    test('text styles - locale ja', () async {
      await testTextStyle('locale ja',
          innerText: '次 化 刃 直 入 令',
          outerText: '',
          locale: const ui.Locale('ja'));
    });

    test('text styles - locale ko', () async {
      await testTextStyle('locale ko',
          innerText: '次 化 刃 直 入 令',
          outerText: '',
          locale: const ui.Locale('ko'));
    });

    test('text styles - background', () async {
      await testTextStyle('background',
          background: CkPaint()..color = const ui.Color(0xFF00FF00));
    });

    test('text styles - foreground', () async {
      await testTextStyle('foreground',
          foreground: CkPaint()..color = const ui.Color(0xFF0000FF));
    });

    test('text styles - foreground and background', () async {
      await testTextStyle(
        'foreground and background',
        foreground: CkPaint()..color = const ui.Color(0xFFFF5555),
        background: CkPaint()..color = const ui.Color(0xFF007700),
      );
    });

    test('text styles - background and color', () async {
      await testTextStyle(
        'background and color',
        color: const ui.Color(0xFFFFFF00),
        background: CkPaint()..color = const ui.Color(0xFF007700),
      );
    });

    test('text styles - shadows', () async {
      await testTextStyle('shadows', shadows: <ui.Shadow>[
        const ui.Shadow(
          color: ui.Color(0xFF999900),
          offset: ui.Offset(10, 10),
          blurRadius: 5,
        ),
        const ui.Shadow(
          color: ui.Color(0xFF009999),
          offset: ui.Offset(-10, -10),
          blurRadius: 10,
        ),
      ]);
    });

    test('text styles - old style figures', () async {
      await testTextStyle(
        'old style figures',
        paragraphFontFamily: 'Roboto',
        paragraphFontSize: 24,
        outerText: '0 1 2 3 4 5 ',
        innerText: '0 1 2 3 4 5',
        fontFeatures: <ui.FontFeature>[const ui.FontFeature.oldstyleFigures()],
      );
    });

    test('text styles - stylistic set 1', () async {
      await testTextStyle(
        'stylistic set 1',
        paragraphFontFamily: 'Roboto',
        paragraphFontSize: 24,
        outerText: 'g',
        innerText: 'g',
        fontFeatures: <ui.FontFeature>[ui.FontFeature.stylisticSet(1)],
      );
    });

    test('text styles - stylistic set 2', () async {
      await testTextStyle(
        'stylistic set 2',
        paragraphFontFamily: 'Roboto',
        paragraphFontSize: 24,
        outerText: 'α',
        innerText: 'α',
        fontFeatures: <ui.FontFeature>[ui.FontFeature.stylisticSet(2)],
      );
    });

    test('text styles - override font family', () async {
      await testTextStyle(
        'override font family',
        paragraphFontFamily: 'Ahem',
        fontFamily: 'Roboto',
      );
    });

    test('text styles - override font size', () async {
      await testTextStyle(
        'override font size',
        paragraphFontSize: 36,
        fontSize: 18,
      );
    });

    test('text style - override font weight', () async {
      await testTextStyle(
        'override font weight',
        paragraphFontWeight: ui.FontWeight.w900,
        fontWeight: ui.FontWeight.normal,
      );
    });

    test('text style - override font style', () async {
      await testTextStyle(
        'override font style',
        paragraphFontStyle: ui.FontStyle.italic,
        fontStyle: ui.FontStyle.normal,
      );
    });

    test('text style - characters from multiple fallback fonts', () async {
      await testTextStyle(
        'multi-font characters',
        // This character is claimed by multiple fonts. This test makes sure
        // we can find a font supporting it.
        outerText: '欢',
        innerText: '',
      );
    });

    test('text style - symbols', () async {
      // One of the CJK fonts loaded in one of the tests above also contains
      // some of these symbols. To make sure the test produces predictable
      // results we reset the fallback data forcing the engine to reload
      // fallbacks, which for this test will only load Noto Symbols.
      await testTextStyle(
        'symbols',
        outerText: '← ↑ → ↓ ',
        innerText: '',
      );
    });

    test(
        'text style - foreground/background/color do not leak across paragraphs',
        () async {
      const double testWidth = 440;
      const double middle = testWidth / 2;
      CkParagraph createTestParagraph(
          {ui.Color? color, CkPaint? foreground, CkPaint? background}) {
        final CkParagraphBuilder builder =
            CkParagraphBuilder(CkParagraphStyle());
        builder.pushStyle(CkTextStyle(
          fontSize: 16,
          color: color,
          foreground: foreground,
          background: background,
        ));
        final StringBuffer text = StringBuffer();
        if (color == null && foreground == null && background == null) {
          text.write('Default');
        } else {
          if (color != null) {
            text.write('Color');
          }
          if (foreground != null) {
            if (text.isNotEmpty) {
              text.write('+');
            }
            text.write('Foreground');
          }
          if (background != null) {
            if (text.isNotEmpty) {
              text.write('+');
            }
            text.write('Background');
          }
        }
        builder.addText(text.toString());
        final CkParagraph paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: testWidth));
        return paragraph;
      }

      final List<ParagraphFactory> variations = <ParagraphFactory>[
        () => createTestParagraph(),
        () => createTestParagraph(color: const ui.Color(0xFF009900)),
        () => createTestParagraph(
            foreground: CkPaint()..color = const ui.Color(0xFF990000)),
        () => createTestParagraph(
            background: CkPaint()..color = const ui.Color(0xFF7777FF)),
        () => createTestParagraph(
              color: const ui.Color(0xFFFF00FF),
              background: CkPaint()..color = const ui.Color(0xFF0000FF),
            ),
        () => createTestParagraph(
              foreground: CkPaint()..color = const ui.Color(0xFF00FFFF),
              background: CkPaint()..color = const ui.Color(0xFF0000FF),
            ),
      ];

      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
      canvas.translate(10, 10);

      for (final ParagraphFactory from in variations) {
        for (final ParagraphFactory to in variations) {
          canvas.save();
          final CkParagraph fromParagraph = from();
          canvas.drawParagraph(fromParagraph, ui.Offset.zero);

          final ui.Offset leftEnd = ui.Offset(
              fromParagraph.maxIntrinsicWidth + 10, fromParagraph.height / 2);
          final ui.Offset rightEnd = ui.Offset(middle - 10, leftEnd.dy);
          const ui.Offset tipOffset = ui.Offset(-5, -5);
          canvas.drawLine(leftEnd, rightEnd, CkPaint());
          canvas.drawLine(rightEnd, rightEnd + tipOffset, CkPaint());
          canvas.drawLine(
              rightEnd, rightEnd + tipOffset.scale(1, -1), CkPaint());

          canvas.translate(middle, 0);
          canvas.drawParagraph(to(), ui.Offset.zero);
          canvas.restore();
          canvas.translate(0, 22);
        }
      }

      final CkPicture picture = recorder.endRecording();
      await matchPictureGolden(
        'canvaskit_text_styles_do_not_leak.png',
        picture,
        region: const ui.Rect.fromLTRB(0, 0, testWidth, 850),
      );
    });

    test('sample Chinese text', () async {
      await testSampleText(
        'chinese',
        '也称乱数假文或者哑元文本， '
            '是印刷及排版领域所常用的虚拟文字。'
            '由于曾经一台匿名的打印机刻意打乱了'
            '一盒印刷字体从而造出一本字体样品书',
      );
    });

    test('sample Armenian text', () async {
      await testSampleText(
        'armenian',
        'տպագրության և տպագրական արդյունաբերության համար նախատեսված մոդելային տեքստ է',
      );
    });

    test('sample Albanian text', () async {
      await testSampleText(
        'albanian',
        'është një tekst shabllon i industrisë së printimit dhe shtypshkronjave Lorem Ipsum ka qenë teksti shabllon',
      );
    });

    test('sample Arabic text', () async {
      await testSampleText(
        'arabic',
        'هناك حقيقة مثبتة منذ زمن طويل وهي أن المحتوى المقروء لصفحة ما سيلهي',
        textDirection: ui.TextDirection.rtl,
      );
    });

    test('sample Bulgarian text', () async {
      await testSampleText(
        'bulgarian',
        'е елементарен примерен текст използван в печатарската и типографската индустрия',
      );
    });

    test('sample Catalan text', () async {
      await testSampleText(
        'catalan',
        'és un text de farciment usat per la indústria de la tipografia i la impremta',
      );
    });

    test('sample English text', () async {
      await testSampleText(
        'english',
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
      );
    });

    test('sample Greek text', () async {
      await testSampleText(
        'greek',
        'είναι απλά ένα κείμενο χωρίς νόημα για τους επαγγελματίες της τυπογραφίας και στοιχειοθεσίας',
      );
    });

    test('sample Hebrew text', () async {
      await testSampleText(
        'hebrew',
        'זוהי עובדה מבוססת שדעתו של הקורא תהיה מוסחת על ידי טקטס קריא כאשר הוא יביט בפריסתו',
        textDirection: ui.TextDirection.rtl,
      );
    });

    test('sample Hindi text', () async {
      await testSampleText(
        'hindi',
        'छपाई और अक्षर योजन उद्योग का एक साधारण डमी पाठ है सन १५०० के बाद से अभी तक इस उद्योग का मानक डमी पाठ मन गया जब एक अज्ञात मुद्रक ने नमूना लेकर एक नमूना किताब बनाई',
      );
    });

    test('sample Thai text', () async {
      await testSampleText(
        'thai',
        'คือ เนื้อหาจำลองแบบเรียบๆ ที่ใช้กันในธุรกิจงานพิมพ์หรืองานเรียงพิมพ์ มันได้กลายมาเป็นเนื้อหาจำลองมาตรฐานของธุรกิจดังกล่าวมาตั้งแต่ศตวรรษที่',
      );
    });

    test('sample Georgian text', () async {
      await testSampleText(
        'georgian',
        'საბეჭდი და ტიპოგრაფიული ინდუსტრიის უშინაარსო ტექსტია. იგი სტანდარტად',
      );
    });

    test('sample Bengali text', () async {
      await testSampleText(
        'bengali',
        'ঈদের জামাত মসজিদে, মানতে হবে স্বাস্থ্যবিধি: ধর্ম মন্ত্রণালয়',
      );
    });

    test('hindi svayan test', () async {
      await testSampleText('hindi_svayan', 'स्वयं');
    });

    // We've seen text break when we load many fonts simultaneously. This test
    // combines text in multiple languages into one long paragraph to make sure
    // we can handle it.
    test('sample multilingual text', () async {
      await testSampleText(
        'multilingual',
        '也称乱数假文或者哑元文本， 是印刷及排版领域所常用的虚拟文字。 '
            'տպագրության և տպագրական արդյունաբերության համար '
            'është një tekst shabllon i industrisë së printimit '
            ' زمن طويل وهي أن المحتوى المقروء لصفحة ما سيلهي '
            'е елементарен примерен текст използван в печатарската '
            'és un text de farciment usat per la indústria de la '
            'Lorem Ipsum is simply dummy text of the printing '
            'είναι απλά ένα κείμενο χωρίς νόημα για τους επαγγελματίες '
            ' זוהי עובדה מבוססת שדעתו של הקורא תהיה מוסחת על ידי טקטס קריא '
            'छपाई और अक्षर योजन उद्योग का एक साधारण डमी पाठ है सन '
            'คือ เนื้อหาจำลองแบบเรียบๆ ที่ใช้กันในธุรกิจงานพิมพ์หรืองานเรียงพิมพ์ '
            'საბეჭდი და ტიპოგრაფიული ინდუსტრიის უშინაარსო ტექსტია ',
      );
    });

    test('emoji text with skin tone', () async {
      await testSampleText('emoji_with_skin_tone', '👋🏿 👋🏾 👋🏽 👋🏼 👋🏻');
    }, timeout: const Timeout.factor(2));

    // Make sure we clear the canvas in between frames.
    test('empty frame after contentful frame', () async {
      // First draw a frame with a red rectangle
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
      canvas.drawRect(const ui.Rect.fromLTRB(20, 20, 100, 100),
          CkPaint()..color = const ui.Color(0xffff0000));
      final CkPicture picture = recorder.endRecording();
      final LayerSceneBuilder builder = LayerSceneBuilder();
      builder.pushOffset(0, 0);
      builder.addPicture(ui.Offset.zero, picture);
      final LayerTree layerTree = builder.build().layerTree;
      CanvasKitRenderer.instance.rasterizer.draw(layerTree);

      // Now draw an empty layer tree and confirm that the red rectangle is
      // no longer drawn.
      final LayerSceneBuilder emptySceneBuilder = LayerSceneBuilder();
      emptySceneBuilder.pushOffset(0, 0);
      final LayerTree emptyLayerTree = emptySceneBuilder.build().layerTree;
      CanvasKitRenderer.instance.rasterizer.draw(emptyLayerTree);

      await matchGoldenFile('canvaskit_empty_scene.png',
          region: const ui.Rect.fromLTRB(0, 0, 100, 100));
    });

    // Regression test for https://github.com/flutter/flutter/issues/121758
    test('resources used in temporary surfaces for Image.toByteData can cross to rendering overlays', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      SurfaceFactory.instance.debugClear();

      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      CkPicture makeTextPicture(String text, ui.Offset offset) {
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        final CkParagraphBuilder builder = CkParagraphBuilder(CkParagraphStyle());
        builder.addText(text);
        final CkParagraph paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 100));
        canvas.drawRect(
          ui.Rect.fromLTWH(offset.dx, offset.dy, paragraph.width, paragraph.height).inflate(10),
          CkPaint()..color = const ui.Color(0xFF00FF00)
        );
        canvas.drawParagraph(paragraph, offset);
        return recorder.endRecording();
      }

      CkPicture imageToPicture(CkImage image, ui.Offset offset) {
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawImage(image, offset, CkPaint());
        return recorder.endRecording();
      }

      final CkPicture helloPicture = makeTextPicture('Hello', ui.Offset.zero);

      final CkImage helloImage = helloPicture.toImageSync(100, 100);

      // Calling toByteData is essential to hit the bug.
      await helloImage.toByteData(format: ui.ImageByteFormat.png);

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPicture(ui.Offset.zero, helloPicture);
      sb.addPlatformView(0, width: 10, height: 10);

      // The image is rendered after the platform view so that it's rendered into
      // a separate surface, which is what triggers the bug. If the bug is present
      // the image will not appear on the UI.
      sb.addPicture(const ui.Offset(0, 50), imageToPicture(helloImage, ui.Offset.zero));
      sb.pop();

      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);

      await matchGoldenFile('cross_overlay_resources.png', region: const ui.Rect.fromLTRB(0, 0, 100, 100));
    });
  });
}

Future<void> testSampleText(String language, String text,
    {ui.TextDirection textDirection = ui.TextDirection.ltr}) async {
  const double testWidth = 300;
  double paragraphHeight = 0;
  final CkPicture picture = await generatePictureWhenFontsStable(() {
    final CkPictureRecorder recorder = CkPictureRecorder();
    final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
    final CkParagraphBuilder paragraphBuilder =
        CkParagraphBuilder(CkParagraphStyle(
      textDirection: textDirection,
    ));
    paragraphBuilder.addText(text);
    final CkParagraph paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: testWidth - 20));
    canvas.drawParagraph(paragraph, const ui.Offset(10, 10));
    paragraphHeight = paragraph.height;
    return recorder.endRecording();
  });
  await matchPictureGolden(
    'canvaskit_sample_text_$language.png',
    picture,
    region: ui.Rect.fromLTRB(0, 0, testWidth, paragraphHeight + 20),
  );
}

typedef ParagraphFactory = CkParagraph Function();

void drawTestPicture(CkCanvas canvas) {
  canvas.clear(const ui.Color(0xFFFFFFF));

  canvas.translate(10, 10);

  // Row 1
  canvas.save();

  canvas.save();
  canvas.clipRect(
    const ui.Rect.fromLTRB(0, 0, 45, 45),
    ui.ClipOp.intersect,
    true,
  );
  canvas.clipRRect(
    ui.RRect.fromLTRBR(5, 5, 50, 50, const ui.Radius.circular(8)),
    true,
  );
  canvas.clipPath(
    CkPath()
      ..moveTo(5, 5)
      ..lineTo(25, 5)
      ..lineTo(45, 45)
      ..lineTo(5, 45)
      ..close(),
    true,
  );
  canvas.drawColor(const ui.Color.fromARGB(255, 100, 100, 0), ui.BlendMode.srcOver);
  canvas.restore(); // remove clips

  canvas.translate(60, 0);
  canvas.drawCircle(
    const ui.Offset(30, 25),
    15,
    CkPaint()..color = const ui.Color(0xFF0000AA),
  );

  canvas.translate(60, 0);
  canvas.drawArc(
    const ui.Rect.fromLTRB(10, 20, 50, 40),
    math.pi / 4,
    3 * math.pi / 2,
    true,
    CkPaint()..color = const ui.Color(0xFF00AA00),
  );

  canvas.translate(60, 0);
  canvas.drawImage(
    generateTestImage(),
    const ui.Offset(20, 20),
    CkPaint(),
  );

  canvas.translate(60, 0);
  final ui.RSTransform transform = ui.RSTransform.fromComponents(
    rotation: 0,
    scale: 1,
    anchorX: 0,
    anchorY: 0,
    translateX: 0,
    translateY: 0,
  );
  canvas.drawAtlasRaw(
    CkPaint(),
    generateTestImage(),
    Float32List(4)
      ..[0] = transform.scos
      ..[1] = transform.ssin
      ..[2] = transform.tx + 20
      ..[3] = transform.ty + 20,
    Float32List(4)
      ..[0] = 0
      ..[1] = 0
      ..[2] = 15
      ..[3] = 15,
    Uint32List.fromList(<int>[0x00000000]),
    ui.BlendMode.srcOver,
  );

  canvas.translate(60, 0);
  canvas.drawDRRect(
    ui.RRect.fromLTRBR(0, 0, 40, 30, const ui.Radius.elliptical(16, 8)),
    ui.RRect.fromLTRBR(10, 10, 30, 20, const ui.Radius.elliptical(4, 8)),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageRect(
    generateTestImage(),
    const ui.Rect.fromLTRB(0, 0, 15, 15),
    const ui.Rect.fromLTRB(10, 10, 40, 40),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawImageNine(
    generateTestImage(),
    const ui.Rect.fromLTRB(5, 5, 15, 15),
    const ui.Rect.fromLTRB(10, 10, 50, 40),
    CkPaint(),
  );

  canvas.restore();

  // Row 2
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawLine(ui.Offset.zero, const ui.Offset(40, 30), CkPaint());

  canvas.translate(60, 0);
  canvas.drawOval(
    const ui.Rect.fromLTRB(0, 0, 40, 30),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.save();
  canvas.clipRect(const ui.Rect.fromLTRB(0, 0, 50, 30), ui.ClipOp.intersect, true);
  canvas.drawPaint(CkPaint()..color = const ui.Color(0xFF6688AA));
  canvas.restore();

  canvas.translate(60, 0);
  {
    final CkPictureRecorder otherRecorder = CkPictureRecorder();
    final CkCanvas otherCanvas =
        otherRecorder.beginRecording(const ui.Rect.fromLTRB(0, 0, 40, 20));
    otherCanvas.drawCircle(
      const ui.Offset(30, 15),
      10,
      CkPaint()..color = const ui.Color(0xFFAABBCC),
    );
    canvas.drawPicture(otherRecorder.endRecording());
  }

  canvas.translate(60, 0);
  // TODO(yjbanov): CanvasKit.drawPoints is currently broken
  //                https://github.com/flutter/flutter/issues/71489
  //                But keeping this anyway as it's a good test-case that
  //                will ensure it's fixed when we have the fix.
  canvas.drawPoints(
    CkPaint()
      ..color = const ui.Color(0xFF0000FF)
      ..strokeWidth = 5
      ..strokeCap = ui.StrokeCap.round,
    ui.PointMode.polygon,
    offsetListToFloat32List(const <ui.Offset>[
      ui.Offset(10, 10),
      ui.Offset(20, 10),
      ui.Offset(30, 20),
      ui.Offset(40, 20)
    ]),
  );

  canvas.translate(60, 0);
  canvas.drawRRect(
    ui.RRect.fromLTRBR(0, 0, 40, 30, const ui.Radius.circular(10)),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawRect(
    const ui.Rect.fromLTRB(0, 0, 40, 30),
    CkPaint(),
  );

  canvas.translate(60, 0);
  canvas.drawShadow(
    CkPath()..addRect(const ui.Rect.fromLTRB(0, 0, 40, 30)),
    const ui.Color(0xFF00FF00),
    4,
    true,
  );

  canvas.restore();

  // Row 3
  canvas.translate(0, 60);
  canvas.save();

  canvas.drawVertices(
    CkVertices(
      ui.VertexMode.triangleFan,
      const <ui.Offset>[
        ui.Offset(10, 30),
        ui.Offset(30, 50),
        ui.Offset(10, 60),
      ],
    ),
    ui.BlendMode.srcOver,
    CkPaint(),
  );

  canvas.translate(60, 0);
  final int restorePoint = canvas.save();
  for (int i = 0; i < 5; i++) {
    canvas.save();
    canvas.translate(10, 10);
    canvas.drawCircle(ui.Offset.zero, 5, CkPaint());
  }
  canvas.restoreToCount(restorePoint);
  canvas.drawCircle(ui.Offset.zero, 7, CkPaint()..color = const ui.Color(0xFFFF0000));

  canvas.translate(60, 0);
  canvas.drawLine(ui.Offset.zero, const ui.Offset(30, 30), CkPaint());
  canvas.save();
  canvas.rotate(-math.pi / 8);
  canvas.drawLine(ui.Offset.zero, const ui.Offset(30, 30), CkPaint());
  canvas.drawCircle(
      const ui.Offset(30, 30), 7, CkPaint()..color = const ui.Color(0xFF00AA00));
  canvas.restore();

  canvas.translate(60, 0);
  final CkPaint thickStroke = CkPaint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 20;
  final CkPaint semitransparent = CkPaint()..color = const ui.Color(0x66000000);

  canvas.saveLayer(kDefaultRegion, semitransparent);
  canvas.drawLine(const ui.Offset(10, 10), const ui.Offset(50, 50), thickStroke);
  canvas.drawLine(const ui.Offset(50, 10), const ui.Offset(10, 50), thickStroke);
  canvas.restore();

  canvas.translate(60, 0);
  canvas.saveLayerWithoutBounds(semitransparent);
  canvas.drawLine(const ui.Offset(10, 10), const ui.Offset(50, 50), thickStroke);
  canvas.drawLine(const ui.Offset(50, 10), const ui.Offset(10, 50), thickStroke);
  canvas.restore();

  // To test saveLayerWithFilter we draw three circles with only the middle one
  // blurred using the layer image filter.
  canvas.translate(60, 0);
  canvas.saveLayer(kDefaultRegion, CkPaint());
  canvas.drawCircle(const ui.Offset(30, 30), 10, CkPaint());
  {
    canvas.saveLayerWithFilter(
        kDefaultRegion, ui.ImageFilter.blur(sigmaX: 5, sigmaY: 10));
    canvas.drawCircle(const ui.Offset(10, 10), 10, CkPaint());
    canvas.drawCircle(const ui.Offset(50, 50), 10, CkPaint());
    canvas.restore();
  }
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.scale(2, 1.5);
  canvas.drawCircle(ui.Offset.zero, 10, CkPaint());
  canvas.restore();

  canvas.translate(60, 0);
  canvas.save();
  canvas.translate(30, 30);
  canvas.skew(2, 1.5);
  canvas.drawRect(const ui.Rect.fromLTRB(-10, -10, 10, 10), CkPaint());
  canvas.restore();

  canvas.restore();

  // Row 4
  canvas.translate(0, 60);
  canvas.save();

  canvas.save();
  final Matrix4 matrix = Matrix4.identity();
  matrix.translate(30, 30);
  matrix.scale(2, 1.5);
  canvas.transform(matrix.storage);
  canvas.drawCircle(ui.Offset.zero, 10, CkPaint());
  canvas.restore();

  canvas.translate(60, 0);
  final CkParagraph p = makeSimpleText('Hello', fontSize: 18, color: const ui.Color(0xFF0000AA));
  canvas.drawParagraph(
    p,
    const ui.Offset(10, 20),
  );

  canvas.translate(60, 0);
  canvas.drawPath(
    CkPath()
      ..moveTo(30, 20)
      ..lineTo(50, 50)
      ..lineTo(10, 50)
      ..close(),
    CkPaint()..color = const ui.Color(0xFF0000AA),
  );

  canvas.restore();
}

CkImage generateTestImage() {
  final DomCanvasElement canvas = createDomCanvasElement(width: 20, height: 20);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.fillStyle = '#FF0000';
  ctx.fillRect(0, 0, 10, 10);
  ctx.fillStyle = '#00FF00';
  ctx.fillRect(0, 10, 10, 10);
  ctx.fillStyle = '#0000FF';
  ctx.fillRect(10, 0, 10, 10);
  ctx.fillStyle = '#FF00FF';
  ctx.fillRect(10, 10, 10, 10);
  final Uint8List imageData =
      ctx.getImageData(0, 0, 20, 20).data.buffer.asUint8List();
  final SkImage skImage = canvasKit.MakeImage(
      SkImageInfo(
        width: 20,
        height: 20,
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
      ),
      imageData,
      4 * 20)!;
  return CkImage(skImage);
}

/// A convenience function for testing paragraph and text styles.
///
/// Renders a paragraph with two pieces of text, [outerText] and [innerText].
/// [outerText] is added to the root of the paragraph where only paragraph
/// style applies. [innerText] is added under a text style with properties
/// set from the arguments to this method. Parameters with prefix "paragraph"
/// are applied to the paragraph style. Others are applied to the text style.
///
/// [name] is the name of the test used as the description on the golden as
/// well as in the golden file name. Avoid special characters. Spaces are OK;
/// they are replaced by "_" in the file name.
///
/// Use [layoutWidth] to customize the width of the paragraph constraints.
Future<void> testTextStyle(
  // Test properties
  String name, {
  double? layoutWidth,
  // Top-level text where only paragraph style applies
  String outerText = 'Hello ',
  // Second-level text where paragraph and text styles both apply.
  String innerText = 'World!',

  // ParagraphStyle properties
  ui.TextAlign? paragraphTextAlign,
  ui.TextDirection? paragraphTextDirection,
  int? paragraphMaxLines,
  String? paragraphFontFamily,
  double? paragraphFontSize,
  double? paragraphHeight,
  ui.TextHeightBehavior? paragraphTextHeightBehavior,
  ui.FontWeight? paragraphFontWeight,
  ui.FontStyle? paragraphFontStyle,
  ui.StrutStyle? paragraphStrutStyle,
  String? paragraphEllipsis,
  ui.Locale? paragraphLocale,

  // TextStyle properties
  ui.Color? color,
  ui.TextDecoration? decoration,
  ui.Color? decorationColor,
  ui.TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  ui.FontWeight? fontWeight,
  ui.FontStyle? fontStyle,
  ui.TextBaseline? textBaseline,
  String? fontFamily,
  List<String>? fontFamilyFallback,
  double? fontSize,
  double? letterSpacing,
  double? wordSpacing,
  double? height,
  ui.TextLeadingDistribution? leadingDistribution,
  ui.Locale? locale,
  CkPaint? background,
  CkPaint? foreground,
  List<ui.Shadow>? shadows,
  List<ui.FontFeature>? fontFeatures,
}) async {
  late ui.Rect region;
  CkPicture renderPicture() {
    const double testWidth = 512;
    final CkPictureRecorder recorder = CkPictureRecorder();
    final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
    canvas.translate(30, 10);
    final CkParagraphBuilder descriptionBuilder =
        CkParagraphBuilder(CkParagraphStyle());
    descriptionBuilder.addText(name);
    final CkParagraph descriptionParagraph = descriptionBuilder.build();
    descriptionParagraph
        .layout(const ui.ParagraphConstraints(width: testWidth / 2 - 70));
    const ui.Offset descriptionOffset = ui.Offset(testWidth / 2 + 30, 0);
    canvas.drawParagraph(descriptionParagraph, descriptionOffset);

    final CkParagraphBuilder pb = CkParagraphBuilder(CkParagraphStyle(
      textAlign: paragraphTextAlign,
      textDirection: paragraphTextDirection,
      maxLines: paragraphMaxLines,
      fontFamily: paragraphFontFamily,
      fontSize: paragraphFontSize,
      height: paragraphHeight,
      textHeightBehavior: paragraphTextHeightBehavior,
      fontWeight: paragraphFontWeight,
      fontStyle: paragraphFontStyle,
      strutStyle: paragraphStrutStyle,
      ellipsis: paragraphEllipsis,
      locale: paragraphLocale,
    ));

    pb.addText(outerText);

    pb.pushStyle(CkTextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      background: background,
      foreground: foreground,
      shadows: shadows,
      fontFeatures: fontFeatures,
    ));
    pb.addText(innerText);
    pb.pop();
    final CkParagraph p = pb.build();
    p.layout(ui.ParagraphConstraints(width: layoutWidth ?? testWidth / 2));
    canvas.drawParagraph(p, ui.Offset.zero);

    canvas.drawPath(
      CkPath()
        ..moveTo(-10, 0)
        ..lineTo(-20, 0)
        ..lineTo(-20, p.height)
        ..lineTo(-10, p.height),
      CkPaint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawPath(
      CkPath()
        ..moveTo(testWidth / 2 + 10, 0)
        ..lineTo(testWidth / 2 + 20, 0)
        ..lineTo(testWidth / 2 + 20, p.height)
        ..lineTo(testWidth / 2 + 10, p.height),
      CkPaint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    const double padding = 20;
    region = ui.Rect.fromLTRB(
      0,
      0,
      testWidth,
      math.max(
        descriptionOffset.dy + descriptionParagraph.height + padding,
        p.height + padding,
      ),
    );
    return recorder.endRecording();
  }

  // Render once to trigger font downloads.
  final CkPicture picture = await generatePictureWhenFontsStable(renderPicture);
  await matchPictureGolden(
    'canvaskit_text_styles_${name.replaceAll(' ', '_')}.png',
    picture,
    region: region,
  );
  expect(notoDownloadQueue.debugIsLoadingFonts, isFalse);
  expect(notoDownloadQueue.pendingFonts, isEmpty);
  expect(notoDownloadQueue.downloader.debugActiveDownloadCount, 0);
}

typedef PictureGenerator = CkPicture Function();

Future<CkPicture> generatePictureWhenFontsStable(
    PictureGenerator generator) async {
  CkPicture picture = generator();
  // Fallback fonts start downloading as a post-frame callback.
  CanvasKitRenderer.instance.rasterizer.debugRunPostFrameCallbacks();
  // Font downloading begins asynchronously so we inject a timer before checking the download queue.
  await Future<void>.delayed(Duration.zero);
  while (notoDownloadQueue.isPending ||
      notoDownloadQueue.downloader.debugActiveDownloadCount > 0) {
    await notoDownloadQueue.debugWhenIdle();
    await notoDownloadQueue.downloader.debugWhenIdle();
    picture = generator();
    CanvasKitRenderer.instance.rasterizer.debugRunPostFrameCallbacks();
    // Dummy timer for the same reason as above.
    await Future<void>.delayed(Duration.zero);
  }
  return picture;
}
