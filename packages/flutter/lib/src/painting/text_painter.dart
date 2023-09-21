// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show max, min;
import 'dart:ui' as ui show
  BoxHeightStyle,
  BoxWidthStyle,
  LineMetrics,
  Paragraph,
  ParagraphBuilder,
  ParagraphConstraints,
  ParagraphStyle,
  PlaceholderAlignment,
  TextHeightBehavior,
  TextStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'inline_span.dart';
import 'placeholder_span.dart';
import 'strut_style.dart';
import 'text_scaler.dart';
import 'text_span.dart';

export 'package:flutter/services.dart' show TextRange, TextSelection;

// The default font size if none is specified. This should be kept in
// sync with the default values in text_style.dart, as well as the
// defaults set in the engine (eg, LibTxt's text_style.h, paragraph_style.h).
const double _kDefaultFontSize = 14.0;

/// How overflowing text should be handled.
///
/// A [TextOverflow] can be passed to [Text] and [RichText] via their
/// [Text.overflow] and [RichText.overflow] properties respectively.
enum TextOverflow {
  /// Clip the overflowing text to fix its container.
  clip,

  /// Fade the overflowing text to transparent.
  fade,

  /// Use an ellipsis to indicate that the text has overflowed.
  ellipsis,

  /// Render overflowing text outside of its container.
  visible,
}

/// Holds the [Size] and baseline required to represent the dimensions of
/// a placeholder in text.
///
/// Placeholders specify an empty space in the text layout, which is used
/// to later render arbitrary inline widgets into defined by a [WidgetSpan].
///
/// See also:
///
///  * [WidgetSpan], a subclass of [InlineSpan] and [PlaceholderSpan] that
///    represents an inline widget embedded within text. The space this
///    widget takes is indicated by a placeholder.
///  * [RichText], a text widget that supports text inline widgets.
@immutable
class PlaceholderDimensions {
  /// Constructs a [PlaceholderDimensions] with the specified parameters.
  ///
  /// The `size` and `alignment` are required as a placeholder's dimensions
  /// require at least `size` and `alignment` to be fully defined.
  const PlaceholderDimensions({
    required this.size,
    required this.alignment,
    this.baseline,
    this.baselineOffset,
  });

  /// A constant representing an empty placeholder.
  static const PlaceholderDimensions empty = PlaceholderDimensions(size: Size.zero, alignment: ui.PlaceholderAlignment.bottom);

  /// Width and height dimensions of the placeholder.
  final Size size;

  /// How to align the placeholder with the text.
  ///
  /// See also:
  ///
  ///  * [baseline], the baseline to align to when using
  ///    [dart:ui.PlaceholderAlignment.baseline],
  ///    [dart:ui.PlaceholderAlignment.aboveBaseline],
  ///    or [dart:ui.PlaceholderAlignment.belowBaseline].
  ///  * [baselineOffset], the distance of the alphabetic baseline from the upper
  ///    edge of the placeholder.
  final ui.PlaceholderAlignment alignment;

  /// Distance of the [baseline] from the upper edge of the placeholder.
  ///
  /// Only used when [alignment] is [ui.PlaceholderAlignment.baseline].
  final double? baselineOffset;

  /// The [TextBaseline] to align to. Used with:
  ///
  ///  * [ui.PlaceholderAlignment.baseline]
  ///  * [ui.PlaceholderAlignment.aboveBaseline]
  ///  * [ui.PlaceholderAlignment.belowBaseline]
  ///  * [ui.PlaceholderAlignment.middle]
  final TextBaseline? baseline;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlaceholderDimensions
        && other.size == size
        && other.alignment == alignment
        && other.baseline == baseline
        && other.baselineOffset == baselineOffset;
  }

  @override
  int get hashCode => Object.hash(size, alignment, baseline, baselineOffset);

  @override
  String toString() {
    return switch (alignment) {
      ui.PlaceholderAlignment.top ||
      ui.PlaceholderAlignment.bottom ||
      ui.PlaceholderAlignment.middle ||
      ui.PlaceholderAlignment.aboveBaseline ||
      ui.PlaceholderAlignment.belowBaseline => 'PlaceholderDimensions($size, $alignment)',
      ui.PlaceholderAlignment.baseline      => 'PlaceholderDimensions($size, $alignment($baselineOffset from top))',
    };
  }
}

/// The different ways of measuring the width of one or more lines of text.
///
/// See [Text.textWidthBasis], for example.
enum TextWidthBasis {
  /// multiline text will take up the full width given by the parent. For single
  /// line text, only the minimum amount of width needed to contain the text
  /// will be used. A common use case for this is a standard series of
  /// paragraphs.
  parent,

  /// The width will be exactly enough to contain the longest line and no
  /// longer. A common use case for this is chat bubbles.
  longestLine,
}

/// A [TextBoundary] subclass for locating word breaks.
///
/// The underlying implementation uses [UAX #29](https://unicode.org/reports/tr29/)
/// defined default word boundaries.
///
/// The default word break rules can be tailored to meet the requirements of
/// different use cases. For instance, the default rule set keeps horizontal
/// whitespaces together as a single word, which may not make sense in a
/// word-counting context -- "hello    world" counts as 3 words instead of 2.
/// An example is the [moveByWordBoundary] variant, which is a tailored
/// word-break locator that more closely matches the default behavior of most
/// platforms and editors when it comes to handling text editing keyboard
/// shortcuts that move or delete word by word.
class WordBoundary extends TextBoundary {
  /// Creates a [WordBoundary] with the text and layout information.
  WordBoundary._(this._text, this._paragraph);

  final InlineSpan _text;
  final ui.Paragraph _paragraph;

  @override
  TextRange getTextBoundaryAt(int position) => _paragraph.getWordBoundary(TextPosition(offset: max(position, 0)));

  // Combines two UTF-16 code units (high surrogate + low surrogate) into a
  // single code point that represents a supplementary character.
  static int _codePointFromSurrogates(int highSurrogate, int lowSurrogate) {
    assert(
      TextPainter.isHighSurrogate(highSurrogate),
      'U+${highSurrogate.toRadixString(16).toUpperCase().padLeft(4, "0")}) is not a high surrogate.',
    );
    assert(
      TextPainter.isLowSurrogate(lowSurrogate),
      'U+${lowSurrogate.toRadixString(16).toUpperCase().padLeft(4, "0")}) is not a low surrogate.',
    );
    const int base = 0x010000 - (0xD800 << 10) - 0xDC00;
    return (highSurrogate << 10) + lowSurrogate + base;
  }

  // The Runes class does not provide random access with a code unit offset.
  int? _codePointAt(int index) {
    final int? codeUnitAtIndex = _text.codeUnitAt(index);
    if (codeUnitAtIndex == null) {
      return null;
    }
    return switch (codeUnitAtIndex & 0xFC00) {
      0xD800 => _codePointFromSurrogates(codeUnitAtIndex, _text.codeUnitAt(index + 1)!),
      0xDC00 => _codePointFromSurrogates(_text.codeUnitAt(index - 1)!, codeUnitAtIndex),
      _      => codeUnitAtIndex,
    };
  }

  static bool _isNewline(int codePoint) {
    return switch (codePoint) {
      0x000A || 0x0085 || 0x000B || 0x000C || 0x2028 || 0x2029 => true,
      _ => false,
    };
  }

  bool _skipSpacesAndPunctuations(int offset, bool forward) {
    // Use code point since some punctuations are supplementary characters.
    // "inner" here refers to the code unit that's before the break in the
    // search direction (`forward`).
    final int? innerCodePoint = _codePointAt(forward ? offset - 1 : offset);
    final int? outerCodeUnit = _text.codeUnitAt(forward ? offset : offset - 1);

    // Make sure the hard break rules in UAX#29 take precedence over the ones we
    // add below. Luckily there're only 4 hard break rules for word breaks, and
    // dictionary based breaking does not introduce new hard breaks:
    // https://unicode-org.github.io/icu/userguide/boundaryanalysis/break-rules.html#word-dictionaries
    //
    // WB1 & WB2: always break at the start or the end of the text.
    final bool hardBreakRulesApply = innerCodePoint == null || outerCodeUnit == null
    // WB3a & WB3b: always break before and after newlines.
                                  || _isNewline(innerCodePoint) || _isNewline(outerCodeUnit);
    return hardBreakRulesApply || !RegExp(r'[\p{Space_Separator}\p{Punctuation}]', unicode: true).hasMatch(String.fromCharCode(innerCodePoint));
  }

  /// Returns a [TextBoundary] suitable for handling keyboard navigation
  /// commands that change the current selection word by word.
  ///
  /// This [TextBoundary] is used by text widgets in the flutter framework to
  /// provide default implementation for text editing shortcuts, for example,
  /// "delete to the previous word".
  ///
  /// The implementation applies the same set of rules [WordBoundary] uses,
  /// except that word breaks end on a space separator or a punctuation will be
  /// skipped, to match the behavior of most platforms. Additional rules may be
  /// added in the future to better match platform behaviors.
  late final TextBoundary moveByWordBoundary = _UntilTextBoundary(this, _skipSpacesAndPunctuations);
}

class _UntilTextBoundary extends TextBoundary {
  const _UntilTextBoundary(this._textBoundary, this._predicate);

  final UntilPredicate _predicate;
  final TextBoundary _textBoundary;

  @override
  int? getLeadingTextBoundaryAt(int position) {
    if (position < 0) {
      return null;
    }
    final int? offset = _textBoundary.getLeadingTextBoundaryAt(position);
    return offset == null || _predicate(offset, false)
      ? offset
      : getLeadingTextBoundaryAt(offset - 1);
  }

  @override
  int? getTrailingTextBoundaryAt(int position) {
    final int? offset = _textBoundary.getTrailingTextBoundaryAt(max(position, 0));
    return offset == null || _predicate(offset, true)
      ? offset
      : getTrailingTextBoundaryAt(offset);
  }
}

class _TextLayout {
  _TextLayout._(this._paragraph);

  // This field is not final because the owner TextPainter could create a new
  // ui.Paragraph with the exact same text layout (for example, when only the
  // color of the text is changed).
  //
  // The creator of this _TextLayout is also responsible for disposing this
  // object when it's no logner needed.
  ui.Paragraph _paragraph;

  /// Whether this layout has been invalidated and disposed.
  ///
  /// Only for use when asserts are enabled.
  bool get debugDisposed => _paragraph.debugDisposed;

  /// The horizontal space required to paint this text.
  ///
  /// If a line ends with trailing spaces, the trailing spaces may extend
  /// outside of the horizontal paint bounds defined by [width].
  double get width => _paragraph.width;

  /// The vertical space required to paint this text.
  double get height => _paragraph.height;

  /// The width at which decreasing the width of the text would prevent it from
  /// painting itself completely within its bounds.
  double get minIntrinsicLineExtent => _paragraph.minIntrinsicWidth;

  /// The width at which increasing the width of the text no longer decreases the height.
  ///
  /// Includes trailing spaces if any.
  double get maxIntrinsicLineExtent => _paragraph.maxIntrinsicWidth;

  /// The distance from the left edge of the leftmost glyph to the right edge of
  /// the rightmost glyph in the paragraph.
  double get longestLine => _paragraph.longestLine;

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  double getDistanceToBaseline(TextBaseline baseline) {
    return switch (baseline) {
      TextBaseline.alphabetic => _paragraph.alphabeticBaseline,
      TextBaseline.ideographic => _paragraph.ideographicBaseline,
    };
  }
}

// This class stores the current text layout and the corresponding
// paintOffset/contentWidth, as well as some cached text metrics values that
// depends on the current text layout, which will be invalidated as soon as the
// text layout is invalidated.
class _TextPainterLayoutCacheWithOffset {
  _TextPainterLayoutCacheWithOffset(this.layout, this.textAlignment, double minWidth, double maxWidth, TextWidthBasis widthBasis)
    : contentWidth = _contentWidthFor(minWidth, maxWidth, widthBasis, layout),
      assert(textAlignment >= 0.0 && textAlignment <= 1.0);

  final _TextLayout layout;

  // The content width the text painter should report in TextPainter.width.
  // This is also used to compute `paintOffset`
  double contentWidth;

  // The effective text alignment in the TextPainter's canvas. The value is
  // within the [0, 1] interval: 0 for left aligned and 1 for right aligned.
  final double textAlignment;

  // The paintOffset of the `paragraph` in the TextPainter's canvas.
  //
  // It's coordinate values are guaranteed to not be NaN.
  Offset get paintOffset {
    if (textAlignment == 0) {
      return Offset.zero;
    }
    if (!paragraph.width.isFinite) {
      return const Offset(double.infinity, 0.0);
    }
    final double dx = textAlignment * (contentWidth - paragraph.width);
    assert(!dx.isNaN);
    return Offset(dx, 0);
  }

  ui.Paragraph get paragraph => layout._paragraph;

  static double _contentWidthFor(double minWidth, double maxWidth, TextWidthBasis widthBasis, _TextLayout layout) {
    return switch (widthBasis) {
      TextWidthBasis.longestLine => clampDouble(layout.longestLine, minWidth, maxWidth),
      TextWidthBasis.parent => clampDouble(layout.maxIntrinsicLineExtent, minWidth, maxWidth),
    };
  }

  // Try to resize the contentWidth to fit the new input constraints, by just
  // adjusting the paint offset (so no line-breaking changes needed).
  //
  // Returns false if the new constraints require re-computing the line breaks,
  // in which case no side effects will occur.
  bool _resizeToFit(double minWidth, double maxWidth, TextWidthBasis widthBasis) {
    assert(layout.maxIntrinsicLineExtent.isFinite);
    // The assumption here is that if a Paragraph's width is already >= its
    // maxIntrinsicWidth, further increasing the input width does not change its
    // layout (but may change the paint offset if it's not left-aligned). This is
    // true even for TextAlign.justify: when width >= maxIntrinsicWidth
    // TextAlign.justify will behave exactly the same as TextAlign.start.
    //
    // An exception to this is when the text is not left-aligned, and the input
    // width is double.infinity. Since the resulting Paragraph will have a width
    // of double.infinity, and to make the text visible the paintOffset.dx is
    // bound to be double.negativeInfinity, which invalidates all arithmetic
    // operations.
    final double newContentWidth = _contentWidthFor(minWidth, maxWidth, widthBasis, layout);
    if (newContentWidth == contentWidth) {
      return true;
    }
    assert(minWidth <= maxWidth);
    // Always needsLayout when the current paintOffset and the paragraph width are not finite.
    if (!paintOffset.dx.isFinite && !paragraph.width.isFinite && minWidth.isFinite) {
      assert(paintOffset.dx == double.infinity);
      assert(paragraph.width == double.infinity);
      return false;
    }
    final double maxIntrinsicWidth = paragraph.maxIntrinsicWidth;
    if ((paragraph.width - maxIntrinsicWidth) > -precisionErrorTolerance && (maxWidth - maxIntrinsicWidth) > -precisionErrorTolerance) {
      // Adjust the paintOffset and contentWidth to the new input constraints.
      contentWidth = newContentWidth;
      return true;
    }
    return false;
  }

  // ---- Cached Values ----

  List<TextBox> get inlinePlaceholderBoxes => _cachedInlinePlaceholderBoxes ??= paragraph.getBoxesForPlaceholders();
  List<TextBox>? _cachedInlinePlaceholderBoxes;

  List<ui.LineMetrics> get lineMetrics => _cachedLineMetrics ??= paragraph.computeLineMetrics();
  List<ui.LineMetrics>? _cachedLineMetrics;

  // Holds the TextPosition the last caret metrics were computed with. When new
  // values are passed in, we recompute the caret metrics only as necessary.
  TextPosition? _previousCaretPosition;
}

/// This is used to cache and pass the computed metrics regarding the
/// caret's size and position. This is preferred due to the expensive
/// nature of the calculation.
///
// A _CaretMetrics is either a _LineCaretMetrics or an _EmptyLineCaretMetrics.
@immutable
sealed class _CaretMetrics { }

/// The _CaretMetrics for carets located in a non-empty line. Carets located in a
/// non-empty line are associated with a glyph within the same line.
final class _LineCaretMetrics implements _CaretMetrics {
  const _LineCaretMetrics({required this.offset, required this.writingDirection, required this.fullHeight});
  /// The offset of the top left corner of the caret from the top left
  /// corner of the paragraph.
  final Offset offset;
  /// The writing direction of the glyph the _CaretMetrics is associated with.
  final TextDirection writingDirection;
  /// The full height of the glyph at the caret position.
  final double fullHeight;
}

/// The _CaretMetrics for carets located in an empty line (when the text is
/// empty, or the caret is between two a newline characters).
final class _EmptyLineCaretMetrics implements _CaretMetrics {
  const _EmptyLineCaretMetrics({ required this.lineVerticalOffset });

  /// The y offset of the unoccupied line.
  final double lineVerticalOffset;
}

/// An object that paints a [TextSpan] tree into a [Canvas].
///
/// To use a [TextPainter], follow these steps:
///
/// 1. Create a [TextSpan] tree and pass it to the [TextPainter]
///    constructor.
///
/// 2. Call [layout] to prepare the paragraph.
///
/// 3. Call [paint] as often as desired to paint the paragraph.
///
/// 4. Call [dispose] when the object will no longer be accessed to release
///    native resources. For [TextPainter] objects that are used repeatedly and
///    stored on a [State] or [RenderObject], call [dispose] from
///    [State.dispose] or [RenderObject.dispose] or similar. For [TextPainter]
///    objects that are only used ephemerally, it is safe to immediately dispose
///    them after the last call to methods or properties on the object.
///
/// If the width of the area into which the text is being painted
/// changes, return to step 2. If the text to be painted changes,
/// return to step 1.
///
/// The default text style is white. To change the color of the text,
/// pass a [TextStyle] object to the [TextSpan] in `text`.
class TextPainter {
  /// Creates a text painter that paints the given text.
  ///
  /// The `text` and `textDirection` arguments are optional but [text] and
  /// [textDirection] must be non-null before calling [layout].
  ///
  /// The [maxLines] property, if non-null, must be greater than zero.
  TextPainter({
    InlineSpan? text,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
  }) : assert(text == null || text.debugAssertIsValid()),
       assert(maxLines == null || maxLines > 0),
       assert(textScaleFactor == 1.0 || identical(textScaler, TextScaler.noScaling), 'Use textScaler instead.'),
       _text = text,
       _textAlign = textAlign,
       _textDirection = textDirection,
       _textScaler = textScaler == TextScaler.noScaling ? TextScaler.linear(textScaleFactor) : textScaler,
       _maxLines = maxLines,
       _ellipsis = ellipsis,
       _locale = locale,
       _strutStyle = strutStyle,
       _textWidthBasis = textWidthBasis,
       _textHeightBehavior = textHeightBehavior;

  /// Computes the width of a configured [TextPainter].
  ///
  /// This is a convenience method that creates a text painter with the supplied
  /// parameters, lays it out with the supplied [minWidth] and [maxWidth], and
  /// returns its [TextPainter.width] making sure to dispose the underlying
  /// resources. Doing this operation is expensive and should be avoided
  /// whenever it is possible to preserve the [TextPainter] to paint the
  /// text or get other information about it.
  static double computeWidth({
    required InlineSpan text,
    required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    double minWidth = 0.0,
    double maxWidth = double.infinity,
  }) {
    assert(
      textScaleFactor == 1.0 || identical(textScaler, TextScaler.noScaling),
      'Use textScaler instead.',
    );
    final TextPainter painter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler == TextScaler.noScaling ? TextScaler.linear(textScaleFactor) : textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);

    try {
      return painter.width;
    } finally {
      painter.dispose();
    }
  }

  /// Computes the max intrinsic width of a configured [TextPainter].
  ///
  /// This is a convenience method that creates a text painter with the supplied
  /// parameters, lays it out with the supplied [minWidth] and [maxWidth], and
  /// returns its [TextPainter.maxIntrinsicWidth] making sure to dispose the
  /// underlying resources. Doing this operation is expensive and should be avoided
  /// whenever it is possible to preserve the [TextPainter] to paint the
  /// text or get other information about it.
  static double computeMaxIntrinsicWidth({
    required InlineSpan text,
    required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    double minWidth = 0.0,
    double maxWidth = double.infinity,
  }) {
    assert(
      textScaleFactor == 1.0 || identical(textScaler, TextScaler.noScaling),
      'Use textScaler instead.',
    );
    final TextPainter painter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler == TextScaler.noScaling ? TextScaler.linear(textScaleFactor) : textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);

    try {
      return painter.maxIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }

  // Whether textWidthBasis has changed after the most recent `layout` call.
  bool _debugNeedsRelayout = true;
  // The result of the most recent `layout` call.
  _TextPainterLayoutCacheWithOffset? _layoutCache;

  // Whether _layoutCache contains outdated paint information and needs to be
  // updated before painting.
  //
  // ui.Paragraph is entirely immutable, thus text style changes that can affect
  // layout and those who can't both require the ui.Paragraph object being
  // recreated. The caller may not call `layout` again after text color is
  // updated. See: https://github.com/flutter/flutter/issues/85108
  bool _rebuildParagraphForPaint = true;
  // `_layoutCache`'s input width. This is only needed because there's no API to
  // create paint only updates that don't affect the text layout (e.g., changing
  // the color of the text), on ui.Paragraph or ui.ParagraphBuilder.
  double _inputWidth = double.nan;

  bool get _debugAssertTextLayoutIsValid {
    assert(!debugDisposed);
    if (_layoutCache == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Text layout not available'),
        if (_debugMarkNeedsLayoutCallStack != null) DiagnosticsStackTrace('The calls that first invalidated the text layout were', _debugMarkNeedsLayoutCallStack)
        else ErrorDescription('The TextPainter has never been laid out.')
      ]);
    }
    return true;
  }

  StackTrace? _debugMarkNeedsLayoutCallStack;

  /// Marks this text painter's layout information as dirty and removes cached
  /// information.
  ///
  /// Uses this method to notify text painter to relayout in the case of
  /// layout changes in engine. In most cases, updating text painter properties
  /// in framework will automatically invoke this method.
  void markNeedsLayout() {
    assert(() {
      if (_layoutCache != null) {
        _debugMarkNeedsLayoutCallStack ??= StackTrace.current;
      }
      return true;
    }());
    _layoutCache?.paragraph.dispose();
    _layoutCache = null;
  }

  /// The (potentially styled) text to paint.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  /// This and [textDirection] must be non-null before you call [layout].
  ///
  /// The [InlineSpan] this provides is in the form of a tree that may contain
  /// multiple instances of [TextSpan]s and [WidgetSpan]s. To obtain a plain text
  /// representation of the contents of this [TextPainter], use [plainText].
  InlineSpan? get text => _text;
  InlineSpan? _text;
  set text(InlineSpan? value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value) {
      return;
    }
    if (_text?.style != value?.style) {
      _layoutTemplate?.dispose();
      _layoutTemplate = null;
    }

    final RenderComparison comparison = value == null
      ? RenderComparison.layout
      : _text?.compareTo(value) ?? RenderComparison.layout;

    _text = value;
    _cachedPlainText = null;

    if (comparison.index >= RenderComparison.layout.index) {
      markNeedsLayout();
    } else if (comparison.index >= RenderComparison.paint.index) {
      // Don't invalid the _layoutCache just yet. It still contains valid layout
      // information.
      _rebuildParagraphForPaint = true;
    }
    // Neither relayout or repaint is needed.
  }

  /// Returns a plain text version of the text to paint.
  ///
  /// This uses [InlineSpan.toPlainText] to get the full contents of all nodes in the tree.
  String get plainText {
    _cachedPlainText ??= _text?.toPlainText(includeSemanticsLabels: false);
    return _cachedPlainText ?? '';
  }
  String? _cachedPlainText;

  /// How the text should be aligned horizontally.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The [textAlign] property defaults to [TextAlign.start].
  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) {
      return;
    }
    _textAlign = value;
    markNeedsLayout();
  }

  /// The default directionality of the text.
  ///
  /// This controls how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are resolved.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// This and [text] must be non-null before you call [layout].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
    _layoutTemplate?.dispose();
    _layoutTemplate = null; // Shouldn't really matter, but for strict correctness...
  }

  /// Deprecated. Will be removed in a future version of Flutter. Use
  /// [textScaler] instead.
  ///
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  double get textScaleFactor => textScaler.textScaleFactor;
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  set textScaleFactor(double value) {
    textScaler = TextScaler.linear(value);
  }

  /// {@template flutter.painting.textPainter.textScaler}
  /// The font scaling strategy to use when laying out and rendering the text.
  ///
  /// The value usually comes from [MediaQuery.textScalerOf], which typically
  /// reflects the user-specified text scaling value in the platform's
  /// accessibility settings. The [TextStyle.fontSize] of the text will be
  /// adjusted by the [TextScaler] before the text is laid out and rendered.
  /// {@endtemplate}
  ///
  /// The [layout] method must be called after [textScaler] changes as it
  /// affects the text layout.
  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) {
      return;
    }
    _textScaler = value;
    markNeedsLayout();
    _layoutTemplate?.dispose();
    _layoutTemplate = null;
  }

  /// The string used to ellipsize overflowing text. Setting this to a non-empty
  /// string will cause this string to be substituted for the remaining text
  /// if the text can not fit within the specified maximum width.
  ///
  /// Specifically, the ellipsis is applied to the last line before the line
  /// truncated by [maxLines], if [maxLines] is non-null and that line overflows
  /// the width constraint, or to the first line that is wider than the width
  /// constraint, if [maxLines] is null. The width constraint is the `maxWidth`
  /// passed to [layout].
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The higher layers of the system, such as the [Text] widget, represent
  /// overflow effects using the [TextOverflow] enum. The
  /// [TextOverflow.ellipsis] value corresponds to setting this property to
  /// U+2026 HORIZONTAL ELLIPSIS (…).
  String? get ellipsis => _ellipsis;
  String? _ellipsis;
  set ellipsis(String? value) {
    assert(value == null || value.isNotEmpty);
    if (_ellipsis == value) {
      return;
    }
    _ellipsis = value;
    markNeedsLayout();
  }

  /// The locale used to select region-specific glyphs.
  Locale? get locale => _locale;
  Locale? _locale;
  set locale(Locale? value) {
    if (_locale == value) {
      return;
    }
    _locale = value;
    markNeedsLayout();
  }

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary.
  ///
  /// If the text exceeds the given number of lines, it is truncated such that
  /// subsequent lines are dropped.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  int? get maxLines => _maxLines;
  int? _maxLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (_maxLines == value) {
      return;
    }
    _maxLines = value;
    markNeedsLayout();
  }

  /// {@template flutter.painting.textPainter.strutStyle}
  /// The strut style to use. Strut style defines the strut, which sets minimum
  /// vertical layout metrics.
  ///
  /// Omitting or providing null will disable strut.
  ///
  /// Omitting or providing null for any properties of [StrutStyle] will result in
  /// default values being used. It is highly recommended to at least specify a
  /// [StrutStyle.fontSize].
  ///
  /// See [StrutStyle] for details.
  /// {@endtemplate}
  StrutStyle? get strutStyle => _strutStyle;
  StrutStyle? _strutStyle;
  set strutStyle(StrutStyle? value) {
    if (_strutStyle == value) {
      return;
    }
    _strutStyle = value;
    markNeedsLayout();
  }

  /// {@template flutter.painting.textPainter.textWidthBasis}
  /// Defines how to measure the width of the rendered text.
  /// {@endtemplate}
  TextWidthBasis get textWidthBasis => _textWidthBasis;
  TextWidthBasis _textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    if (_textWidthBasis == value) {
      return;
    }
    assert(() { return _debugNeedsRelayout = true; }());
    _textWidthBasis = value;
  }

  /// {@macro dart.ui.textHeightBehavior}
  ui.TextHeightBehavior? get textHeightBehavior => _textHeightBehavior;
  ui.TextHeightBehavior? _textHeightBehavior;
  set textHeightBehavior(ui.TextHeightBehavior? value) {
    if (_textHeightBehavior == value) {
      return;
    }
    _textHeightBehavior = value;
    markNeedsLayout();
  }

  /// An ordered list of [TextBox]es that bound the positions of the placeholders
  /// in the paragraph.
  ///
  /// Each box corresponds to a [PlaceholderSpan] in the order they were defined
  /// in the [InlineSpan] tree.
  List<TextBox>? get inlinePlaceholderBoxes {
    final _TextPainterLayoutCacheWithOffset? layout = _layoutCache;
    if (layout == null) {
      return null;
    }
    final Offset offset = layout.paintOffset;
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return <TextBox>[];
    }
    final List<TextBox> rawBoxes = layout.inlinePlaceholderBoxes;
    if (offset == Offset.zero) {
      return rawBoxes;
    }
    return rawBoxes.map((TextBox box) => _shiftTextBox(box, offset)).toList(growable: false);
  }

  /// Sets the dimensions of each placeholder in [text].
  ///
  /// The number of [PlaceholderDimensions] provided should be the same as the
  /// number of [PlaceholderSpan]s in text. Passing in an empty or null `value`
  /// will do nothing.
  ///
  /// If [layout] is attempted without setting the placeholder dimensions, the
  /// placeholders will be ignored in the text layout and no valid
  /// [inlinePlaceholderBoxes] will be returned.
  void setPlaceholderDimensions(List<PlaceholderDimensions>? value) {
    if (value == null || value.isEmpty || listEquals(value, _placeholderDimensions)) {
      return;
    }
    assert(() {
      int placeholderCount = 0;
      text!.visitChildren((InlineSpan span) {
        if (span is PlaceholderSpan) {
          placeholderCount += 1;
        }
        return value.length >= placeholderCount;
      });
      return placeholderCount == value.length;
    }());
    _placeholderDimensions = value;
    markNeedsLayout();
  }
  List<PlaceholderDimensions>? _placeholderDimensions;

  ui.ParagraphStyle _createParagraphStyle([ TextDirection? defaultTextDirection ]) {
    // The defaultTextDirection argument is used for preferredLineHeight in case
    // textDirection hasn't yet been set.
    assert(textDirection != null || defaultTextDirection != null, 'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    return _text!.style?.getParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection ?? defaultTextDirection,
      textScaler: textScaler,
      maxLines: _maxLines,
      textHeightBehavior: _textHeightBehavior,
      ellipsis: _ellipsis,
      locale: _locale,
      strutStyle: _strutStyle,
    ) ?? ui.ParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection ?? defaultTextDirection,
      // Use the default font size to multiply by as RichText does not
      // perform inheriting [TextStyle]s and would otherwise
      // fail to apply textScaler.
      fontSize: textScaler.scale(_kDefaultFontSize),
      maxLines: maxLines,
      textHeightBehavior: _textHeightBehavior,
      ellipsis: ellipsis,
      locale: locale,
    );
  }

  ui.Paragraph? _layoutTemplate;
  ui.Paragraph _createLayoutTemplate() {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      _createParagraphStyle(TextDirection.rtl),
    ); // direction doesn't matter, text is just a space
    final ui.TextStyle? textStyle = text?.style?.getTextStyle(textScaler: textScaler);
    if (textStyle != null) {
      builder.pushStyle(textStyle);
    }
    builder.addText(' ');
    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }

  /// The height of a space in [text] in logical pixels.
  ///
  /// Not every line of text in [text] will have this height, but this height
  /// is "typical" for text in [text] and useful for sizing other objects
  /// relative a typical line of text.
  ///
  /// Obtaining this value does not require calling [layout].
  ///
  /// The style of the [text] property is used to determine the font settings
  /// that contribute to the [preferredLineHeight]. If [text] is null or if it
  /// specifies no styles, the default [TextStyle] values are used (a 10 pixel
  /// sans-serif font).
  double get preferredLineHeight => (_layoutTemplate ??= _createLayoutTemplate()).height;

  /// The width at which decreasing the width of the text would prevent it from
  /// painting itself completely within its bounds.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicWidth {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.minIntrinsicLineExtent;
  }

  /// The width at which increasing the width of the text no longer decreases the height.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicWidth {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.maxIntrinsicLineExtent;
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    return _layoutCache!.contentWidth;
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.height;
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    return Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.layout.getDistanceToBaseline(baseline);
  }

  /// Whether any text was truncated or ellipsized.
  ///
  /// If [maxLines] is not null, this is true if there were more lines to be
  /// drawn than the given [maxLines], and thus at least one line was omitted in
  /// the output; otherwise it is false.
  ///
  /// If [maxLines] is null, this is true if [ellipsis] is not the empty string
  /// and there was a line that overflowed the `maxWidth` argument passed to
  /// [layout]; otherwise it is false.
  ///
  /// Valid only after [layout] has been called.
  bool get didExceedMaxLines {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.paragraph.didExceedMaxLines;
  }

  // Creates a ui.Paragraph using the current configurations in this class and
  // assign it to _paragraph.
  ui.Paragraph _createParagraph(InlineSpan text) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(_createParagraphStyle());
    text.build(builder, textScaler: textScaler, dimensions: _placeholderDimensions);
    assert(() {
      _debugMarkNeedsLayoutCallStack = null;
      return true;
    }());
    _rebuildParagraphForPaint = false;
    return builder.build();
  }

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a width that's as close to its max intrinsic
  /// width (or its longest line, if [textWidthBasis] is set to
  /// [TextWidthBasis.parent]) as possible while still being greater than or
  /// equal to `minWidth` and less than or equal to `maxWidth`.
  ///
  /// The [text] and [textDirection] properties must be non-null before this is
  /// called.
  void layout({ double minWidth = 0.0, double maxWidth = double.infinity }) {
    assert(!maxWidth.isNaN);
    assert(!minWidth.isNaN);
    assert(() {
      _debugNeedsRelayout = false;
      return true;
    }());

    final _TextPainterLayoutCacheWithOffset? cachedLayout = _layoutCache;
    if (cachedLayout != null && cachedLayout._resizeToFit(minWidth, maxWidth, textWidthBasis)) {
      return;
    }

    final InlineSpan? text = this.text;
    if (text == null) {
      throw StateError('TextPainter.text must be set to a non-null value before using the TextPainter.');
    }
    final TextDirection? textDirection = this.textDirection;
    if (textDirection == null) {
      throw StateError('TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    }

    final double paintOffsetAlignment = _computePaintOffsetFraction(textAlign, textDirection);
    // Try to avoid laying out the paragraph with maxWidth=double.infinity
    // when the text is not left-aligned, so we don't have to deal with an
    // infinite paint offset.
    final bool adjustMaxWidth = !maxWidth.isFinite && paintOffsetAlignment != 0;
    final double? adjustedMaxWidth = !adjustMaxWidth ? maxWidth : cachedLayout?.layout.maxIntrinsicLineExtent;
    _inputWidth = adjustedMaxWidth ?? maxWidth;

    // Only rebuild the paragraph when there're layout changes, even when
    // `_rebuildParagraphForPaint` is true. It's best to not eagerly rebuild
    // the paragraph to avoid the extra work, because:
    // 1. the text color could change again before `paint` is called (so one of
    //    the paragraph rebuilds is unnecessary)
    // 2. the user could be measuring the text layout so `paint` will never be
    //    called.
    final ui.Paragraph paragraph = (cachedLayout?.paragraph ?? _createParagraph(text))
      ..layout(ui.ParagraphConstraints(width: _inputWidth));
    final _TextPainterLayoutCacheWithOffset newLayoutCache = _TextPainterLayoutCacheWithOffset(
      _TextLayout._(paragraph), paintOffsetAlignment, minWidth, maxWidth, textWidthBasis,
    );
    // Call layout again if newLayoutCache had an infinite paint offset.
    // This is not as expensive as it seems, line breaking is relatively cheap
    // as compared to shaping.
    if (adjustedMaxWidth == null && minWidth.isFinite) {
      assert(maxWidth.isInfinite);
      final double newInputWidth = newLayoutCache.layout.maxIntrinsicLineExtent;
      paragraph.layout(ui.ParagraphConstraints(width: newInputWidth));
      _inputWidth = newInputWidth;
    }
    _layoutCache = newLayoutCache;
  }

  /// Paints the text onto the given canvas at the given offset.
  ///
  /// Valid only after [layout] has been called.
  ///
  /// If you cannot see the text being painted, check that your text color does
  /// not conflict with the background on which you are drawing. The default
  /// text color is white (to contrast with the default black background color),
  /// so if you are writing an application with a white background, the text
  /// will not be visible by default.
  ///
  /// To set the text style, specify a [TextStyle] when creating the [TextSpan]
  /// that you pass to the [TextPainter] constructor or to the [text] property.
  void paint(Canvas canvas, Offset offset) {
    final _TextPainterLayoutCacheWithOffset? layoutCache = _layoutCache;
    if (layoutCache == null) {
      throw StateError(
        'TextPainter.paint called when text geometry was not yet calculated.\n'
        'Please call layout() before paint() to position the text before painting it.',
      );
    }

    if (!layoutCache.paintOffset.dx.isFinite || !layoutCache.paintOffset.dy.isFinite) {
      return;
    }

    if (_rebuildParagraphForPaint) {
      Size? debugSize;
      assert(() {
        debugSize = size;
        return true;
      }());

      final ui.Paragraph paragraph = layoutCache.paragraph;
      // Unfortunately even if we know that there is only paint changes, there's
      // no API to only make those updates so the paragraph has to be recreated
      // and re-laid out.
      assert(!_inputWidth.isNaN);
      layoutCache.layout._paragraph = _createParagraph(text!)..layout(ui.ParagraphConstraints(width: _inputWidth));
      assert(paragraph.width == layoutCache.layout._paragraph.width);
      paragraph.dispose();
      assert(debugSize == size);
    }
    assert(!_rebuildParagraphForPaint);
    canvas.drawParagraph(layoutCache.paragraph, offset + layoutCache.paintOffset);
  }

  // Returns true if value falls in the valid range of the UTF16 encoding.
  static bool _isUTF16(int value) {
    return value >= 0x0 && value <= 0xFFFFF;
  }

  /// Returns true iff the given value is a valid UTF-16 high (first) surrogate.
  /// The value must be a UTF-16 code unit, meaning it must be in the range
  /// 0x0000-0xFFFF.
  ///
  /// See also:
  ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  ///   * [isLowSurrogate], which checks the same thing for low (second)
  /// surrogates.
  static bool isHighSurrogate(int value) {
    assert(_isUTF16(value));
    return value & 0xFC00 == 0xD800;
  }

  /// Returns true iff the given value is a valid UTF-16 low (second) surrogate.
  /// The value must be a UTF-16 code unit, meaning it must be in the range
  /// 0x0000-0xFFFF.
  ///
  /// See also:
  ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  ///   * [isHighSurrogate], which checks the same thing for high (first)
  /// surrogates.
  static bool isLowSurrogate(int value) {
    assert(_isUTF16(value));
    return value & 0xFC00 == 0xDC00;
  }

  // Checks if the glyph is either [Unicode.RLM] or [Unicode.LRM]. These values take
  // up zero space and do not have valid bounding boxes around them.
  //
  // We do not directly use the [Unicode] constants since they are strings.
  static bool _isUnicodeDirectionality(int value) {
    return value == 0x200F || value == 0x200E;
  }

  /// Returns the closest offset after `offset` at which the input cursor can be
  /// positioned.
  int? getOffsetAfter(int offset) {
    final int? nextCodeUnit = _text!.codeUnitAt(offset);
    if (nextCodeUnit == null) {
      return null;
    }
    // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
    return isHighSurrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  /// Returns the closest offset before `offset` at which the input cursor can
  /// be positioned.
  int? getOffsetBefore(int offset) {
    final int? prevCodeUnit = _text!.codeUnitAt(offset - 1);
    if (prevCodeUnit == null) {
      return null;
    }
    // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
    return isLowSurrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  // Unicode value for a zero width joiner character.
  static const int _zwjUtf16 = 0x200d;

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character upstream from the given string offset.
  _CaretMetrics? _getMetricsFromUpstream(int offset) {
    assert(offset >= 0);
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0 || offset > plainTextLength) {
      return null;
    }
    final int prevCodeUnit = plainText.codeUnitAt(max(0, offset - 1));

    // If the upstream character is a newline, cursor is at start of next line
    const int NEWLINE_CODE_UNIT = 10;

    // Check for multi-code-unit glyphs such as emojis or zero width joiner.
    final bool needsSearch = isHighSurrogate(prevCodeUnit) || isLowSurrogate(prevCodeUnit) || _text!.codeUnitAt(offset) == _zwjUtf16 || _isUnicodeDirectionality(prevCodeUnit);
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty) {
      final int prevRuneOffset = offset - graphemeClusterLength;
      // Use BoxHeightStyle.strut to ensure that the caret's height fits within
      // the line's height and is consistent throughout the line.
      boxes = _layoutCache!.paragraph.getBoxesForRange(max(0, prevRuneOffset), offset, boxHeightStyle: ui.BoxHeightStyle.strut);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the beginning of the line, a non-surrogate position will
        // return empty boxes. We break and try from downstream instead.
        if (!needsSearch && prevCodeUnit == NEWLINE_CODE_UNIT) {
          break; // Only perform one iteration if no search is required.
        }
        if (prevRuneOffset < -plainTextLength) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }

      // Try to identify the box nearest the offset.  This logic works when
      // there's just one box, and when all boxes have the same direction.
      // It may not work in bidi text: https://github.com/flutter/flutter/issues/123424
      final TextBox box = boxes.last.direction == TextDirection.ltr
          ? boxes.last : boxes.first;
      return prevCodeUnit == NEWLINE_CODE_UNIT
        ? _EmptyLineCaretMetrics(lineVerticalOffset: box.bottom)
        : _LineCaretMetrics(offset: Offset(box.end, box.top), writingDirection: box.direction, fullHeight: box.bottom - box.top);
    }
    return null;
  }

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character downstream from the given string offset.
  _CaretMetrics? _getMetricsFromDownstream(int offset) {
    assert(offset >= 0);
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0) {
      return null;
    }
    // We cap the offset at the final index of plain text.
    final int nextCodeUnit = plainText.codeUnitAt(min(offset, plainTextLength - 1));

    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final bool needsSearch = isHighSurrogate(nextCodeUnit) || isLowSurrogate(nextCodeUnit) || nextCodeUnit == _zwjUtf16 || _isUnicodeDirectionality(nextCodeUnit);
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty) {
      final int nextRuneOffset = offset + graphemeClusterLength;
      // Use BoxHeightStyle.strut to ensure that the caret's height fits within
      // the line's height and is consistent throughout the line.
      boxes = _layoutCache!.paragraph.getBoxesForRange(offset, nextRuneOffset, boxHeightStyle: ui.BoxHeightStyle.strut);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the end of the line, a non-surrogate position will
        // return empty boxes. We break and try from upstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (nextRuneOffset >= plainTextLength << 1) {
          break; // Stop iterating when beyond the max length of the text.
        }
        // Multiply by two to log(n) time cover the entire text span. This allows
        // faster discovery of very long clusters and reduces the possibility
        // of certain large clusters taking much longer than others, which can
        // cause jank.
        graphemeClusterLength *= 2;
        continue;
      }

      // Try to identify the box nearest the offset.  This logic works when
      // there's just one box, and when all boxes have the same direction.
      // It may not work in bidi text: https://github.com/flutter/flutter/issues/123424
      final TextBox box = boxes.first.direction == TextDirection.ltr
        ? boxes.first : boxes.last;
      return _LineCaretMetrics(offset: Offset(box.start, box.top), writingDirection: box.direction, fullHeight: box.bottom - box.top);
    }
    return null;
  }

  static double _computePaintOffsetFraction(TextAlign textAlign, TextDirection textDirection) {
    return switch ((textAlign, textDirection)) {
      (TextAlign.left, _) => 0.0,
      (TextAlign.right, _) => 1.0,
      (TextAlign.center, _) => 0.5,
      (TextAlign.start, TextDirection.ltr) => 0.0,
      (TextAlign.start, TextDirection.rtl) => 1.0,
      (TextAlign.justify, TextDirection.ltr) => 0.0,
      (TextAlign.justify, TextDirection.rtl) => 1.0,
      (TextAlign.end, TextDirection.ltr) => 1.0,
      (TextAlign.end, TextDirection.rtl) => 0.0,
    };
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final _CaretMetrics caretMetrics;
    final _TextPainterLayoutCacheWithOffset layoutCache = _layoutCache!;
    if (position.offset < 0) {
      // TODO(LongCatIsLooong): make this case impossible; see https://github.com/flutter/flutter/issues/79495
      caretMetrics = const _EmptyLineCaretMetrics(lineVerticalOffset: 0);
    } else {
      caretMetrics = _computeCaretMetrics(position);
    }

    final Offset rawOffset;
    switch (caretMetrics) {
      case _EmptyLineCaretMetrics(:final double lineVerticalOffset):
        final double paintOffsetAlignment = _computePaintOffsetFraction(textAlign, textDirection!);
        // The full width is not (width - caretPrototype.width)
        // because RenderEditable reserves cursor width on the right. Ideally this
        // should be handled by RenderEditable instead.
        final double dx = paintOffsetAlignment == 0 ? 0 : paintOffsetAlignment * layoutCache.contentWidth;
        return Offset(dx, lineVerticalOffset);
      case _LineCaretMetrics(writingDirection: TextDirection.ltr, :final Offset offset):
        rawOffset = offset;
      case _LineCaretMetrics(writingDirection: TextDirection.rtl, :final Offset offset):
        rawOffset = Offset(offset.dx - caretPrototype.width, offset.dy);
    }
    // If offset.dx is outside of the advertised content area, then the associated
    // glyph cluster belongs to a trailing newline character. Ideally the behavior
    // should be handled by higher-level implementations (for instance,
    // RenderEditable reserves width for showing the caret, it's best to handle
    // the clamping there).
    final double adjustedDx = clampDouble(rawOffset.dx + layoutCache.paintOffset.dx, 0, layoutCache.contentWidth);
    return Offset(adjustedDx, rawOffset.dy + layoutCache.paintOffset.dy);
  }

  /// {@template flutter.painting.textPainter.getFullHeightForCaret}
  /// Returns the strut bounded height of the glyph at the given `position`.
  /// {@endtemplate}
  ///
  /// Valid only after [layout] has been called.
  double? getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
    if (position.offset < 0) {
      // TODO(LongCatIsLooong): make this case impossible; see https://github.com/flutter/flutter/issues/79495
      return null;
    }
    return switch (_computeCaretMetrics(position)) {
      _LineCaretMetrics(:final double fullHeight) => fullHeight,
      _EmptyLineCaretMetrics() => null,
    };
  }

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullHeightForCaret] in a row without performing redundant and expensive
  // get rect calls to the paragraph.
  late _CaretMetrics _caretMetrics;

  // Checks if the [position] and [caretPrototype] have changed from the cached
  // version and recomputes the metrics required to position the caret.
  _CaretMetrics _computeCaretMetrics(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    if (position == cachedLayout._previousCaretPosition) {
      return _caretMetrics;
    }
    final int offset = position.offset;
    final _CaretMetrics? metrics = switch (position.affinity) {
      TextAffinity.upstream => _getMetricsFromUpstream(offset) ?? _getMetricsFromDownstream(offset),
      TextAffinity.downstream => _getMetricsFromDownstream(offset) ?? _getMetricsFromUpstream(offset),
    };
    // Cache the input parameters to prevent repeat work later.
    cachedLayout._previousCaretPosition = position;
    return _caretMetrics = metrics ?? const _EmptyLineCaretMetrics(lineVerticalOffset: 0);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// The [selection] must be a valid range (with [TextSelection.isValid] true).
  ///
  /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
  /// the shape of the [TextBox]s. These properties default to
  /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Leading or trailing newline characters will be represented by zero-width
  /// `TextBox`es.
  ///
  /// The method only returns `TextBox`es of glyphs that are entirely enclosed by
  /// the given `selection`: a multi-code-unit glyph will be excluded if only
  /// part of its code units are in `selection`.
  List<TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    assert(_debugAssertTextLayoutIsValid);
    assert(selection.isValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    final Offset offset = cachedLayout.paintOffset;
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return <TextBox>[];
    }
    final List<TextBox> boxes = cachedLayout.paragraph.getBoxesForRange(
      selection.start,
      selection.end,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
    return offset == Offset.zero
      ? boxes
      : boxes.map((TextBox box) => _shiftTextBox(box, offset)).toList(growable: false);
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset cachedLayout = _layoutCache!;
    return cachedLayout.paragraph.getPositionForOffset(offset - cachedLayout.paintOffset);
  }

  /// {@template flutter.painting.TextPainter.getWordBoundary}
  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  /// {@endtemplate}
  TextRange getWordBoundary(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.paragraph.getWordBoundary(position);
  }

  /// {@template flutter.painting.TextPainter.wordBoundaries}
  /// Returns a [TextBoundary] that can be used to perform word boundary analysis
  /// on the current [text].
  ///
  /// This [TextBoundary] uses word boundary rules defined in [Unicode Standard
  /// Annex #29](http://www.unicode.org/reports/tr29/#Word_Boundaries).
  /// {@endtemplate}
  ///
  /// Currently word boundary analysis can only be performed after [layout]
  /// has been called.
  WordBoundary get wordBoundaries => WordBoundary._(text!, _layoutCache!.paragraph);

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline (if any) is not returned as part of the range.
  TextRange getLineBoundary(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    return _layoutCache!.paragraph.getLineBoundary(position);
  }

  static ui.LineMetrics _shiftLineMetrics(ui.LineMetrics metrics, Offset offset) {
    assert(offset.dx.isFinite);
    assert(offset.dy.isFinite);
    return ui.LineMetrics(
      hardBreak: metrics.hardBreak,
      ascent: metrics.ascent,
      descent: metrics.descent,
      unscaledAscent: metrics.unscaledAscent,
      height: metrics.height,
      width: metrics.width,
      left: metrics.left + offset.dx,
      baseline: metrics.baseline + offset.dy,
      lineNumber: metrics.lineNumber,
    );
  }

  static TextBox _shiftTextBox(TextBox box, Offset offset) {
    assert(offset.dx.isFinite);
    assert(offset.dy.isFinite);
    return TextBox.fromLTRBD(
      box.left + offset.dx,
      box.top + offset.dy,
      box.right + offset.dx,
      box.bottom + offset.dy,
      box.direction,
    );
  }

  /// Returns the full list of [LineMetrics] that describe in detail the various
  /// metrics of each laid out line.
  ///
  /// The [LineMetrics] list is presented in the order of the lines they represent.
  /// For example, the first line is in the zeroth index.
  ///
  /// [LineMetrics] contains measurements such as ascent, descent, baseline, and
  /// width for the line as a whole, and may be useful for aligning additional
  /// widgets to a particular line.
  ///
  /// Valid only after [layout] has been called.
  List<ui.LineMetrics> computeLineMetrics() {
    assert(_debugAssertTextLayoutIsValid);
    assert(!_debugNeedsRelayout);
    final _TextPainterLayoutCacheWithOffset layout = _layoutCache!;
    final Offset offset = layout.paintOffset;
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return const <ui.LineMetrics>[];
    }
    final List<ui.LineMetrics> rawMetrics = layout.lineMetrics;
    return offset == Offset.zero
      ? rawMetrics
      : rawMetrics.map((ui.LineMetrics metrics) => _shiftLineMetrics(metrics, offset)).toList(growable: false);
  }

  bool _disposed = false;

  /// Whether this object has been disposed or not.
  ///
  /// Only for use when asserts are enabled.
  bool get debugDisposed {
    bool? disposed;
    assert(() {
      disposed = _disposed;
      return true;
    }());
    return disposed ?? (throw StateError('debugDisposed only available when asserts are on.'));
  }

  /// Releases the resources associated with this painter.
  ///
  /// After disposal this painter is unusable.
  void dispose() {
    assert(() {
      _disposed = true;
      return true;
    }());
    _layoutTemplate?.dispose();
    _layoutTemplate = null;
    _layoutCache?.paragraph.dispose();
    _layoutCache = null;
    _text = null;
  }
}
