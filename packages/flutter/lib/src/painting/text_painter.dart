// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph, ParagraphBuilder, ParagraphConstraints, ParagraphStyle, TextBox;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'text_span.dart';

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

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
  /// The text argument is optional but [text] must be non-null before calling
  /// [layout].
  TextPainter({
    TextSpan text,
    TextAlign textAlign,
    double textScaleFactor: 1.0,
    int maxLines,
    String ellipsis,
  }) : _text = text, _textAlign = textAlign, _textScaleFactor = textScaleFactor, _maxLines = maxLines, _ellipsis = ellipsis {
    assert(text == null || text.debugAssertIsValid());
    assert(textScaleFactor != null);
  }

  ui.Paragraph _paragraph;
  bool _needsLayout = true;

  /// The (potentially styled) text to paint.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  TextSpan get text => _text;
  TextSpan _text;
  set text(TextSpan value) {
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
  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value)
      return;
    _textAlign = value;
    _paragraph = null;
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

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary.
  ///
  /// If the text exceeds the given number of lines, it is truncated such that
  /// subsequent lines are dropped.
  ///
  /// After this is set, you must call [layout] before the next call to [paint].
  int get maxLines => _maxLines;
  int _maxLines;
  set maxLines(int value) {
    if (_maxLines == value)
      return;
    _maxLines = value;
    _paragraph = null;
    _needsLayout = true;
  }

  ui.Paragraph _layoutTemplate;

  /// The height of a zero-width space in [text] in logical pixels.
  ///
  /// Not every line of text in [text] will have this height, but this height
  /// is "typical" for text in [text] and useful for sizing other objects
  /// relative a typical line of text.
  double get preferredLineHeight {
    assert(text != null);
    if (_layoutTemplate == null) {
      final ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle());
      if (text.style != null)
        builder.pushStyle(text.style.getTextStyle(textScaleFactor: textScaleFactor));
      builder.addText(_kZeroWidthSpace);
      _layoutTemplate = builder.build()
        ..layout(new ui.ParagraphConstraints(width: double.INFINITY));
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

  /// The width at which decreasing the width of the text would prevent it from painting itself completely within its bounds.
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
    return _applyFloatingPointHack(_paragraph.width);
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
    return new Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the
  /// given type.
  ///
  /// Valid only after [layout] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
    assert(baseline != null);
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
  /// width as possible while still being greater than or equal to minWidth and
  /// less than or equal to maxWidth.
  void layout({ double minWidth: 0.0, double maxWidth: double.INFINITY }) {
    assert(_text != null);
    if (!_needsLayout && minWidth == _lastMinWidth && maxWidth == _lastMaxWidth)
      return;
    _needsLayout = false;
    if (_paragraph == null) {
      ui.ParagraphStyle paragraphStyle = _text.style?.getParagraphStyle(
        textAlign: textAlign,
        textScaleFactor: textScaleFactor,
        maxLines: _maxLines,
        ellipsis: _ellipsis,
      );
      paragraphStyle ??= new ui.ParagraphStyle(
        textAlign: textAlign,
        maxLines: maxLines,
        ellipsis: ellipsis,
      );
      final ui.ParagraphBuilder builder = new ui.ParagraphBuilder(paragraphStyle);
      _text.build(builder, textScaleFactor: textScaleFactor);
      _paragraph = builder.build();
    }
    _lastMinWidth = minWidth;
    _lastMaxWidth = maxWidth;
    _paragraph.layout(new ui.ParagraphConstraints(width: maxWidth));
    if (minWidth != maxWidth) {
      final double newWidth = maxIntrinsicWidth.clamp(minWidth, maxWidth);
      if (newWidth != width)
        _paragraph.layout(new ui.ParagraphConstraints(width: newWidth));
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
    assert(() {
      if (_needsLayout) {
        throw new FlutterError(
          'TextPainter.paint called when text geometry was not yet calculated.\n'
          'Please call layout() before paint() to position the text before painting it.'
        );
      }
      return true;
    });
    canvas.drawParagraph(_paragraph, offset);
  }

  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  Offset _getOffsetFromUpstream(int offset, Rect caretPrototype) {
    final int prevCodeUnit = _text.codeUnitAt(offset - 1);
    if (prevCodeUnit == null)
      return null;
    final int prevRuneOffset = _isUtf16Surrogate(prevCodeUnit) ? offset - 2 : offset - 1;
    final List<ui.TextBox> boxes = _paragraph.getBoxesForRange(prevRuneOffset, offset);
    if (boxes.isEmpty)
      return null;
    final ui.TextBox box = boxes[0];
    final double caretEnd = box.end;
    final double dx = box.direction == TextDirection.rtl ? caretEnd : caretEnd - caretPrototype.width;
    return new Offset(dx, box.top);
  }

  Offset _getOffsetFromDownstream(int offset, Rect caretPrototype) {
    final int nextCodeUnit = _text.codeUnitAt(offset + 1);
    if (nextCodeUnit == null)
      return null;
    final int nextRuneOffset = _isUtf16Surrogate(nextCodeUnit) ? offset + 2 : offset + 1;
    final List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset, nextRuneOffset);
    if (boxes.isEmpty)
      return null;
    final ui.TextBox box = boxes[0];
    final double caretStart = box.start;
    final double dx = box.direction == TextDirection.rtl ? caretStart - caretPrototype.width : caretStart;
    return new Offset(dx, box.top);
  }

  Offset get _emptyOffset {
    // TODO(abarth): Handle the directionality of the text painter itself.
    switch (textAlign ?? TextAlign.left) {
      case TextAlign.left:
      case TextAlign.justify:
        return Offset.zero;
      case TextAlign.right:
        return new Offset(width, 0.0);
      case TextAlign.center:
        return new Offset(width / 2.0, 0.0);
    }
    return null;
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    final int offset = position.offset;
    switch (position.affinity) {
      case TextAffinity.upstream:
        return _getOffsetFromUpstream(offset, caretPrototype)
            ?? _getOffsetFromDownstream(offset, caretPrototype)
            ?? _emptyOffset;
      case TextAffinity.downstream:
        return _getOffsetFromDownstream(offset, caretPrototype)
            ?? _getOffsetFromUpstream(offset, caretPrototype)
            ?? _emptyOffset;
    }
    assert(position.affinity != null);
    return null;
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
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
    return new TextRange(start: indices[0], end: indices[1]);
  }
}
