// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

const _experimentalEnableCanvasImplementation = false;

// TODO(yjbanov): this is a hack we use to compute ideographic baseline; this
//                number is the ratio ideographic/alphabetic for font Ahem,
//                which matches the Flutter number. It may be completely wrong
//                for any other font. We'll need to eventually fix this. That
//                said Flutter doesn't seem to use ideographic baseline for
//                anything as of this writing.
const double _baselineRatioHack = 1.1662499904632568;

/// Signature of a function that takes a character and returns true or false.
typedef CharPredicate = bool Function(String letter);

final RegExp _whitespace = RegExp(r'\s');
bool _excludeWhitespace(String letter) => _whitespace.hasMatch(letter);

final RegExp _newline = RegExp(r'\n');
bool _excludeNewlines(String letter) => _newline.hasMatch(letter);

/// Manages [ParagraphRuler] instances and caches them per unique
/// [ParagraphGeometricStyle].
///
/// All instances of [ParagraphRuler] should be created through this class.
class RulerManager {
  RulerManager({@required this.rulerCacheCapacity}) {
    _rulerHost.style
      ..position = 'fixed'
      ..visibility = 'hidden'
      ..overflow = 'hidden'
      ..top = '0'
      ..left = '0'
      ..width = '0'
      ..height = '0';
    html.document.body.append(_rulerHost);
    registerHotRestartListener(dispose);
  }

  final int rulerCacheCapacity;

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

  /// Releases the resources used by this [RulerManager].
  ///
  /// After this is called, this object is no longer usable.
  void dispose() {
    _rulerHost?.remove();
  }

  /// If ruler cache size exceeds [rulerCacheCapacity], evicts those rulers that
  /// were used the least.
  ///
  /// Resets hit counts back to zero.
  @visibleForTesting
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

  /// Performs a cache lookup to find an existing [ParagraphRuler] for the given
  /// [style] and if it can't find one in the cache, it would create one.
  ///
  /// The returned ruler is marked as hit so there's no need to do that
  /// elsewhere.
  @visibleForTesting
  ParagraphRuler findOrCreateRuler(ParagraphGeometricStyle style) {
    ParagraphRuler ruler = _rulers[style];
    if (ruler == null) {
      if (assertionsEnabled) {
        domRenderer.debugRulerCacheMiss();
      }
      ruler = _rulers[style] = ParagraphRuler(style, this);
      _scheduleRulerCacheCleanup();
    } else {
      if (assertionsEnabled) {
        domRenderer.debugRulerCacheHit();
      }
    }
    ruler.hit();
    return ruler;
  }
}

/// Provides various text measurement APIs using either a dom-based approach
/// in [DomTextMeasurementService], or a canvas-based approach in
/// [CanvasTextMeasurementService].
abstract class TextMeasurementService {
  /// Initializes the text measurement service with a specific
  /// [rulerCacheCapacity] that gets passed to the [RulerManager].
  static void initialize({@required int rulerCacheCapacity}) {
    clearCache();
    rulerManager = RulerManager(rulerCacheCapacity: rulerCacheCapacity);
  }

  @visibleForTesting
  static RulerManager rulerManager;

  /// The DOM-based text measurement service.
  @visibleForTesting
  static TextMeasurementService get domInstance =>
      DomTextMeasurementService.instance;

  /// The canvas-based text measurement service.
  @visibleForTesting
  static TextMeasurementService get canvasInstance =>
      CanvasTextMeasurementService.instance;

  /// Gets the appropriate [TextMeasurementService] instance for the given
  /// [paragraph].
  static TextMeasurementService forParagraph(ui.Paragraph paragraph) {
    // TODO(flutter_web): https://github.com/flutter/flutter/issues/33523
    // When the canvas-based implementation is complete and passes all the
    // tests, get rid of [_experimentalEnableCanvasImplementation].
    if (_experimentalEnableCanvasImplementation &&
        _canUseCanvasMeasurement(paragraph)) {
      return canvasInstance;
    }
    return domInstance;
  }

  /// Clears the cache of paragraph rulers.
  @visibleForTesting
  static void clearCache() {
    rulerManager?.dispose();
    rulerManager = null;
  }

  static bool _canUseCanvasMeasurement(ui.Paragraph paragraph) {
    // Currently, the canvas-based approach only works on plain text that
    // doesn't have any of the following styles:
    // - decoration
    // - letter spacing
    // - word spacing
    final style = paragraph.webOnlyGetParagraphGeometricStyle();
    return paragraph.webOnlyGetPlainText() != null &&
        style.decoration == null &&
        style.letterSpacing == null &&
        style.wordSpacing == null;
  }

  /// Measures the paragraph and returns a [MeasurementResult] object.
  MeasurementResult measure(
    ui.Paragraph paragraph,
    ui.ParagraphConstraints constraints,
  ) {
    final style = paragraph.webOnlyGetParagraphGeometricStyle();
    final ParagraphRuler ruler =
        TextMeasurementService.rulerManager.findOrCreateRuler(style);

    if (assertionsEnabled) {
      if (paragraph.webOnlyGetPlainText() == null) {
        domRenderer.debugRichTextLayout();
      } else {
        domRenderer.debugPlainTextLayout();
      }
    }

    MeasurementResult result = ruler.cacheLookup(paragraph, constraints);
    if (result != null) {
      return result;
    }

    result = _doMeasure(paragraph, constraints, ruler);
    ruler.cacheMeasurement(paragraph, result);
    return result;
  }

  /// Measures the width of a substring of the given [paragraph] with no
  /// constraints.
  double measureSubstringWidth(ui.Paragraph paragraph, int start, int end);

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
    final ParagraphRuler ruler =
        TextMeasurementService.rulerManager.findOrCreateRuler(style);

    return ruler.measureBoxesForRange(
      paragraph.webOnlyGetPlainText(),
      constraints,
      start: start,
      end: end,
      alignOffset: alignOffset,
      textDirection: textDirection,
    );
  }

  /// Performs the actual measurement of the following values for the given
  /// paragraph:
  ///
  /// * isSingleLine: whether the paragraph can be rendered in a single line.
  /// * height: constrained measure of the entire paragraph's height.
  /// * lineHeight: the height of a single line of the paragraph.
  /// * alphabeticBaseline: single line measure.
  /// * ideographicBaseline: based on [alphabeticBaseline].
  /// * maxIntrinsicWidth: the width of the paragraph with no line-wrapping.
  /// * minIntrinsicWidth: the min width the paragraph fits in without overflowing.
  ///
  /// [MeasurementResult.height] will be equal to [MeasurementResult.lineHeight]
  /// when [MeasurementResult.isSingleLine] is true.
  ///
  /// [MeasurementResult.width] is set to the same value of [constraints.width].
  ///
  /// It also optionally computes [MeasurementResult.lineBreaks] in the given
  /// paragraph. When that's available, it can be used by a canvas to render
  /// the text line.
  MeasurementResult _doMeasure(
    ui.Paragraph paragraph,
    ui.ParagraphConstraints constraints,
    ParagraphRuler ruler,
  );
}

/// A DOM-based text measurement implementation.
///
/// This implementation is slower than [CanvasTextMeasurementService] but it's
/// needed for some cases that aren't yet supported in the canvas-based
/// implementation such as letter-spacing, word-spacing, etc.
class DomTextMeasurementService extends TextMeasurementService {
  /// The text measurement service singleton.
  static DomTextMeasurementService get instance {
    if (_instance == null) {
      _instance = DomTextMeasurementService();
    }
    return _instance;
  }

  static DomTextMeasurementService _instance;

  @override
  MeasurementResult _doMeasure(
    ui.Paragraph paragraph,
    ui.ParagraphConstraints constraints,
    ParagraphRuler ruler,
  ) {
    ruler.willMeasure(paragraph);
    final String plainText = paragraph.webOnlyGetPlainText();

    ruler.measureAll(constraints);

    MeasurementResult result;
    // When the text has a new line, we should always use multi-line mode.
    final bool hasNewline = plainText?.contains('\n') ?? false;
    if (!hasNewline && ruler.singleLineDimensions.width <= constraints.width) {
      result = _measureSingleLineParagraph(ruler, paragraph, constraints);
    } else {
      // Assert: If text doesn't have new line for infinite constraints we
      // should have called single line measure paragraph instead.
      assert(hasNewline || constraints.width != double.infinity);
      result = _measureMultiLineParagraph(ruler, paragraph, constraints);
    }
    ruler.didMeasure();
    return result;
  }

  @override
  double measureSubstringWidth(ui.Paragraph paragraph, int start, int end) {
    final style = paragraph.webOnlyGetParagraphGeometricStyle();
    final ParagraphRuler ruler =
        TextMeasurementService.rulerManager.findOrCreateRuler(style);

    final String text = paragraph.webOnlyGetPlainText().substring(start, end);
    final ui.Paragraph substringParagraph =
        paragraph.webOnlyCloneWithText(text);

    ruler.willMeasure(substringParagraph);
    ruler.measureAsSingleLine();
    final TextDimensions dimensions = ruler.singleLineDimensions;
    ruler.didMeasure();
    return dimensions.width;
  }

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
  MeasurementResult _measureSingleLineParagraph(ParagraphRuler ruler,
      ui.Paragraph paragraph, ui.ParagraphConstraints constraints) {
    final double width = constraints.width;
    final double minIntrinsicWidth = ruler.minIntrinsicDimensions.width;
    double maxIntrinsicWidth = ruler.singleLineDimensions.width;
    final double alphabeticBaseline = ruler.alphabeticBaseline;
    final double height = ruler.singleLineDimensions.height;

    maxIntrinsicWidth =
        _applySubPixelRoundingHack(minIntrinsicWidth, maxIntrinsicWidth);
    final ideographicBaseline = alphabeticBaseline * _baselineRatioHack;
    return MeasurementResult(
      constraints.width,
      isSingleLine: true,
      width: width,
      height: height,
      lineHeight: height,
      minIntrinsicWidth: minIntrinsicWidth,
      maxIntrinsicWidth: maxIntrinsicWidth,
      alphabeticBaseline: alphabeticBaseline,
      ideographicBaseline: ideographicBaseline,
      lineBreaks: null,
    );
  }

  /// Called when we have determined that the paragraph needs to wrap into
  /// multiple lines to fit the [constraints], i.e. its `maxIntrinsicWidth` is
  /// bigger than the available horizontal space.
  ///
  /// While `maxIntrinsicWidth` is still good from the call to
  /// `measureAsSingleLine`, we need to re-measure with the width constraint
  /// and get new values for width, height and alphabetic baseline. We also need
  /// to measure `minIntrinsicWidth`.
  MeasurementResult _measureMultiLineParagraph(ParagraphRuler ruler,
      ui.Paragraph paragraph, ui.ParagraphConstraints constraints) {
    // If constraint is infinite, we must use _measureSingleLineParagraph
    final double width = constraints.width;
    final double minIntrinsicWidth = ruler.minIntrinsicDimensions.width;
    double maxIntrinsicWidth = ruler.singleLineDimensions.width;
    final double alphabeticBaseline = ruler.alphabeticBaseline;
    final double height = ruler.constrainedDimensions.height;

    double lineHeight;
    if (paragraph.webOnlyGetParagraphGeometricStyle().maxLines != null) {
      lineHeight = ruler.lineHeightDimensions.height;
    }

    maxIntrinsicWidth =
        _applySubPixelRoundingHack(minIntrinsicWidth, maxIntrinsicWidth);
    assert(minIntrinsicWidth <= maxIntrinsicWidth);
    final ideographicBaseline = alphabeticBaseline * _baselineRatioHack;
    return MeasurementResult(
      constraints.width,
      isSingleLine: false,
      width: width,
      height: height,
      lineHeight: lineHeight,
      minIntrinsicWidth: minIntrinsicWidth,
      maxIntrinsicWidth: maxIntrinsicWidth,
      alphabeticBaseline: alphabeticBaseline,
      ideographicBaseline: ideographicBaseline,
      lineBreaks: null,
    );
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

/// A canvas-based text measurement implementation.
///
/// This is a faster implementation than [DomTextMeasurementService] and
/// provides line breaks information that can be useful for multi-line text.
class CanvasTextMeasurementService extends TextMeasurementService {
  /// The text measurement service singleton.
  static CanvasTextMeasurementService get instance {
    if (_instance == null) {
      _instance = CanvasTextMeasurementService();
    }
    return _instance;
  }

  static CanvasTextMeasurementService _instance;

  final html.CanvasRenderingContext2D _canvasContext =
      html.CanvasElement().context2D;

  @override
  MeasurementResult _doMeasure(
    ui.Paragraph paragraph,
    ui.ParagraphConstraints constraints,
    ParagraphRuler ruler,
  ) {
    final String text = paragraph.webOnlyGetPlainText();
    final ParagraphGeometricStyle style =
        paragraph.webOnlyGetParagraphGeometricStyle();
    assert(text != null);

    // TODO(mdebbar): Check if the whole text can fit in a single-line. Then avoid all this ceremony.
    _canvasContext.font = style.cssFontString;

    List<int> breaks = [];
    int lineStart = 0;
    int lastMandatoryBreak = 0;
    // The greatest chunk width (without trailing whitespace).
    double widestChunk = 0;
    // Without taking any optional line breaks, what's the widest line?
    double widestContinuousLine = 0;

    // TODO(flutter_web): Chrome & Safari return more info from [canvasContext.measureText].
    int i = 0;
    while (i < text.length) {
      final LineBreakResult brk = nextLineBreak(text, i);
      final double lineWidth = _measureSubstring(text, lineStart, brk.index);

      if (lineWidth > constraints.width) {
        breaks.add(i);
        lineStart = i;
      }

      final double chunkWidth = _measureSubstring(text, i, brk.index);
      if (chunkWidth > widestChunk) {
        widestChunk = chunkWidth;
      }

      if (brk.type == LineBreakType.mandatory ||
          brk.type == LineBreakType.endOfText) {
        // The continuous line is the chunk of text since the last mandatory
        // line break.
        final continuousLineWidth = _measureSubstring(
          text,
          lastMandatoryBreak,
          brk.index,
          excludeTrailing: _excludeNewlines,
        );
        if (continuousLineWidth > widestContinuousLine) {
          widestContinuousLine = continuousLineWidth;
        }
        lastMandatoryBreak = brk.index;
        lineStart = brk.index;

        // Don't insert the last line-break at the end of the text.
        if (brk.type != LineBreakType.endOfText) {
          breaks.add(brk.index);
        }
      }
      i = brk.index;
    }

    final int lineCount = breaks.length + 1;
    final double lineHeight = ruler.lineHeightDimensions.height;
    final result = MeasurementResult(
      constraints.width,
      isSingleLine: lineCount == 1,
      alphabeticBaseline: ruler.alphabeticBaseline,
      ideographicBaseline: ruler.alphabeticBaseline * _baselineRatioHack,
      height: lineCount * lineHeight,
      lineHeight: lineHeight,
      // `minIntrinsicWidth` is the greatest width of text that can't
      // be broken down into multiple lines.
      minIntrinsicWidth: widestChunk,
      // `maxIntrinsicWidth` is the width of the widest piece of text
      // that doesn't contain mandatory line breaks.
      maxIntrinsicWidth: widestContinuousLine,
      width: constraints.width,
      // TODO(flutter_web): Consider passing the actual strings instead of just
      // indexes.
      lineBreaks: breaks,
    );
    return result;
  }

  @override
  double measureSubstringWidth(ui.Paragraph paragraph, int start, int end) {
    final text = paragraph.webOnlyGetPlainText().substring(start, end);
    final style = paragraph.webOnlyGetParagraphGeometricStyle();
    _canvasContext.font = style.cssFontString;
    return _canvasContext.measureText(text).width;
  }

  /// Measures the width of the substring of [text] starting from the index
  /// [start] (inclusive) to [end] (exclusive).
  ///
  /// As a convenience, an [excludeTrailing] function can be passed to exclude
  /// certain characters from the end of the substring. If omitted, the default
  /// is to exclude trailing whitespace.
  ///
  /// For example:
  /// ```
  /// // The substring here would be "foo     ". By default, trailing whitespace
  /// // is trimmed, so it returns the width of "foo".
  /// _measureSubstring("foo     bar", 0, 8);
  ///
  /// // The substring here is "foo   \n". Only trailing new lines are trimmed
  /// // here, so it returns the width of "foo   ".
  /// _measureSubstring(
  ///   "foo   \nbar", 0, 7,
  ///   excludeTrailing: (char) => char == '\n',
  /// );
  /// ```
  ///
  /// This method assumes that the correct font has already been set on
  /// [_canvasContext].
  double _measureSubstring(
    String text,
    int start,
    int end, {
    CharPredicate excludeTrailing = _excludeWhitespace,
  }) {
    assert(start >= 0 && start < text.length);
    assert(end >= 0 && end <= text.length);

    if (excludeTrailing != null) {
      while (start < end && excludeTrailing(text[end - 1])) {
        end--;
      }
    }
    if (start == end) {
      return 0;
    }

    final sub = text.substring(start, end);
    final double width = _canvasContext.measureText(sub).width;

    // What we are doing here is we are rounding to the nearest 2nd decimal
    // point. So 39.999423 becomes 40, and 11.243982 becomes 11.24.
    // The reason we are doing this is because we noticed that canvas API has a
    // ±0.001 error margin.
    return (width * 100).round() / 100;
  }
}
