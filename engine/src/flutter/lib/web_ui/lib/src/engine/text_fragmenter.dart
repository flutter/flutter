// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import 'dom.dart';
import 'text/line_breaker.dart';
import 'util.dart';

/// Holds grapheme, line break, and lazy word segmentation boundaries for [text].
class SegmentationResult {
  SegmentationResult({required this.text, required this.graphemes, required this.breaks});

  final String text;
  final Uint32List graphemes;
  final Uint32List breaks;

  Uint32List? _words;

  /// Returns whether word boundaries have been computed for [text].
  @visibleForTesting
  bool get hasWords => _words != null;

  /// Word boundaries in UTF-16 code unit offsets, computed lazily on first access.
  Uint32List get words =>
      _words ??= fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.word);

  /// Finds the word boundary containing [offset] in UTF-16 code units, matching
  /// SkParagraph's `ParagraphImpl::getWordBoundary(unsigned offset)` contract.
  ui.TextRange getWordBoundary(int offset) {
    // Out-of-bounds or negative offsets return an empty range at text.length,
    // matching C++ ParagraphImpl::getWordBoundary(unsigned offset).
    if (offset < 0 || offset >= text.length) {
      return ui.TextRange(start: text.length, end: text.length);
    }

    // Binary search for the first break strictly greater than offset.
    // Because fragmentUsingIntlSegmenter starts at 0 and ends at text.length,
    // and 0 <= offset < text.length, wordBreaks[0] <= offset < wordBreaks.last
    // is guaranteed.
    final Uint32List wordBreaks = words;
    var low = 0;
    int high = wordBreaks.length - 1;
    while (low + 1 < high) {
      final int mid = (low + high) >>> 1;
      if (wordBreaks[mid] <= offset) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return ui.TextRange(start: wordBreaks[low], end: wordBreaks[high]);
  }
}

// The cache numbers below were picked based on the following logic.
//
// Most paragraphs in an app are small (e.g. icons, button labels, etc). These
// paragraphs are also cheap to cache. So we cache a lot of them. 100,000 of
// them amounts to a worst case of 5MB (10-character long text + words uint list
// + graphemes uint list + breaks uint list).
//
// Large paragraphs are less common (a handful per page), but are expensive to
// cache. So we cache fewer of them. 20 of them at a length of 50,000 characters
// amount to a memory usage of 5MB (50,000-character long text + words uint list
// + graphemes uint list + breaks uint list).
//
// Medium paragraphs are somewhere in between. 10,000 of them amount to a worst
// case of 5MB (100-character long text + words uint list + graphemes uint list
// + breaks uint list).

typedef SegmentationCacheSpec = ({int cacheSize, int maxTextLength});

const SegmentationCacheSpec kSmallParagraphCacheSpec = (cacheSize: 100000, maxTextLength: 10);
const SegmentationCacheSpec kMediumParagraphCacheSpec = (cacheSize: 10000, maxTextLength: 100);
const SegmentationCacheSpec kLargeParagraphCacheSpec = (cacheSize: 20, maxTextLength: 50000);

typedef SegmentationCache = ({
  LruCache<String, SegmentationResult> small,
  LruCache<String, SegmentationResult> medium,
  LruCache<String, SegmentationResult> large,
});

/// Caches segmentation results for small, medium and large paragraphts.
///
/// Paragraphs are frequently re-created because of style or font changes, while
/// their text contents remain the same. This cache is effective at
/// short-circuiting the segmentation of such paragraphs.
final SegmentationCache segmentationCache = (
  small: LruCache<String, SegmentationResult>(kSmallParagraphCacheSpec.cacheSize),
  medium: LruCache<String, SegmentationResult>(kMediumParagraphCacheSpec.cacheSize),
  large: LruCache<String, SegmentationResult>(kLargeParagraphCacheSpec.cacheSize),
);

extension SegmentationCacheExtensions on SegmentationCache {
  /// Gets the appropriate cache for the given [text].
  LruCache<String, SegmentationResult>? getCacheForText(String text) {
    if (text.length <= kSmallParagraphCacheSpec.maxTextLength) {
      return small;
    }
    if (text.length <= kMediumParagraphCacheSpec.maxTextLength) {
      return medium;
    }
    if (text.length <= kLargeParagraphCacheSpec.maxTextLength) {
      return large;
    }
    return null;
  }

  /// Clears all the caches.
  void clear() {
    small.clear();
    medium.clear();
    large.clear();
  }
}

/// Segments the [text] into words, graphemes and line breaks.
///
/// Caches results in [segmentationCache].
SegmentationResult segmentText(String text) {
  final LruCache<String, SegmentationResult>? cache = segmentationCache.getCacheForText(text);
  final SegmentationResult? cachedResult = cache?[text];

  final SegmentationResult result;
  if (cachedResult != null) {
    result = cachedResult;
  } else {
    // Word boundaries are only needed when getWordBoundary() is queried, so
    // SegmentationResult.words computes them lazily on demand.
    result = SegmentationResult(
      text: text,
      graphemes: fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.grapheme),
      breaks: fragmentUsingV8LineBreaker(text),
    );
  }

  // Save or promote to most recently used.
  cache?.cache(text, result);
  return result;
}

/// The granularity at which to segment text.
///
/// To find all supported granularities, see:
/// - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter/Segmenter
enum IntlSegmenterGranularity { grapheme, word }

final Map<IntlSegmenterGranularity, DomSegmenter> _intlSegmenters =
    <IntlSegmenterGranularity, DomSegmenter>{
      IntlSegmenterGranularity.grapheme: createIntlSegmenter(granularity: 'grapheme'),
      IntlSegmenterGranularity.word: createIntlSegmenter(granularity: 'word'),
    };

Uint32List fragmentUsingIntlSegmenter(String text, IntlSegmenterGranularity granularity) {
  final DomSegmenter segmenter = _intlSegmenters[granularity]!;
  final DomIteratorWrapper<DomSegment> iterator = segmenter.segment(text).iterator();

  final breaks = <int>[];
  while (iterator.moveNext()) {
    breaks.add(iterator.current.index);
  }
  breaks.add(text.length);
  return Uint32List.fromList(breaks);
}

// These are the soft/hard line break values expected by Skia's SkParagraph.
const int kSoftLineBreak = 0;
const int kHardLineBreak = 100;

final DomV8BreakIterator _v8LineBreaker = createV8BreakIterator();

Uint32List fragmentUsingV8LineBreaker(String text) {
  final List<LineBreakFragment> fragments = breakLinesUsingV8BreakIterator(
    text,
    text.toJS,
    _v8LineBreaker,
  );

  final int size = (fragments.length + 1) * 2;
  final typedArray = Uint32List(size);

  typedArray[0] = 0; // start index
  typedArray[1] = kSoftLineBreak; // break type

  for (var i = 0; i < fragments.length; i++) {
    final LineBreakFragment fragment = fragments[i];
    final int uint32Index = 2 + i * 2;
    typedArray[uint32Index] = fragment.end;
    typedArray[uint32Index + 1] = fragment.type == LineBreakType.mandatory
        ? kHardLineBreak
        : kSoftLineBreak;
  }

  return typedArray;
}
