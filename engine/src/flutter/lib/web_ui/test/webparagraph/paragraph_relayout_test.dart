// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  WebParagraph build(
    void Function(WebParagraphBuilder builder) addContent, {
    TextDirection textDirection = TextDirection.ltr,
    WebTextStyle? textStyle,
  }) {
    final builder = WebParagraphBuilder(
      WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20, textDirection: textDirection),
    );
    builder.pushStyle(textStyle ?? WebTextStyle(color: const Color(0xFF000000)));
    addContent(builder);
    return builder.build();
  }

  final cases = <String, WebParagraph Function()>{
    'latin with trailing spaces': () =>
        build((b) => b.addText('Hello world,   quick brown fox  ' * 4)),
    'letter and word spacing': () => build(
      (b) => b.addText('Spaced letters and words here ' * 3),
      textStyle: WebTextStyle(color: const Color(0xFF000000), letterSpacing: 2, wordSpacing: 5),
    ),
    'ligatures and kerning': () => build((b) => b.addText('office affine AVATAR WAVE To Ty ' * 3)),
    'RTL paragraph': () => build(
      (b) => b.addText(
        '\u0645\u0631\u062D\u0628\u0627 \u0628\u0627\u0644\u0639\u0627\u0644\u0645 42 ' * 4,
      ),
      textDirection: TextDirection.rtl,
    ),
    'multi-span BiDi': () => build((b) {
      b.addText('Hello, ');
      b.pushStyle(WebTextStyle(color: const Color(0xFF0000FF), fontWeight: FontWeight.bold));
      b.addText('world \u05E9\u05DC\u05D5\u05DD (\u05E2\u05D5\u05DC\u05DD) 123 ');
      b.pop();
      b.addText('tail \u0645\u0631\u062D\u0628\u0627 end');
    }, textDirection: TextDirection.rtl),
    'emoji': () => build(
      (b) => b.addText('Hi \u{1F44D}\u{1F3FD} \u{1F468}\u200D\u{1F469}\u200D\u{1F467} ok ' * 3),
    ),
    'hard line breaks': () => build((b) => b.addText('First line\nSecond  \n\nFourth line\n')),
    'placeholders': () => build((b) {
      b.addText('Before ');
      b.addPlaceholder(30, 20, PlaceholderAlignment.middle);
      b.addText(' after the placeholder and more text');
    }),
  };

  group('re-layout block geometry', () {
    for (final MapEntry<String, WebParagraph Function()> entry in cases.entries) {
      test('block advance matches the span metrics: ${entry.key}', () {
        final WebParagraph paragraph = entry.value();
        for (final width in <double>[500, 120, 260, 80]) {
          paragraph.layout(ParagraphConstraints(width: width));
          var blocks = 0;
          for (final TextLine line in paragraph.lines) {
            for (final LineBlock block in line.visualBlocks) {
              if (block is! TextBlock || block is EllipsisBlock) {
                continue;
              }
              blocks++;
              expect(
                block.advance,
                block.span.getBlockSelection(block),
                reason: 'width $width, block ${block.textRange}',
              );
            }
          }
          expect(blocks, greaterThan(0));
        }
        paragraph.dispose();
      });
    }
  });
}
