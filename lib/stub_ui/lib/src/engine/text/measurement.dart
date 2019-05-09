// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Measures paragraphs of text using a shared top-level absolutely positioned
/// element and [ParagraphRuler]s.
class TextMeasurementService {
  TextMeasurementService._({@required this.rulerCacheCapacity}) {
    _rulerHost.style
      ..position = 'fixed'
      ..visibility = 'hidden'
      ..overflow = 'hidden'
      ..top = '0'
      ..left = '0'
      ..width = '0'
      ..height = '0';
    html.document.body.append(_rulerHost);
    registerHotRestartListener(() {
      _rulerHost?.remove();
    });
  }

  /// Initializes the text measurement service singleton.
  static TextMeasurementService initialize({@required int rulerCacheCapacity}) {
    _instance =
        TextMeasurementService._(rulerCacheCapacity: rulerCacheCapacity);
    return _instance;
  }

  /// The text measurement service singleton.
  static TextMeasurementService get instance => _instance;
  static TextMeasurementService _instance;

  final int rulerCacheCapacity;

  final html.CanvasRenderingContext2D canvasContext =
      html.CanvasElement().context2D;

  /// Hosts a cache of rulers that measure text.
  ///
  /// This element exists purely for organizational purposes. Otherwise the
  /// rulers would be attached to the `<body>` element polluting the element
  /// tree and making it hard to navigate. It does not serve any functional
  /// purpose.
  final html.Element _rulerHost = html.Element.tag('flt-ruler-host');

  /// The cache of rulers used to measure text.
  ///
  /// Each ruler is keyed by paragraph style. This allows us to setup the
  /// ruler's DOM structure once during the very first measurement of a given
  /// paragraph style. Subsequent measurements could reuse the same ruler and
  /// only swap the text contents. This minimizes the amount of work a browser
  /// needs to do when measure many pieces of text with the same style.
  ///
  /// What makes this cache effective is the fact that a typical application
  /// only uses a limited number of text styles. Using too many text styles on
  /// the same screen is considered bad for user experience.
  Map<ParagraphGeometricStyle, ParagraphRuler> get rulers => _rulers;
  Map<ParagraphGeometricStyle, ParagraphRuler> _rulers =
      <ParagraphGeometricStyle, ParagraphRuler>{};

  bool _rulerCacheCleanupScheduled = false;

  void _scheduleRulerCacheCleanup() {
    if (!_rulerCacheCleanupScheduled) {
      _rulerCacheCleanupScheduled = true;
      scheduleMicrotask(() {
        _rulerCacheCleanupScheduled = false;
        cleanUpRulerCache();
      });
    }
  }

  /// If ruler cache size exceeds [rulerCacheCapacity], evicts those rulers that
  /// were used the least.
  ///
  /// Resets hit counts back to zero.
  void cleanUpRulerCache() {
    if (_rulers.length > rulerCacheCapacity) {
      List<ParagraphRuler> sortedByUsage = _rulers.values.toList();
      sortedByUsage.sort((ParagraphRuler a, ParagraphRuler b) {
        return b.hitCount - a.hitCount;
      });
      _rulers = <ParagraphGeometricStyle, ParagraphRuler>{};
      for (int i = 0; i < sortedByUsage.length; i++) {
        var ruler = sortedByUsage[i];
        ruler.resetHitCount();
        if (i < rulerCacheCapacity) {
          // Retain this ruler.
          _rulers[ruler.style] = ruler;
        } else {
          // This ruler did not have enough usage this frame to be retained.
          ruler.dispose();
        }
      }
    }
  }

  /// Adds an element used for measuring text as a child of [_rulerHost].
  void addHostElement(html.DivElement element) {
    _rulerHost.append(element);
  }

  /// Measures the paragraph and sets the values directly on the [paragraph]
  /// object.
  void measure(ui.Paragraph paragraph, ui.ParagraphConstraints constraints) {
    final ParagraphGeometricStyle style =
        paragraph.webOnlyGetParagraphGeometricStyle();
    final ParagraphRuler ruler = _findOrCreateRuler(style);

    if (assertionsEnabled) {
      if (paragraph.webOnlyGetPlainText() == null) {
        domRenderer.debugRichTextLayout();
      } else {
        domRenderer.debugPlainTextLayout();
      }
    }

    RulerCacheEntry cacheEntry = ruler.cacheLookup(paragraph, constraints);
    if (cacheEntry != null) {
      cacheEntry.applyToParagraph(paragraph);
      ruler._hitCount++;
      return;
    }

    ruler.willMeasure(paragraph);
    ruler.measureAll(constraints);

    final String plainText = paragraph.webOnlyGetPlainText();
    // When the text has a new line, we should always use multi-line mode.
    final bool hasNewline = plainText?.contains('\n') ?? false;
    if (!hasNewline && ruler.singleLineDimensions.width <= constraints.width) {
      _measureSingleLineParagraph(ruler, paragraph, constraints);
    } else {
      // Assert: If text doesn't have new line for infinite constraints we
      // should have called single line measure paragraph instead.
      assert(hasNewline || constraints.width != double.infinity);
      _measureMultiLineParagraph(ruler, paragraph, constraints);
    }
    ruler.didMeasure();
  }

  /// Performs measurements on the given [paragraph] as a single line with no
  /// constraints.
  ///
  /// This method has no side-effects as it doesn't mutate the
  /// paragraph, unlike [measure].
  TextDimensions measureSingleLineText(ui.Paragraph paragraph) {
    final style = paragraph.webOnlyGetParagraphGeometricStyle();
    final ParagraphRuler ruler = _findOrCreateRuler(style);

    ruler.willMeasure(paragraph);
    ruler.measureAsSingleLine();
    final TextDimensions dimensions = ruler.singleLineDimensions;
    ruler.didMeasure();
    return dimensions;
  }

  /// Measures the width of the given [paragraph] as a single line with no
  /// constraints.
  ///
  /// Since only the width is needed, this method uses the [measureText] Canvas
  /// API which is significantly faster than DOM measurement.
  double measureSingleLineWidth(String text, ParagraphGeometricStyle style) {
    assert(
        style.letterSpacing == null &&
            style.wordSpacing == null &&
            style.decoration == null,
        'Cannot measure text using canvas if it uses '
        'letter spacing, word spacing or decoration: $style');
    canvasContext.font = style.cssFontString;
    return canvasContext.measureText(text).width;
  }

  /// Delegates to a [ParagraphRuler] to measure a list of text boxes that
  /// enclose the given range of text.
  List<ui.TextBox> measureBoxesForRange(
    ui.Paragraph paragraph,
    ui.ParagraphConstraints constraints, {
    int start,
    int end,
    double alignOffset,
    ui.TextDirection textDirection,
  }) {
    final ParagraphGeometricStyle style =
        paragraph.webOnlyGetParagraphGeometricStyle();
    final ParagraphRuler ruler = _findOrCreateRuler(style);

    return ruler.measureBoxesForRange(
      paragraph.webOnlyGetPlainText(),
      constraints,
      start: start,
      end: end,
      alignOffset: alignOffset,
      textDirection: textDirection,
    );
  }

  ParagraphRuler _findOrCreateRuler(ParagraphGeometricStyle style) {
    final ParagraphRuler ruler = _rulers[style];
    if (ruler != null) {
      if (assertionsEnabled) {
        domRenderer.debugRulerCacheHit();
      }
      return ruler;
    }

    if (assertionsEnabled) {
      domRenderer.debugRulerCacheMiss();
    }
    _scheduleRulerCacheCleanup();
    return _rulers[style] = ParagraphRuler(style);
  }

  // TODO(yjbanov): this is a hack we use to compute ideographic baseline; this
  //                number is the ratio ideographic/alphabetic for font Ahem,
  //                which matches the Flutter number. It may be completely wrong
  //                for any other font. We'll need to eventually fix this. That
  //                said Flutter doesn't seem to use ideographic baseline for
  //                anything as of this writing.
  static const _baselineRatioHack = 1.1662499904632568;

  /// Called when we have determined that the paragraph fits the [constraints]
  /// without wrapping.
  ///
  /// This means that:
  /// * `width == maxIntrinsicWidth` - we gave it more horizontal space than
  ///   it needs and so the paragraph won't expand beyond `maxIntrinsicWidth`.
  /// * `height` is the height computed by `measureAsSingleLine`; giving the
  ///    paragraph the width constraint won't change its height as we already
  ///    determined that it fits within the constraint without wrapping.
  /// * `alphabeticBaseline` is also final for the same reason as the `height`
  ///   value.
  ///
  /// This method still needs to measure `minIntrinsicWidth`.
  void _measureSingleLineParagraph(ParagraphRuler ruler, ui.Paragraph paragraph,
      ui.ParagraphConstraints constraints) {
    final double width = constraints.width;
    final double minIntrinsicWidth = ruler.minIntrinsicDimensions.width;
    double maxIntrinsicWidth = ruler.singleLineDimensions.width;
    final double alphabeticBaseline = ruler.alphabeticBaseline;
    final double height = ruler.singleLineDimensions.height;

    maxIntrinsicWidth =
        _applySubPixelRoundingHack(minIntrinsicWidth, maxIntrinsicWidth);
    final ideographicBaseline = alphabeticBaseline * _baselineRatioHack;
    final cacheEntry = RulerCacheEntry(constraints.width,
        isSingleLine: true,
        width: width,
        height: height,
        lineHeight: height,
        minIntrinsicWidth: minIntrinsicWidth,
        maxIntrinsicWidth: maxIntrinsicWidth,
        alphabeticBaseline: alphabeticBaseline,
        ideographicBaseline: ideographicBaseline);
    ruler.cacheMeasurement(paragraph, constraints, cacheEntry);
    cacheEntry.applyToParagraph(paragraph);
  }

  /// Called when we have determined that the paragraph needs to wrap into
  /// multiple lines to fit the [constraints], i.e. its `maxIntrinsicWidth` is
  /// bigger than the available horizontal space.
  ///
  /// While `maxIntrinsicWidth` is still good from the call to
  /// `measureAsSingleLine`, we need to re-measure with the width constraint
  /// and get new values for width, height and alphabetic baseline. We also need
  /// to measure `minIntrinsicWidth`.
  void _measureMultiLineParagraph(ParagraphRuler ruler, ui.Paragraph paragraph,
      ui.ParagraphConstraints constraints) {
    // If constraint is infinite, we must use _measureSingleLineParagraph
    final double width = constraints.width;
    final double minIntrinsicWidth = ruler.minIntrinsicDimensions.width;
    double maxIntrinsicWidth = ruler.singleLineDimensions.width;
    final double alphabeticBaseline = ruler.alphabeticBaseline;
    final double height = ruler.constrainedDimensions.height;

    double lineHeight = height;
    if (paragraph.webOnlyGetParagraphGeometricStyle().maxLines != null) {
      lineHeight = ruler.lineHeightDimensions.height;
    }

    maxIntrinsicWidth =
        _applySubPixelRoundingHack(minIntrinsicWidth, maxIntrinsicWidth);
    assert(minIntrinsicWidth <= maxIntrinsicWidth);
    final ideographicBaseline = alphabeticBaseline * _baselineRatioHack;
    final cacheEntry = RulerCacheEntry(constraints.width,
        isSingleLine: false,
        width: width,
        height: height,
        lineHeight: lineHeight,
        minIntrinsicWidth: minIntrinsicWidth,
        maxIntrinsicWidth: maxIntrinsicWidth,
        alphabeticBaseline: alphabeticBaseline,
        ideographicBaseline: ideographicBaseline);
    ruler.cacheMeasurement(paragraph, constraints, cacheEntry);
    cacheEntry.applyToParagraph(paragraph);
  }

  /// This hack is needed because `offsetWidth` rounds the value to the nearest
  /// whole number. On a very rare occasion the minimum intrinsic width reported
  /// by the browser is slightly bigger than the reported maximum intrinsic
  /// width. If the discrepancy overlaps 0.5 then the rounding happens in
  /// opposite directions.
  ///
  /// For example, if minIntrinsicWidth == 99.5 and maxIntrinsicWidth == 99.48,
  /// then minIntrinsicWidth is rounded up to 100, and maxIntrinsicWidth is
  /// rounded down to 99.
  // TODO(yjbanov): remove the need for this hack.
  static double _applySubPixelRoundingHack(
      double minIntrinsicWidth, double maxIntrinsicWidth) {
    if (minIntrinsicWidth <= maxIntrinsicWidth) {
      return maxIntrinsicWidth;
    }

    if (minIntrinsicWidth - maxIntrinsicWidth < 2.0) {
      return minIntrinsicWidth;
    }

    throw Exception('minIntrinsicWidth ($minIntrinsicWidth) is greater than '
        'maxIntrinsicWidth ($maxIntrinsicWidth).');
  }
}
