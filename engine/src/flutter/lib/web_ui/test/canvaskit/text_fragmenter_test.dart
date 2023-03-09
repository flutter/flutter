// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  late SkUint32List breaks;

  tearDown(() {
    if (browserSupportsCanvaskitChromium) {
      free(breaks);
    }
  });

  group('$fragmentUsingIntlSegmenter', () {
    test('fragments text into words', () {
      breaks = fragmentUsingIntlSegmenter(
        'Hello world 你好世界',
        IntlSegmenterGranularity.word,
      );
      expect(
        breaks.toTypedArray(),
        orderedEquals(<int>[0, 5, 6, 11, 12, 14, 16]),
      );
    });

    test('fragments multi-line text into words', () {
      breaks = fragmentUsingIntlSegmenter(
        'Lorem ipsum\ndolor 你好世界 sit\namet',
        IntlSegmenterGranularity.word,
      );
      expect(
        breaks.toTypedArray(),
        orderedEquals(<int>[
          0, 5, 6, 11, 12, // "Lorem ipsum\n"
          17, 18, 20, 22, 23, 26, 27, // "dolor 你好世界 sit\n"
          31, // "amet"
        ]),
      );
    });

    test('fragments text into grapheme clusters', () {
      // The smiley emoji has a length of 2.
      // The family emoji has a length of 11.
      breaks = fragmentUsingIntlSegmenter(
        'Lorem🙂ipsum👨‍👩‍👧‍👦',
        IntlSegmenterGranularity.grapheme,
      );
      expect(
        breaks.toTypedArray(),
        orderedEquals(<int>[
          0, 1, 2, 3, 4, 5, 7, // "Lorem🙂"
          8, 9, 10, 11, 12, 23, // "ipsum👨‍👩‍👧‍👦"
        ]),
      );
    });

    test('fragments multi-line text into grapheme clusters', () {
      // The smiley emojis have a length of 2 each.
      // The family emoji has a length of 11.
      breaks = fragmentUsingIntlSegmenter(
        'Lorem🙂\nipsum👨‍👩‍👧‍👦dolor\n😄',
        IntlSegmenterGranularity.grapheme,
      );
      expect(
        breaks.toTypedArray(),
        orderedEquals(<int>[
          0, 1, 2, 3, 4, 5, 7, 8, // "Lorem🙂\n"
          9, 10, 11, 12, 13, 24, // "ipsum👨‍👩‍👧‍👦"
          25, 26, 27, 28, 29, 30, 32, // "dolor😄\n"
        ]),
      );
    });
  }, skip: !browserSupportsCanvaskitChromium);

  group('$fragmentUsingV8LineBreaker', () {
    const int kSoft = 0;
    const int kHard = 1;

    test('fragments text into soft and hard line breaks', () {
      breaks = fragmentUsingV8LineBreaker(
        'Lorem-ipsum 你好🙂\nDolor sit',
      );
      expect(
        breaks.toTypedArray(),
        orderedEquals(<int>[
          0, kSoft,
          6, kSoft, // "Lorem-"
          12, kSoft, // "ipsum "
          13, kSoft, // "你"
          14, kSoft, // "好"
          17, kHard, // "🙂\n"
          23, kSoft, // "Dolor "
          26, kSoft, // "sit"
        ]),
      );
    });
  }, skip: !browserSupportsCanvaskitChromium);
}
