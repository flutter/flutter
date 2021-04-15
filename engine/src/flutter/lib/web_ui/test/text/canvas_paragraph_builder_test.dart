// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

bool get isIosSafari => browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs;

String fontFamilyToAttribute(String fontFamily) {
  fontFamily = canonicalizeFontFamily(fontFamily)!;
  if (browserEngine == BrowserEngine.firefox) {
    fontFamily = fontFamily.replaceAll('"', '&quot;');
  } else if (browserEngine == BrowserEngine.blink ||
      browserEngine == BrowserEngine.samsung ||
      browserEngine == BrowserEngine.webkit) {
    fontFamily = fontFamily.replaceAll('"', '');
  }
  return 'font-family: $fontFamily;';
}

final String defaultFontFamily = fontFamilyToAttribute('Ahem');
const String defaultColor = 'color: rgb(255, 0, 0);';
const String defaultFontSize = 'font-size: 14px;';
final String paragraphStyle =
    'position: absolute; white-space: pre;';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  await webOnlyInitializeTestDomRenderer();

  setUpAll(() {
    WebExperiments.ensureInitialized();
  });

  test('Builds a text-only canvas paragraph', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor font-size: 13px; $defaultFontFamily">'
      'Hello'
      '</span>'
      '</p>',
    );

    // Should break "Hello" into "Hel" and "lo".
    paragraph.layout(ParagraphConstraints(width: 39.0));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor font-size: 13px; $defaultFontFamily">'
      'Hel<br>lo'
      '</span>'
      '</p>',
    );

    final ParagraphSpan span = paragraph.spans.single;
    expect(span, isA<FlatTextSpan>());
    final FlatTextSpan textSpan = span as FlatTextSpan;
    expect(textSpan.textOf(paragraph), 'Hello');
    expect(textSpan.style, styleWithDefaults(fontSize: 13.0));
  });

  test('Correct defaults', () {
    final EngineParagraphStyle style = EngineParagraphStyle();
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="$defaultFontSize $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor $defaultFontSize $defaultFontFamily">'
      'Hello'
      '</span>'
      '</p>',
    );

    final FlatTextSpan textSpan = paragraph.spans.single as FlatTextSpan;
    expect(textSpan.style, styleWithDefaults());
  });

  test('Sets correct styles for max-lines', () {
    final EngineParagraphStyle style = EngineParagraphStyle(maxLines: 2);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'Hello');

    double expectedHeight = 14.0;
    if (isIosSafari) {
      // On iOS Safari, the height measurement is one extra pixel.
      expectedHeight++;
    }
    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="$defaultFontSize $defaultFontFamily $paragraphStyle overflow-y: hidden; height: ${expectedHeight}px;">'
      '<span style="$defaultColor $defaultFontSize $defaultFontFamily">'
      'Hello'
      '</span>'
      '</p>',
    );
  });

  test('Sets correct styles for ellipsis', () {
    final EngineParagraphStyle style = EngineParagraphStyle(ellipsis: '...');
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('HelloWorld');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.paragraphStyle, style);
    expect(paragraph.toPlainText(), 'HelloWorld');

    double expectedHeight = 14.0;
    if (isIosSafari) {
      // On iOS Safari, the height measurement is one extra pixel.
      expectedHeight++;
    }
    paragraph.layout(ParagraphConstraints(width: 100.0));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="$defaultFontSize $defaultFontFamily $paragraphStyle width: 100px; overflow-y: hidden; height: ${expectedHeight}px;">'
      '<span style="$defaultColor $defaultFontSize $defaultFontFamily">'
      'Hell...'
      '</span>'
      '</p>',
    );
  });

  test('Builds a single-span paragraph with complex styles', () {
    final EngineParagraphStyle style =
        EngineParagraphStyle(fontSize: 13.0, height: 1.5);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontSize: 9.0));
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.pushStyle(TextStyle(fontSize: 40.0));
    builder.pop();
    builder
        .pushStyle(TextStyle(fontStyle: FontStyle.italic, letterSpacing: 2.0));
    builder.addText('Hello');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello');
    expect(paragraph.spans, hasLength(1));

    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="line-height: 1.5; font-size: 9px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor line-height: 1.5; font-size: 9px; font-weight: bold; font-style: italic; $defaultFontFamily letter-spacing: 2px;">'
      'Hello'
      '</span>'
      '</p>',
    );

    final FlatTextSpan span = paragraph.spans.single as FlatTextSpan;
    expect(span.textOf(paragraph), 'Hello');
    expect(
      span.style,
      styleWithDefaults(
        height: 1.5,
        fontSize: 9.0,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 2.0,
      ),
    );
  });

  test('Builds a multi-span paragraph', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.addText('Hello');
    builder.pop();
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText(' world');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello world');
    expect(paragraph.spans, hasLength(2));

    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor font-size: 13px; font-weight: bold; $defaultFontFamily">'
      'Hello'
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-style: italic; $defaultFontFamily">'
      ' world'
      '</span>'
      '</p>',
    );

    // Should break "Hello world" into "Hello" and " world".
    paragraph.layout(ParagraphConstraints(width: 75.0));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle width: 75px;">'
      '<span style="$defaultColor font-size: 13px; font-weight: bold; $defaultFontFamily">'
      'Hello'
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-style: italic; $defaultFontFamily">'
      ' <br>world'
      '</span>'
      '</p>',
    );

    final FlatTextSpan hello = paragraph.spans.first as FlatTextSpan;
    expect(hello.textOf(paragraph), 'Hello');
    expect(
      hello.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
      ),
    );

    final FlatTextSpan world = paragraph.spans.last as FlatTextSpan;
    expect(world.textOf(paragraph), ' world');
    expect(
      world.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontStyle: FontStyle.italic,
      ),
    );
  });

  test('Builds a multi-span paragraph with complex styles', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.pushStyle(TextStyle(height: 2.0));
    builder.addText('Hello');
    builder.pop(); // pop TextStyle(height: 2.0).
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText(' world');
    builder.pushStyle(TextStyle(fontWeight: FontWeight.normal));
    builder.addText('!');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'Hello world!');
    expect(paragraph.spans, hasLength(3));

    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor line-height: 2; font-size: 13px; font-weight: bold; $defaultFontFamily">'
      'Hello'
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-weight: bold; font-style: italic; $defaultFontFamily">'
      ' world'
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-weight: normal; font-style: italic; $defaultFontFamily">'
      '!'
      '</span>'
      '</p>',
    );

    final FlatTextSpan hello = paragraph.spans[0] as FlatTextSpan;
    expect(hello.textOf(paragraph), 'Hello');
    expect(
      hello.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
        height: 2.0,
      ),
    );

    final FlatTextSpan world = paragraph.spans[1] as FlatTextSpan;
    expect(world.textOf(paragraph), ' world');
    expect(
      world.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );

    final FlatTextSpan bang = paragraph.spans[2] as FlatTextSpan;
    expect(bang.textOf(paragraph), '!');
    expect(
      bang.style,
      styleWithDefaults(
        fontSize: 13.0,
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.italic,
      ),
    );
  });

  test('Paragraph with new lines generates correct DOM', () {
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 13.0);
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('First\nSecond ');
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText('ThirdLongLine');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'First\nSecond ThirdLongLine');
    expect(paragraph.spans, hasLength(2));

    // There's a new line between "First" and "Second", but "Second" and
    // "ThirdLongLine" remain together since constraints are infinite.
    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle">'
      '<span style="$defaultColor font-size: 13px; $defaultFontFamily">'
      'First<br>Second '
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-style: italic; $defaultFontFamily">'
      'ThirdLongLine'
      '</span>'
      '</p>',
    );

    // Should break the paragraph into "First", "Second" and "ThirdLongLine".
    paragraph.layout(ParagraphConstraints(width: 180.0));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 13px; $defaultFontFamily $paragraphStyle width: 180px;">'
      '<span style="$defaultColor font-size: 13px; $defaultFontFamily">'
      'First<br>Second <br>'
      '</span>'
      '<span style="$defaultColor font-size: 13px; font-style: italic; $defaultFontFamily">'
      'ThirdLongLine'
      '</span>'
      '</p>',
    );
  });

  test('various font sizes', () {
    // Paragraphs and spans force the Ahem font in test mode. We need to trick
    // them into thinking they are not in test mode, so they use the provided
    // font family.
    debugEmulateFlutterTesterEnvironment = false;
    final EngineParagraphStyle style = EngineParagraphStyle(fontSize: 12.0, fontFamily: 'first');
    final CanvasParagraphBuilder builder = CanvasParagraphBuilder(style);

    builder.addText('First ');
    builder.pushStyle(TextStyle(fontSize: 18.0, fontFamily: 'second'));
    builder.addText('Second ');
    builder.pushStyle(TextStyle(fontSize: 10.0, fontFamily: 'third'));
    builder.addText('Third');

    final CanvasParagraph paragraph = builder.build();
    expect(paragraph.toPlainText(), 'First Second Third');
    expect(paragraph.spans, hasLength(3));

    // The paragraph should take the font size and family from the span with the
    // greatest font size.
    paragraph.layout(ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.toDomElement().outerHtml,
      '<p style="font-size: 18px; ${fontFamilyToAttribute('second')} $paragraphStyle">'
      '<span style="$defaultColor font-size: 12px; ${fontFamilyToAttribute('first')}">'
      'First '
      '</span>'
      '<span style="$defaultColor font-size: 18px; ${fontFamilyToAttribute('second')}">'
      'Second '
      '</span>'
      '<span style="$defaultColor font-size: 10px; ${fontFamilyToAttribute('third')}">'
      'Third'
      '</span>'
      '</p>',
    );
    debugEmulateFlutterTesterEnvironment = true;
  });
}

TextStyle styleWithDefaults({
  Color color = const Color(0xFFFF0000),
  String fontFamily = DomRenderer.defaultFontFamily,
  double fontSize = DomRenderer.defaultFontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    height: height,
    letterSpacing: letterSpacing,
  );
}
