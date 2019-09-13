// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show min, max;
import 'dart:ui' as ui show Paragraph, ParagraphBuilder, ParagraphConstraints, ParagraphStyle, PlaceholderAlignment, LineMetrics;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'inline_span.dart';
import 'placeholder_span.dart';
import 'strut_style.dart';
import 'text_span.dart';

export 'package:flutter/services.dart' show TextRange, TextSelection;

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
    @required this.size,
    @required this.alignment,
    this.baseline,
    this.baselineOffset,
  }) : assert(size != null),
       assert(alignment != null);

  /// Width and height dimensions of the placeholder.
  final Size size;

  /// How to align the placeholder with the text.
  ///
  /// See also:
  ///
  ///  * [baseline], the baseline to align to when using
  ///    [ui.PlaceholderAlignment.baseline],
  ///    [ui.PlaceholderAlignment.aboveBaseline],
  ///    or [ui.PlaceholderAlignment.underBaseline].
  ///  * [baselineOffset], the distance of the alphabetic baseline from the upper
  ///    edge of the placeholder.
  final ui.PlaceholderAlignment alignment;

  /// Distance of the [baseline] from the upper edge of the placeholder.
  ///
  /// Only used when [alignment] is [ui.PlaceholderAlignment.baseline].
  final double baselineOffset;

  /// The [TextBaseline] to align to. Used with:
  ///
  ///  * [ui.PlaceholderAlignment.baseline]
  ///  * [ui.PlaceholderAlignment.aboveBaseline]
  ///  * [ui.PlaceholderAlignment.underBaseline]
  ///  * [ui.PlaceholderAlignment.middle]
  final TextBaseline baseline;

  @override
  String toString() {
    return 'PlaceholderDimensions($size, $baseline)';
  }
}

/// The different ways of measuring the width of one or more lines of text.
///
/// See [Text.textWidthBasis], for example.
enum TextWidthBasis {
  /// Multiline text will take up the full width given by the parent. For single
  /// line text, only the minimum amount of width needed to contain the text
  /// will be used. A common use case for this is a standard series of
  /// paragraphs.
  parent,

  /// The width will be exactly enough to contain the longest line and no
  /// longer. A common use case for this is chat bubbles.
  longestLine,
}

/// This is used to cache and pass the computed metrics regarding the
/// caret's size and position. This is preferred due to the expensive
/// nature of the calculation.
class _CaretMetrics {
  const _CaretMetrics({this.offset, this.fullHeight});
  /// The offset of the top left corner of the caret from the top left
  /// corner of the paragraph.
  final Offset offset;

  /// The full height of the glyph at the caret position.
  final double fullHeight;
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
    InlineSpan text,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection,
    double textScaleFactor = 1.0,
    int maxLines,
    String ellipsis,
    Locale locale,
    StrutStyle strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
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
       _textWidthBasis = textWidthBasis;

  ui.Paragraph _paragraph;
  bool _needsLayout = true;

  /// The (potentially styled) text to paint.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  /// This and [textDirection] must be non-null before you call [layout].
  ///
  /// The [InlineSpan] this provides is in the form of a tree that may contain
  /// multiple instances of [TextSpan]s and [WidgetSpan]s. To obtain a plaintext
  /// representation of the contents of this [TextPainter], use [InlineSpan.toPlainText]
  /// to get the full contents of all nodes in the tree. [TextSpan.text] will
  /// only provide the contents of the first node in the tree.
  InlineSpan get text => _text;
  InlineSpan _text;
  set text(InlineSpan value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value)
      return;
    if (_text?.style != value?.style)
      _layoutTemplate = null;
    _text = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// How the text should be aligned horizontally.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  ///
  /// The [textAlign] property must not be null. It defaults to [TextAlign.start].
  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textAlign == value)
      return;
    _textAlign = value;
    _paragraph = null;
    _needsLayout = true;
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
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value)
      return;
    _textDirection = value;
    _paragraph = null;
    _layoutTemplate = null; // Shouldn't really matter, but for strict correctness...
    _needsLayout = true;
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
    if (_textScaleFactor == value)
      return;
    _textScaleFactor = value;
    _paragraph = null;
    _layoutTemplate = null;
    _needsLayout = true;
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
  String get ellipsis => _ellipsis;
  String _ellipsis;
  set ellipsis(String value) {
    assert(value == null || value.isNotEmpty);
    if (_ellipsis == value)
      return;
    _ellipsis = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// The locale used to select region-specific glyphs.
  Locale get locale => _locale;
  Locale _locale;
  set locale(Locale value) {
    if (_locale == value)
      return;
    _locale = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary.
  ///
  /// If the text exceeds the given number of lines, it is truncated such that
  /// subsequent lines are dropped.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  int get maxLines => _maxLines;
  int _maxLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int value) {
    assert(value == null || value > 0);
    if (_maxLines == value)
      return;
    _maxLines = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// {@template flutter.painting.textPainter.strutStyle}
  /// The strut style to use. Strut style defines the strut, which sets minimum
  /// vertical layout metrics.
  ///
  /// Omitting or providing null will disable strut.
  ///
  /// Omitting or providing null for any properties of [StrutStyle] will result in
  /// default values being used. It is highly recommended to at least specify a
  /// [fontSize].
  ///
  /// See [StrutStyle] for details.
  /// {@endtemplate}
  StrutStyle get strutStyle => _strutStyle;
  StrutStyle _strutStyle;
  set strutStyle(StrutStyle value) {
    if (_strutStyle == value)
      return;
    _strutStyle = value;
    _paragraph = null;
    _needsLayout = true;
  }

  /// {@template flutter.painting.textPainter.textWidthBasis}
  /// Defines how to measure the width of the rendered text.
  /// {@endtemplate}
  TextWidthBasis get textWidthBasis => _textWidthBasis;
  TextWidthBasis _textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    assert(value != null);
    if (_textWidthBasis == value)
      return;
    _textWidthBasis = value;
    _paragraph = null;
    _needsLayout = true;
  }


  ui.Paragraph _layoutTemplate;

  /// An ordered list of [TextBox]es that bound the positions of the placeholders
  /// in the paragraph.
  ///
  /// Each box corresponds to a [PlaceholderSpan] in the order they were defined
  /// in the [InlineSpan] tree.
  List<TextBox> get inlinePlaceholderBoxes => _inlinePlaceholderBoxes;
  List<TextBox> _inlinePlaceholderBoxes;

  /// An ordered list of scales for each placeholder in the paragraph.
  ///
  /// The scale is used as a multiplier on the height, width and baselineOffset of
  /// the placeholder. Scale is primarily used to handle accessibility scaling.
  ///
  /// Each scale corresponds to a [PlaceholderSpan] in the order they were defined
  /// in the [InlineSpan] tree.
  List<double> get inlinePlaceholderScales => _inlinePlaceholderScales;
  List<double> _inlinePlaceholderScales;

  /// Sets the dimensions of each placeholder in [text].
  ///
  /// The number of [PlaceholderDimensions] provided should be the same as the
  /// number of [PlaceholderSpan]s in text. Passing in an empty or null `value`
  /// will do nothing.
  ///
  /// If [layout] is attempted without setting the placeholder dimensions, the
  /// placeholders will be ignored in the text layout and no valid
  /// [inlinePlaceholderBoxes] will be returned.
  void setPlaceholderDimensions(List<PlaceholderDimensions> value) {
    if (value == null || value.isEmpty || listEquals(value, _placeholderDimensions)) {
      return;
    }
    assert(() {
      int placeholderCount = 0;
      text.visitChildren((InlineSpan span) {
        if (span is PlaceholderSpan) {
          placeholderCount += 1;
        }
        return true;
      });
      return placeholderCount;
    }() == value.length);
    _placeholderDimensions = value;
    _needsLayout = true;
    _paragraph = null;
  }
  List<PlaceholderDimensions> _placeholderDimensions;

  ui.ParagraphStyle _createParagraphStyle([ TextDirection defaultTextDirection ]) {
    // The defaultTextDirection argument is used for preferredLineHeight in case
    // textDirection hasn't yet been set.
    assert(textAlign != null);
    assert(textDirection != null || defaultTextDirection != null, 'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    return _text.style?.getParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection ?? defaultTextDirection,
      textScaleFactor: textScaleFactor,
      maxLines: _maxLines,
      ellipsis: _ellipsis,
      locale: _locale,
      strutStyle: _strutStyle,
    ) ?? ui.ParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection ?? defaultTextDirection,
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
    );
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
  double get preferredLineHeight {
    if (_layoutTemplate == null) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        _createParagraphStyle(TextDirection.rtl),
      ); // direction doesn't matter, text is just a space
      if (text?.style != null)
        builder.pushStyle(text.style.getTextStyle(textScaleFactor: textScaleFactor));
      builder.addText(' ');
      _layoutTemplate = builder.build()
        ..layout(const ui.ParagraphConstraints(width: double.infinity));
    }
    return _layoutTemplate.height;
  }

  // Unfortunately, using full precision floating point here causes bad layouts
  // because floating point math isn't associative. If we add and subtract
  // padding, for example, we'll get different values when we estimate sizes and
  // when we actually compute layout because the operations will end up associated
  // differently. To work around this problem for now, we round fractional pixel
  // values up to the nearest whole pixel value. The right long-term fix is to do
  // layout using fixed precision arithmetic.
  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }

  /// The width at which decreasing the width of the text would prevent it from
  /// painting itself completely within its bounds.
  ///
  /// Valid only after [layout] has been called.
  double get minIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicWidth);
  }

  /// The width at which increasing the width of the text no longer decreases the height.
  ///
  /// Valid only after [layout] has been called.
  double get maxIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(
      textWidthBasis == TextWidthBasis.longestLine ? _paragraph.longestLine : _paragraph.width,
    );
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] has been called.
  Size get size {
    assert(!_needsLayout);
    return Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    assert(baseline != null);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
    return null;
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
    assert(!_needsLayout);
    return _paragraph.didExceedMaxLines;
  }

  double _lastMinWidth;
  double _lastMaxWidth;

  /// Computes the visual position of the glyphs for painting the text.
  ///
  /// The text will layout with a width that's as close to its max intrinsic
  /// width as possible while still being greater than or equal to `minWidth` and
  /// less than or equal to `maxWidth`.
  ///
  /// The [text] and [textDirection] properties must be non-null before this is
  /// called.
  void layout({ double minWidth = 0.0, double maxWidth = double.infinity }) {
    assert(text != null, 'TextPainter.text must be set to a non-null value before using the TextPainter.');
    assert(textDirection != null, 'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    if (!_needsLayout && minWidth == _lastMinWidth && maxWidth == _lastMaxWidth)
      return;
    _needsLayout = false;
    if (_paragraph == null) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(_createParagraphStyle());
      _text.build(builder, textScaleFactor: textScaleFactor, dimensions: _placeholderDimensions);
      _inlinePlaceholderScales = builder.placeholderScales;
      _paragraph = builder.build();
    }
    _lastMinWidth = minWidth;
    _lastMaxWidth = maxWidth;
    _paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    if (minWidth != maxWidth) {
      final double newWidth = maxIntrinsicWidth.clamp(minWidth, maxWidth);
      if (newWidth != width) {
        _paragraph.layout(ui.ParagraphConstraints(width: newWidth));
      }
    }
    _inlinePlaceholderBoxes = _paragraph.getBoxesForPlaceholders();
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
    assert(() {
      if (_needsLayout) {
        throw FlutterError(
          'TextPainter.paint called when text geometry was not yet calculated.\n'
          'Please call layout() before paint() to position the text before painting it.'
        );
      }
      return true;
    }());
    canvas.drawParagraph(_paragraph, offset);
  }

  // Complex glyphs can be represented by two or more UTF16 codepoints. This
  // checks if the value represents a UTF16 glyph by itself or is a 'surrogate'.
  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  /// Returns the closest offset after `offset` at which the input cursor can be
  /// positioned.
  int getOffsetAfter(int offset) {
    final int nextCodeUnit = _text.codeUnitAt(offset);
    if (nextCodeUnit == null)
      return null;
    // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
    return _isUtf16Surrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  /// Returns the closest offset before `offset` at which the input cursor can
  /// be positioned.
  int getOffsetBefore(int offset) {
    final int prevCodeUnit = _text.codeUnitAt(offset - 1);
    if (prevCodeUnit == null)
      return null;
    // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
    return _isUtf16Surrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  // Unicode value for a zero width joiner character.
  static const int _zwjUtf16 = 0x200d;

  // Get the Rect of the cursor (in logical pixels) based off the near edge
  // of the character upstream from the given string offset.
  // TODO(garyq): Use actual extended grapheme cluster length instead of
  // an increasing cluster length amount to achieve deterministic performance.
  Rect _getRectFromUpstream(int offset, Rect caretPrototype) {
    final String flattenedText = _text.toPlainText(includePlaceholders: false);
    final int prevCodeUnit = _text.codeUnitAt(max(0, offset - 1));
    if (prevCodeUnit == null)
      return null;

    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final bool needsSearch = _isUtf16Surrogate(prevCodeUnit) || _text.codeUnitAt(offset) == _zwjUtf16;
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty && flattenedText != null) {
      final int prevRuneOffset = offset - graphemeClusterLength;
      boxes = _paragraph.getBoxesForRange(prevRuneOffset, offset);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the beginning of the line, a non-surrogate position will
        // return empty boxes. We break and try from downstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (prevRuneOffset < -flattenedText.length) {
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

      // If the upstream character is a newline, cursor is at start of next line
      const int NEWLINE_CODE_UNIT = 10;
      if (prevCodeUnit == NEWLINE_CODE_UNIT) {
        return Rect.fromLTRB(_emptyOffset.dx, box.bottom, _emptyOffset.dx, box.bottom + box.bottom - box.top);
      }

      final double caretEnd = box.end;
      final double dx = box.direction == TextDirection.rtl ? caretEnd - caretPrototype.width : caretEnd;
      return Rect.fromLTRB(min(dx, _paragraph.width), box.top, min(dx, _paragraph.width), box.bottom);
    }
    return null;
  }

  // Get the Rect of the cursor (in logical pixels) based off the near edge
  // of the character downstream from the given string offset.
  // TODO(garyq): Use actual extended grapheme cluster length instead of
  // an increasing cluster length amount to achieve deterministic performance.
  Rect _getRectFromDownstream(int offset, Rect caretPrototype) {
    final String flattenedText = _text.toPlainText(includePlaceholders: false);
    // We cap the offset at the final index of the _text.
    final int nextCodeUnit = _text.codeUnitAt(min(offset, flattenedText == null ? 0 : flattenedText.length - 1));
    if (nextCodeUnit == null)
      return null;
    // Check for multi-code-unit glyphs such as emojis or zero width joiner
    final bool needsSearch = _isUtf16Surrogate(nextCodeUnit) || nextCodeUnit == _zwjUtf16;
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty && flattenedText != null) {
      final int nextRuneOffset = offset + graphemeClusterLength;
      boxes = _paragraph.getBoxesForRange(offset, nextRuneOffset);
      // When the range does not include a full cluster, no boxes will be returned.
      if (boxes.isEmpty) {
        // When we are at the end of the line, a non-surrogate position will
        // return empty boxes. We break and try from upstream instead.
        if (!needsSearch) {
          break; // Only perform one iteration if no search is required.
        }
        if (nextRuneOffset >= flattenedText.length << 1) {
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
      final double caretStart = box.start;
      final double dx = box.direction == TextDirection.rtl ? caretStart - caretPrototype.width : caretStart;
      return Rect.fromLTRB(min(dx, _paragraph.width), box.top, min(dx, _paragraph.width), box.bottom);
    }
    return null;
  }

  Offset get _emptyOffset {
    assert(!_needsLayout); // implies textDirection is non-null
    assert(textAlign != null);
    switch (textAlign) {
      case TextAlign.left:
        return Offset.zero;
      case TextAlign.right:
        return Offset(width, 0.0);
      case TextAlign.center:
        return Offset(width / 2.0, 0.0);
      case TextAlign.justify:
      case TextAlign.start:
        assert(textDirection != null);
        switch (textDirection) {
          case TextDirection.rtl:
            return Offset(width, 0.0);
          case TextDirection.ltr:
            return Offset.zero;
        }
        return null;
      case TextAlign.end:
        assert(textDirection != null);
        switch (textDirection) {
          case TextDirection.rtl:
            return Offset.zero;
          case TextDirection.ltr:
            return Offset(width, 0.0);
        }
        return null;
    }
    return null;
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.offset;
  }

  /// Returns the tight bounded height of the glyph at the given [position].
  ///
  /// Valid only after [layout] has been called.
  double getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.fullHeight;
  }

  // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
  // [getFullHeightForCaret] in a row without performing redundant and expensive
  // get rect calls to the paragraph.
  _CaretMetrics _caretMetrics;

  // Holds the TextPosition and caretPrototype the last caret metrics were
  // computed with. When new values are passed in, we recompute the caret metrics.
  // only as necessary.
  TextPosition _previousCaretPosition;
  Rect _previousCaretPrototype;

  // Checks if the [position] and [caretPrototype] have changed from the cached
  // version and recomputes the metrics required to position the caret.
  void _computeCaretMetrics(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    if (position == _previousCaretPosition && caretPrototype == _previousCaretPrototype)
      return;
    final int offset = position.offset;
    assert(position.affinity != null);
    Rect rect;
    switch (position.affinity) {
      case TextAffinity.upstream: {
        rect = _getRectFromUpstream(offset, caretPrototype) ?? _getRectFromDownstream(offset, caretPrototype);
        break;
      }
      case TextAffinity.downstream: {
        rect = _getRectFromDownstream(offset, caretPrototype) ??  _getRectFromUpstream(offset, caretPrototype);
        break;
      }
    }
    _caretMetrics = _CaretMetrics(
      offset: rect != null ? Offset(rect.left, rect.top) : _emptyOffset,
      fullHeight: rect != null ? rect.bottom - rect.top : null,
    );

    // Cache the input parameters to prevent repeat work later.
    _previousCaretPosition = position;
    _previousCaretPrototype = caretPrototype;
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!_needsLayout);
    return _paragraph.getBoxesForRange(selection.start, selection.end);
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph.getPositionForOffset(offset);
  }

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  TextRange getWordBoundary(TextPosition position) {
    assert(!_needsLayout);
    final List<int> indices = _paragraph.getWordBoundary(position.offset);
    return TextRange(start: indices[0], end: indices[1]);
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
  ///
  /// This can potentially return a large amount of data, so it is not recommended
  /// to repeatedly call this. Instead, cache the results. The cached results
  /// should be invalidated upon the next sucessful [layout].
  List<ui.LineMetrics> computeLineMetrics() {
    assert(!_needsLayout);
    return _paragraph.computeLineMetrics();
  }
}
