// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$fragmentUsingIntlSegmenter', () {
    test('fragments text into words', () {
      final Uint32List breaks = fragmentUsingIntlSegmenter(
        'Hello world 你好世界',
        IntlSegmenterGranularity.word,
      );
      expect(breaks, orderedEquals(<int>[0, 5, 6, 11, 12, 14, 16]));
    });

    test('fragments multi-line text into words', () {
      final Uint32List breaks = fragmentUsingIntlSegmenter(
        'Lorem ipsum\ndolor 你好世界 sit\namet',
        IntlSegmenterGranularity.word,
      );
      expect(
        breaks,
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
      final Uint32List breaks = fragmentUsingIntlSegmenter(
        'Lorem🙂ipsum👨‍👩‍👧‍👦',
        IntlSegmenterGranularity.grapheme,
      );
      expect(
        breaks,
        orderedEquals(<int>[
          0, 1, 2, 3, 4, 5, 7, // "Lorem🙂"
          8, 9, 10, 11, 12, 23, // "ipsum👨‍👩‍👧‍👦"
        ]),
      );
    });

    test('fragments multi-line text into grapheme clusters', () {
      // The smiley emojis have a length of 2 each.
      // The family emoji has a length of 11.
      final Uint32List breaks = fragmentUsingIntlSegmenter(
        'Lorem🙂\nipsum👨‍👩‍👧‍👦dolor\n😄',
        IntlSegmenterGranularity.grapheme,
      );
      expect(
        breaks,
        orderedEquals(<int>[
          0, 1, 2, 3, 4, 5, 7, 8, // "Lorem🙂\n"
          9, 10, 11, 12, 13, 24, // "ipsum👨‍👩‍👧‍👦"
          25, 26, 27, 28, 29, 30, 32, // "dolor😄\n"
        ]),
      );
    });
  }, skip: !browserSupportsCanvaskitChromium);

  group('$fragmentUsingV8LineBreaker', () {
    test('fragments text into soft and hard line breaks', () {
      final Uint32List breaks = fragmentUsingV8LineBreaker('Lorem-ipsum 你好🙂\nDolor sit');
      expect(
        breaks,
        orderedEquals(<int>[
          0, kSoftLineBreak,
          6, kSoftLineBreak, // "Lorem-"
          12, kSoftLineBreak, // "ipsum "
          13, kSoftLineBreak, // "你"
          14, kSoftLineBreak, // "好"
          17, kHardLineBreak, // "🙂\n"
          23, kSoftLineBreak, // "Dolor "
          26, kSoftLineBreak, // "sit"
        ]),
      );
    });
  }, skip: !browserSupportsCanvaskitChromium);

  group('segmentText', () {
    setUp(() {
      segmentationCache.clear();
    });

    tearDown(() {
      segmentationCache.clear();
    });

    test('segments correctly and computes words lazily', () {
      const text = 'Lorem-ipsum 你好🙂\nDolor sit';
      final SegmentationResult segmentation = segmentText(text);
      expect(segmentation.hasWords, isFalse);
      expect(
        segmentation.graphemes,
        fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.grapheme),
      );
      expect(segmentation.breaks, fragmentUsingV8LineBreaker(text));
      expect(segmentation.hasWords, isFalse);

      expect(segmentation.words, fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.word));
      expect(segmentation.hasWords, isTrue);

      // Subsequent lookups reuse the cached SegmentationResult with its computed words.
      expect(segmentText(text).hasWords, isTrue);
    });

    test('getWordBoundary returns word range and handles out-of-bounds offsets', () {
      const text = 'Hello world';
      final SegmentationResult segmentation = segmentText(text);
      expect(segmentation.hasWords, isFalse);

      expect(segmentation.getWordBoundary(0), const ui.TextRange(start: 0, end: 5));
      expect(segmentation.hasWords, isTrue);
      expect(segmentation.getWordBoundary(4), const ui.TextRange(start: 0, end: 5));
      expect(segmentation.getWordBoundary(5), const ui.TextRange(start: 5, end: 6));
      expect(segmentation.getWordBoundary(6), const ui.TextRange(start: 6, end: 11));
      expect(segmentation.getWordBoundary(10), const ui.TextRange(start: 6, end: 11));

      expect(
        segmentation.getWordBoundary(-1),
        const ui.TextRange(start: text.length, end: text.length),
      );
      expect(
        segmentation.getWordBoundary(text.length),
        const ui.TextRange(start: text.length, end: text.length),
      );
    });

    test('getWordBoundary handles empty text, whitespace-only text, and surrogate pairs', () {
      final SegmentationResult empty = segmentText('');
      expect(empty.getWordBoundary(0), const ui.TextRange(start: 0, end: 0));
      expect(empty.getWordBoundary(-1), const ui.TextRange(start: 0, end: 0));
      expect(empty.hasWords, isFalse);

      const spaces = '   ';
      final SegmentationResult whitespaceOnly = segmentText(spaces);
      expect(whitespaceOnly.getWordBoundary(0), const ui.TextRange(start: 0, end: 3));
      expect(whitespaceOnly.getWordBoundary(2), const ui.TextRange(start: 0, end: 3));
      expect(whitespaceOnly.getWordBoundary(3), const ui.TextRange(start: 3, end: 3));

      // 'Hi 🙂 there': 'Hi' [0..2], ' ' [2..3], '🙂' [3..5] (UTF-16 surrogate pair),
      // ' ' [5..6], 'there' [6..11].
      const emojiText = 'Hi 🙂 there';
      final SegmentationResult emoji = segmentText(emojiText);
      expect(emoji.getWordBoundary(0), const ui.TextRange(start: 0, end: 2));
      expect(emoji.getWordBoundary(2), const ui.TextRange(start: 2, end: 3));
      expect(emoji.getWordBoundary(3), const ui.TextRange(start: 3, end: 5));
      expect(emoji.getWordBoundary(4), const ui.TextRange(start: 3, end: 5));
      expect(emoji.getWordBoundary(5), const ui.TextRange(start: 5, end: 6));
      expect(emoji.getWordBoundary(6), const ui.TextRange(start: 6, end: 11));
    });

    test('caches segmentation results in LRU fashion', () {
      const text1 = 'hello';
      segmentText(text1);
      expect(segmentationCache.small.debugItemQueue, hasLength(1));
      expect(segmentationCache.small[text1], isNotNull);

      const text2 = 'world';
      segmentText(text2);
      expect(segmentationCache.small.debugItemQueue, hasLength(2));
      expect(segmentationCache.small[text2], isNotNull);

      // "world" was segmented last, so it should be first, as in most recently used.
      expect(segmentationCache.small.debugItemQueue.first.key, 'world');
      expect(segmentationCache.small.debugItemQueue.last.key, 'hello');
    });

    test('puts segmentation results in the appropriate cache', () {
      final String smallText = 'a' * (kSmallParagraphCacheSpec.maxTextLength - 1);
      segmentText(smallText);
      expect(segmentationCache.small.debugItemQueue, hasLength(1));
      expect(segmentationCache.medium.debugItemQueue, hasLength(0));
      expect(segmentationCache.large.debugItemQueue, hasLength(0));
      expect(segmentationCache.small[smallText], isNotNull);
      segmentationCache.clear();

      final String mediumText = 'a' * (kMediumParagraphCacheSpec.maxTextLength - 1);
      segmentText(mediumText);
      expect(segmentationCache.small.debugItemQueue, hasLength(0));
      expect(segmentationCache.medium.debugItemQueue, hasLength(1));
      expect(segmentationCache.large.debugItemQueue, hasLength(0));
      expect(segmentationCache.medium[mediumText], isNotNull);
      segmentationCache.clear();

      final String largeText = 'a' * (kLargeParagraphCacheSpec.maxTextLength - 1);
      segmentText(largeText);
      expect(segmentationCache.small.debugItemQueue, hasLength(0));
      expect(segmentationCache.medium.debugItemQueue, hasLength(0));
      expect(segmentationCache.large.debugItemQueue, hasLength(1));
      expect(segmentationCache.large[largeText], isNotNull);
      segmentationCache.clear();

      // Should not cache extremely large texts.
      final String tooLargeText = 'a' * (kLargeParagraphCacheSpec.maxTextLength + 1);
      segmentText(tooLargeText);
      expect(segmentationCache.small.debugItemQueue, hasLength(0));
      expect(segmentationCache.medium.debugItemQueue, hasLength(0));
      expect(segmentationCache.large.debugItemQueue, hasLength(0));
      segmentationCache.clear();
    });

    test('has a limit on the number of entries', () {
      testCacheCapacity(segmentationCache.small, kSmallParagraphCacheSpec);
      testCacheCapacity(segmentationCache.medium, kMediumParagraphCacheSpec);
      testCacheCapacity(segmentationCache.large, kLargeParagraphCacheSpec);
    }, timeout: const Timeout.factor(4));
  }, skip: !browserSupportsCanvaskitChromium);
}

void testCacheCapacity(LruCache<String, SegmentationResult> cache, SegmentationCacheSpec spec) {
  // 1. Fill the cache.
  for (var i = 0; i < spec.cacheSize; i++) {
    final String text = _randomString(spec.maxTextLength);
    segmentText(text);
    // The segmented text should have been added to the cache.
    // TODO(mdebbar): This may fail if the random string generator generates
    //                the same string twice.
    expect(cache.debugItemQueue, hasLength(i + 1));
  }

  // 2. Make sure the cache is full.
  expect(cache.length, spec.cacheSize);

  // 3. Add more items to the cache.
  for (var i = 0; i < 10; i++) {
    final String text = _randomString(spec.maxTextLength);
    segmentText(text);
    // The cache size should remain the same.
    expect(cache.debugItemQueue, hasLength(spec.cacheSize));
  }

  // 4. Clear the cache.
  cache.clear();
}

int _seed = 0;

String _randomString(int length) {
  const allChars =
      ' 1234567890'
      'abcdefghijklmnopqrstuvwxyz'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final String text = '*' * length;
  return text.replaceAllMapped(
    '*',
    // Passing a seed so the results are reproducible.
    (_) => allChars[Random(_seed++).nextInt(allChars.length)],
  );
}
