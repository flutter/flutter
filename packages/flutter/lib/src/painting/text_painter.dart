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
/// The [size] and [alignment] properties are required and cannot be null.
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
  }) : assert(size != null),
       assert(alignment != null);

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
    return 'PlaceholderDimensions($size, $baseline${baselineOffset == null ? ", $baselineOffset" : ""})';
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
      TextPainter._isHighSurrogate(highSurrogate),
      'U+${highSurrogate.toRadixString(16).toUpperCase().padLeft(4, "0")}) is not a high surrogate.',
    );
    assert(
      TextPainter._isLowSurrogate(lowSurrogate),
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
    switch (codeUnitAtIndex & 0xFC00) {
      case 0xD800:
        return _codePointFromSurrogates(codeUnitAtIndex, _text.codeUnitAt(index + 1)!);
      case 0xDC00:
        return _codePointFromSurrogates(_text.codeUnitAt(index - 1)!, codeUnitAtIndex);
      default:
        return codeUnitAtIndex;
    }
  }

  static bool _isNewline(int codePoint) {
    switch (codePoint) {
      case 0x000A:
      case 0x0085:
      case 0x000B:
      case 0x000C:
      case 0x2028:
      case 0x2029:
        return true;
      default:
        return false;
    }
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
  ui.Paragraph _paragraph;

  // Unfortunately, using full precision floating point here causes bad layouts
  // because floating point math isn't associative. If we add and subtract
  // padding, for example, we'll get different values when we estimate sizes and
  // when we actually compute layout because the operations will end up associated
  // differently. To work around this problem for now, we round fractional pixel
  // values up to the nearest whole pixel value. The right long-term fix is to do
  // layout using fixed precision arithmetic.
  static double _applyFloatingPointHack(double layoutValue) => layoutValue.ceilToDouble();

  /// Whether this layout has been invalidated and disposed.
  ///
  /// Only for use when asserts are enabled.
  bool get debugDisposed => _paragraph.debugDisposed;

  /// The horizontal space required to paint this text.
  ///
  /// If a line ends with trailing spaces, the trailing spaces may extend
  /// outside of the horizontal paint bounds defined by [width].
  double get width => _applyFloatingPointHack(_paragraph.width);

  /// The vertical space required to paint this text.
  double get height => _applyFloatingPointHack(_paragraph.height);

  /// The width at which decreasing the width of the text would prevent it from
  /// painting itself completely within its bounds.
  double get minIntrinsicLineExtent => _applyFloatingPointHack(_paragraph.minIntrinsicWidth);

  /// The width at which increasing the width of the text no longer decreases the height.
  ///
  /// Includes trailing spaces if any.
  double get maxIntrinsicLineExtent => _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);

  /// The distance from the left edge of the leftmost glyph to the right edge of
  /// the rightmost glyph in the paragraph.
  double get longestLine => _applyFloatingPointHack(_paragraph.longestLine);

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  double getDistanceToBaseline(TextBaseline baseline) {
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
  }
}

class _TextPainterLayoutCache {
  _TextPainterLayoutCache(this.layout, this.offset, this.contentWidth)
    : assert(offset.dy == 0),
      assert(!offset.dx.isNaN);

  final _TextLayout layout;
  double contentWidth;
  Offset offset;

  ui.Paragraph get paragraph => layout._paragraph;

  List<TextBox>? _inlinePlaceholderBoxes;
  List<ui.LineMetrics>? _lineMetricsCache;
  // Holds the TextPosition the last caret metrics were computed with. When new
  // values are passed in, we recompute the caret metrics. only as necessary.
  TextPosition? _previousCaretPosition;
}

/// This is used to cache and pass the computed metrics regarding the
/// caret's size and position. This is preferred due to the expensive
/// nature of the calculation.
//  This should be a sealed class: A _CaretMetrics is either a _LineCaretMetrics
//  or an _EmptyLineCaretMetrics.
class _CaretMetrics {}

// The _caretMetrics for carets located in a non-empty line. Carets located in a
// non-empty line are associated with a glyph within the same line.
class _LineCaretMetrics implements _CaretMetrics {
  const _LineCaretMetrics({required this.offset, required this.writingDirection, required this.fullHeight});
  /// The offset of the top left corner of the caret from the top left
  /// corner of the paragraph.
  final Offset offset;
  /// The writing direction of the glyph the _CaretMetrics is associated with.
  final TextDirection writingDirection;
  /// The full height of the glyph at the caret position.
  final double fullHeight;
}

// The _CaretMetrics for carets that on an unoccupied line (when the text is
// empty or immediately after a newline character).
class _EmptyLineCaretMetrics implements _CaretMetrics {
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
  /// The [textAlign] property must not be null.
  ///
  /// The [maxLines] property, if non-null, must be greater than zero.
  TextPainter({
    InlineSpan? text,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
  }) : assert(text == null || text.debugAssertIsValid()),
       assert(textAlign != null),
       assert(textScaleFactor != null),
       assert(maxLines == null || maxLines > 0),
       assert(textWidthBasis != null),
       _text = text,
       _textAlign = textAlign,
       _textDirection = textDirection,
       _textScaleFactor = textScaleFactor,
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
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    double minWidth = 0.0,
    double maxWidth = double.infinity,
  }) {
    final TextPainter painter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
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
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    double minWidth = 0.0,
    double maxWidth = double.infinity,
  }) {
    final TextPainter painter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
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

  // _paragraph being null means the text needs layout because of style changes.
  // Setting _paragraph to null invalidates all the layout cache.
  //
  // The TextPainter class should not aggressively invalidate the layout as long
  // as `markNeedsLayout` is not called (i.e., the layout cache is still valid).
  // See: https://github.com/flutter/flutter/issues/85108
  _TextPainterLayoutCache? _layoutCache;
  // Whether _paragraph contains outdated paint information and needs to be
  // rebuilt before painting.
  bool _rebuildParagraphForPaint = true;

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
      // Don't clear the _paragraph instance variable just yet. It still
      // contains valid layout information.
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
  /// The [textAlign] property must not be null. It defaults to [TextAlign.start].
  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
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

  static double _computePaintOffsetFraction(TextAlign textAlign, TextDirection textDirection) {
    switch (textAlign) {
      case TextAlign.left:
        return 0;
      case TextAlign.right:
        return 1;
      case TextAlign.center:
        return 0.5;
      case TextAlign.start:
      // eot is also considered a hard break.
      case TextAlign.justify:
        switch (textDirection) {
          case TextDirection.rtl:
            return 1;
          case TextDirection.ltr:
            return 0;
        }
      case TextAlign.end:
        switch (textDirection) {
          case TextDirection.rtl:
            return 0;
          case TextDirection.ltr:
            return 1;
        }
    }
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textScaleFactor == value) {
      return;
    }
    _textScaleFactor = value;
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
    assert(value != null);
    if (_textWidthBasis == value) {
      return;
    }
    _textWidthBasis = value;
    markNeedsLayout();
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
    final _TextPainterLayoutCache? layout = _layoutCache;
    if (layout == null) {
      return null;
    }
    final List<TextBox> rawBoxes = layout._inlinePlaceholderBoxes
                               ??= layout.paragraph.getBoxesForPlaceholders();
    final Offset offset = layout.offset;
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return <TextBox>[];
    }
    if (offset == Offset.zero) {
      return rawBoxes;
    }
    return rawBoxes.map((TextBox box) => _shiftTextBox(box, offset)).toList(growable: false);
  }

  /// An ordered list of scales for each placeholder in the paragraph.
  ///
  /// The scale is used as a multiplier on the height, width and baselineOffset of
  /// the placeholder. Scale is primarily used to handle accessibility scaling.
  ///
  /// Each scale corresponds to a [PlaceholderSpan] in the order they were defined
  /// in the [InlineSpan] tree.
  List<double>? get inlinePlaceholderScales => _inlinePlaceholderScales;
  List<double>? _inlinePlaceholderScales;

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
        return value.length >= placeholderCount ;
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
    assert(textAlign != null);
    assert(textDirection != null || defaultTextDirection != null, 'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    return _text!.style?.getParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection ?? defaultTextDirection,
      textScaleFactor: textScaleFactor,
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
      // fail to apply textScaleFactor.
      fontSize: _kDefaultFontSize * textScaleFactor,
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
    final ui.TextStyle? textStyle = text?.style?.getTextStyle(textScaleFactor: textScaleFactor);
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
    return _layoutCache!.contentWidth.ceilToDouble();
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
    return Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugAssertTextLayoutIsValid);
    assert(baseline != null);
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
    text.build(builder, textScaleFactor: textScaleFactor, dimensions: _placeholderDimensions);
    _inlinePlaceholderScales = builder.placeholderScales;
    assert(() {
      _debugMarkNeedsLayoutCallStack = null;
      return true;
    }());
    return builder.build();
  }

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a width that's as close to its max intrinsic
  /// width as possible while still being greater than or equal to `minWidth` and
  /// less than or equal to `maxWidth`.
  ///
  /// The [text] and [textDirection] properties must be non-null before this is
  /// called.
  void layout({ double minWidth = 0.0, double maxWidth = double.infinity }) {
    assert(!maxWidth.isNaN);
    assert(!minWidth.isNaN);
    final InlineSpan? text = this.text;
    if (text == null) {
      throw StateError('TextPainter.text must be set to a non-null value before using the TextPainter.');
    }
    final TextDirection? textDirection = this.textDirection;
    if (textDirection == null) {
      throw StateError('TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    }
    final _TextPainterLayoutCache? cachedLayout = _layoutCache;
    final double paintOffsetAlignment = _computePaintOffsetFraction(textAlign, textDirection);

    // The assumption here is that if a Paragraph's width is already >= its
    // maxIntrinsicWidth, further increasing the input width does not change its
    // layout (but may change the paint offset if it's not left-aligned). This is
    // true even for TextAlign.justify, since eot is also considered a hard
    // line break so it will behave exactly the same as TextAlign.start when its
    // width >= maxIntrinsicWidth.
    //
    // An exception to this is when the text is not left-aligned, and the input
    // width is double.infinity. Since the resulting Paragraph will have a width
    // of double.infinity, and to make the text visible the paintOffset.dx is
    // bound to be double.negativeInfinity, which invalidates all arithmetic
    // operations.
    final bool needsLayout = cachedLayout == null
      || (maxWidth != cachedLayout.layout.width
        // Always needsLayout when the current paintOffset and the paragraph
        // width are not finite: we won't be able to translate the paint offset
        // using addition/subtraction.
        && ((!cachedLayout.offset.dx.isFinite && !cachedLayout.paragraph.width.isFinite)
          || cachedLayout.layout.width < cachedLayout.layout.maxIntrinsicLineExtent
          || maxWidth < cachedLayout.layout.maxIntrinsicLineExtent));

    final _TextLayout newLayout;
    if (needsLayout) {
      // Try to avoid laying out the paragraph with maxWith=double.infinity
      // when the text is not left-aligned. When maxIntrinsicWidth is still
      // unkown, use a relatively large number with decent precision instead of
      // double.infinity.
      const double largeWidth = 32768; // 2^15, mantissa precision: 2^15/2^52 ≅ 7.2759576e-12.
      final bool adjustMaxWidth = !maxWidth.isFinite && paintOffsetAlignment != 0;
      final double adjustedMaxWidth = !adjustMaxWidth
        ? maxWidth
        : cachedLayout?.layout.maxIntrinsicLineExtent ?? largeWidth;

      final ui.Paragraph paragraph = _createParagraph(text)..layout(ui.ParagraphConstraints(width: adjustedMaxWidth));

      // If largeWidth is not large enough for the text, we'll have to (at least)
      // re-run the line breaking algorithm.
      if (adjustMaxWidth && paragraph.maxIntrinsicWidth > adjustedMaxWidth) {
        paragraph.layout(ui.ParagraphConstraints(width: paragraph.maxIntrinsicWidth));
      }
      newLayout = _TextLayout._(paragraph);
    } else {
      newLayout = cachedLayout.layout;
    }

    final double intrinsicWidth;
    switch (textWidthBasis) {
      case TextWidthBasis.longestLine:
        intrinsicWidth = newLayout.longestLine;
        break;
      case TextWidthBasis.parent:
        intrinsicWidth = newLayout.maxIntrinsicLineExtent;
        break;
    }

    // The content width the text painter should report after applying this
    // paintOffset;
    final double contentWidth = clampDouble(intrinsicWidth, minWidth, maxWidth);
    final double originX = paintOffsetAlignment == 0 ? 0 : paintOffsetAlignment * (contentWidth - newLayout._paragraph.width);
    if (needsLayout) {
      // If needsLayout is false, we'll rebuild the paragraph in the paint method.
      _rebuildParagraphForPaint = false;
      _layoutCache?.paragraph.dispose();
      _layoutCache = _TextPainterLayoutCache(newLayout, Offset(originX, 0), contentWidth);
    } else {
      assert(cachedLayout.layout == newLayout);
      cachedLayout.contentWidth = contentWidth;
      cachedLayout.offset = Offset(originX, 0);
    }
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
    final _TextPainterLayoutCache? layoutCache = _layoutCache;
    if (layoutCache == null) {
      throw StateError(
        'TextPainter.paint called when text geometry was not yet calculated.\n'
        'Please call layout() before paint() to position the text before painting it.',
      );
    }

    if (!layoutCache.offset.dx.isFinite || !layoutCache.offset.dy.isFinite) {
      return;
    }

    if (_rebuildParagraphForPaint) {
      _rebuildParagraphForPaint = false;
      Size? debugSize;
      assert(() {
        debugSize = size;
        return true;
      }());

      final ui.Paragraph paragraph = layoutCache.layout._paragraph;
      // Unfortunately even we know for sure that there is only paint changes,
      // there's no API to only make those updates so the paragraph has to be
      // recreated and redo layout.
      layoutCache.layout._paragraph = _createParagraph(text!)..layout(ui.ParagraphConstraints(width: layoutCache.layout.width));
      assert(paragraph.width == layoutCache.layout.width);
      paragraph.dispose();
      assert(debugSize == size);
    }
    canvas.drawParagraph(layoutCache.paragraph, offset + layoutCache.offset);
  }

  // Returns true iff the given value is a valid UTF-16 high surrogate. The value
  // must be a UTF-16 code unit, meaning it must be in the range 0x0000-0xFFFF.
  //
  // See also:
  //   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
  static bool _isHighSurrogate(int value) {
    return value & 0xFC00 == 0xD800;
  }

  // Whether the given UTF-16 code unit is a low (second) surrogate.
  static bool _isLowSurrogate(int value) {
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
    return _isHighSurrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  /// Returns the closest offset before `offset` at which the input cursor can
  /// be positioned.
  int? getOffsetBefore(int offset) {
    final int? prevCodeUnit = _text!.codeUnitAt(offset - 1);
    if (prevCodeUnit == null) {
      return null;
    }
    // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
    return _isLowSurrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  // Unicode value for a zero width joiner character.
  static const int _zwjUtf16 = 0x200d;

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character upstream from the given string offset.
  _CaretMetrics? _getMetricsFromUpstream(int offset) {
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0 || offset > plainTextLength) {
      return null;
    }
    final int prevCodeUnit = plainText.codeUnitAt(max(0, offset - 1));

    // If the upstream character is a newline, cursor is at start of next line
    const int NEWLINE_CODE_UNIT = 10;

    // Check for multi-code-unit glyphs such as emojis or zero width joiner.
    final bool needsSearch = _isHighSurrogate(prevCodeUnit) || _isLowSurrogate(prevCodeUnit) || _text!.codeUnitAt(offset) == _zwjUtf16 || _isUnicodeDirectionality(prevCodeUnit);
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty) {
      final int prevRuneOffset = offset - graphemeClusterLength;
      // Use BoxHeightStyle.strut to ensure that the caret's height fits within
      // the line's height and is consistent throughout the line.
      boxes = _layoutCache!.paragraph.getBoxesForRange(prevRuneOffset, offset, boxHeightStyle: ui.BoxHeightStyle.strut);
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
      final TextBox box = boxes.first;
      return prevCodeUnit == NEWLINE_CODE_UNIT
        ? _EmptyLineCaretMetrics(lineVerticalOffset: box.bottom)
        : _LineCaretMetrics(offset: Offset(box.end, box.top), writingDirection: box.direction, fullHeight: box.bottom - box.top);
    }
    return null;
  }

  // Get the caret metrics (in logical pixels) based off the near edge of the
  // character downstream from the given string offset.
  _CaretMetrics? _getMetricsFromDownstream(int offset) {
    final int plainTextLength = plainText.length;
    if (plainTextLength == 0 || offset < 0) {
      return null;
    }
    // We cap the offset at the final index of plain text.
    final int nextCodeUnit = plainText.codeUnitAt(min(offset, plainTextLength - 1));

    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final bool needsSearch = _isHighSurrogate(nextCodeUnit) || _isLowSurrogate(nextCodeUnit) || nextCodeUnit == _zwjUtf16 || _isUnicodeDirectionality(nextCodeUnit);
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
      final TextBox box = boxes.last;
      return _LineCaretMetrics(offset: Offset(box.start, box.top), writingDirection: box.direction, fullHeight: box.bottom - box.top);
    }
    return null;
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final _CaretMetrics caretMetrics = _computeCaretMetrics(position);
    final _TextPainterLayoutCache layoutCache = _layoutCache!;

    if (caretMetrics is _EmptyLineCaretMetrics) {
      final double paintOffsetAlignment = _computePaintOffsetFraction(textAlign, textDirection!);
      // The full width is not (layoutCache.contentWidth - caretPrototype.width)
      // because RenderEditable reserves cursor width on the right. Ideally this
      // should be handled by
      final double dx = paintOffsetAlignment == 0 ? 0 : paintOffsetAlignment * layoutCache.contentWidth;
      return Offset(dx, caretMetrics.lineVerticalOffset);
    }

    final Offset offset;
    switch ((caretMetrics as _LineCaretMetrics).writingDirection) {
      case TextDirection.rtl:
        offset = Offset(caretMetrics.offset.dx - caretPrototype.width, caretMetrics.offset.dy) + layoutCache.offset;
        break;
      case TextDirection.ltr:
        offset = caretMetrics.offset + layoutCache.offset;
        break;
    }
    // If offset.dx is outside of the advertised content area, then the associated
    // glyph belongs to a trailing newline character. Ideally the behavior
    // should be handled by higher-level implementations (for instance,
    // RenderEditable reserves width for showing the caret, it's best to handle
    // the clamping there).
    final double adjustedDx = clampDouble(offset.dx, 0, layoutCache.contentWidth);
    return Offset(adjustedDx, offset.dy);
  }

  /// {@template flutter.painting.textPainter.getFullHeightForCaret}
  /// Returns the strut bounded height of the glyph at the given `position`.
  /// {@endtemplate}
  ///
  /// Valid only after [layout] has been called.
  double? getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
    final _CaretMetrics caretMetrics = _computeCaretMetrics(position);
    return caretMetrics is _LineCaretMetrics ? caretMetrics.fullHeight : null;
  }

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullHeightForCaret] in a row without performing redundant and expensive
  // get rect calls to the paragraph.
  late _CaretMetrics _caretMetrics;

  // Checks if the [position] and [caretPrototype] have changed from the cached
  // version and recomputes the metrics required to position the caret.
  _CaretMetrics _computeCaretMetrics(TextPosition position) {
    assert(_debugAssertTextLayoutIsValid);
    final _TextPainterLayoutCache cachedLayout = _layoutCache!;
    if (position == cachedLayout._previousCaretPosition) {
      return _caretMetrics;
    }
    final int offset = position.offset;
    assert(position.affinity != null);
    final _CaretMetrics? metrics;
    switch (position.affinity) {
      case TextAffinity.upstream: {
        metrics = _getMetricsFromUpstream(offset) ?? _getMetricsFromDownstream(offset);
        break;
      }
      case TextAffinity.downstream: {
        metrics = _getMetricsFromDownstream(offset) ?? _getMetricsFromUpstream(offset);
        break;
      }
    }
    // Cache the input parameters to prevent repeat work later.
    cachedLayout._previousCaretPosition = position;
    return _caretMetrics = metrics ?? const _EmptyLineCaretMetrics(lineVerticalOffset: 0);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
  /// the shape of the [TextBox]s. These properties default to
  /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively and
  /// must not be null.
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
    assert(boxHeightStyle != null);
    assert(boxWidthStyle != null);
    final _TextPainterLayoutCache cachedLayout = _layoutCache!;
    final List<TextBox> boxes = cachedLayout.paragraph.getBoxesForRange(
      selection.start,
      selection.end,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
    final Offset offset = cachedLayout.offset;
    if (!offset.dx.isFinite || !offset.dy.isFinite) {
      return <TextBox>[];
    }
    return offset == Offset.zero
      ? boxes
      : boxes.map((TextBox box) => _shiftTextBox(box, offset)).toList(growable: false);
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(_debugAssertTextLayoutIsValid);
    final _TextPainterLayoutCache cachedLayout = _layoutCache!;
    return cachedLayout.paragraph.getPositionForOffset(offset - cachedLayout.offset);
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
    return _layoutCache!.layout. _paragraph.getLineBoundary(position);
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
    final _TextPainterLayoutCache layout = _layoutCache!;
    final List<ui.LineMetrics> rawMetrics = layout._lineMetricsCache ??= layout.paragraph.computeLineMetrics();
    if (!layout.offset.dx.isFinite || !layout.offset.dy.isFinite) {
      return const <ui.LineMetrics>[];
    }
    return layout.offset == Offset.zero
      ? rawMetrics
      : rawMetrics.map((ui.LineMetrics metrics) => _shiftLineMetrics(metrics, layout.offset)).toList(growable: false);
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
