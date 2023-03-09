// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../dom.dart';
import '../text/line_breaker.dart';
import 'canvaskit_api.dart';
import 'renderer.dart';

/// Injects required ICU data into the [builder].
///
/// This should only be used with the CanvasKit Chromium variant that's compiled
/// without ICU data.
void injectClientICU(SkParagraphBuilder builder) {
  assert(
    canvasKitVariant == CanvasKitVariant.chromium,
    'This method should only be used with the CanvasKit Chromium variant.',
  );

  final String text = builder.getText();
  builder.setWordsUtf16(
    fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.word),
  );
  builder.setGraphemeBreaksUtf16(
    fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.grapheme),
  );
  builder.setLineBreaksUtf16(fragmentUsingV8LineBreaker(text));
}

/// The granularity at which to segment text.
///
/// To find all supported granularities, see:
/// - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter/Segmenter
enum IntlSegmenterGranularity {
  grapheme,
  word,
}

final Map<IntlSegmenterGranularity, DomSegmenter> _intlSegmenters = <IntlSegmenterGranularity, DomSegmenter>{
  IntlSegmenterGranularity.grapheme: createIntlSegmenter(granularity: 'grapheme'),
  IntlSegmenterGranularity.word: createIntlSegmenter(granularity: 'word'),
};

SkUint32List fragmentUsingIntlSegmenter(
  String text,
  IntlSegmenterGranularity granularity,
) {
  final DomSegmenter segmenter = _intlSegmenters[granularity]!;
  final DomIteratorWrapper<DomSegment> iterator = segmenter.segment(text).iterator();

  final List<int> breaks = <int>[];
  while (iterator.moveNext()) {
    breaks.add(iterator.current.index);
  }
  breaks.add(text.length);

  final SkUint32List mallocedList = mallocUint32List(breaks.length);
  mallocedList.toTypedArray().setAll(0, breaks);
  return mallocedList;
}

// These are the soft/hard line break values expected by Skia's SkParagraph.
const int _kSoftLineBreak = 0;
const int _kHardLineBreak = 1;

final DomV8BreakIterator _v8LineBreaker = createV8BreakIterator();

SkUint32List fragmentUsingV8LineBreaker(String text) {
  final List<LineBreakFragment> fragments =
      breakLinesUsingV8BreakIterator(text, _v8LineBreaker);

  final int size = (fragments.length + 1) * 2;
  final SkUint32List mallocedList = mallocUint32List(size);
  final Uint32List typedArray = mallocedList.toTypedArray();

  typedArray[0] = 0; // start index
  typedArray[1] = _kSoftLineBreak; // break type

  for (int i = 0; i < fragments.length; i++) {
    final LineBreakFragment fragment = fragments[i];
    final int uint32Index = 2 + i * 2;
    typedArray[uint32Index] = fragment.end;
    typedArray[uint32Index + 1] = fragment.type == LineBreakType.mandatory
        ? _kHardLineBreak
        : _kSoftLineBreak;
  }

  return mallocedList;
}
