// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph, ParagraphBuilder, ParagraphStyle, TextBox;

import 'basic_types.dart';
import 'text_editing.dart';
import 'text_style.dart';

/// An immutable span of text.
class TextSpan {
  const TextSpan({
    this.style,
    this.text,
    this.children
  });

  /// The style to apply to the text and the children.
  final TextStyle style;

  /// The text contained in the span.
  ///
  /// If both text and children are non-null, the text will preceed the
  /// children.
  final String text;

  /// Additional spans to include as children.
  ///
  /// If both text and children are non-null, the text will preceed the
  /// children.
  final List<TextSpan> children;

  void build(ui.ParagraphBuilder builder) {
    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style.textStyle);
    if (text != null)
      builder.addText(text);
    if (children != null) {
      for (TextSpan child in children) {
        assert(child != null);
        child.build(builder);
      }
    }
    if (hasStyle)
      builder.pop();
  }

  void writePlainText(StringBuffer result) {
    if (text != null)
      result.write(text);
    if (children != null) {
      for (TextSpan child in children)
        child.writePlainText(result);
    }
  }

  String toString([String prefix = '']) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('$prefix$runtimeType:');
    String indent = '$prefix  ';
    buffer.writeln(style.toString(indent));
    if (text != null)
      buffer.writeln('$indent"$text"');
    for (TextSpan child in children)
      buffer.writeln(child.toString(indent));
    return buffer.toString();
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextSpan)
      return false;
    final TextSpan typedOther = other;
    if (typedOther.text != text)
      return false;
    if (typedOther.style != style)
      return false;
    if ((typedOther.children == null) != (children == null))
      return false;
    if (children != null) {
      for (int i = 0; i < children.length; ++i) {
        if (typedOther.children[i] != children[i])
          return false;
      }
    }
    return true;
  }
  int get hashCode => hashValues(style, text, hashList(children));
}

/// An object that paints a [TextSpan] into a canvas.
class TextPainter {
  TextPainter([ TextSpan text ]) {
    this.text = text;
  }

  ui.Paragraph _paragraph;
  bool _needsLayout = true;

  TextSpan _text;
  /// The (potentially styled) text to paint.
  TextSpan get text => _text;
  void set text(TextSpan value) {
    if (_text == value)
      return;
    _text = value;
    ui.ParagraphBuilder builder = new ui.ParagraphBuilder();
    _text.build(builder);
    _paragraph = builder.build(_text.style?.paragraphStyle ?? new ui.ParagraphStyle());
    _needsLayout = true;
  }

  /// The minimum width at which to layout the text.
  double get minWidth => _paragraph.minWidth;
  void set minWidth(value) {
    if (_paragraph.minWidth == value)
      return;
    _paragraph.minWidth = value;
    _needsLayout = true;
  }

  /// The maximum width at which to layout the text.
  double get maxWidth => _paragraph.maxWidth;
  void set maxWidth(value) {
    if (_paragraph.maxWidth == value)
      return;
    _paragraph.maxWidth = value;
    _needsLayout = true;
  }

  /// The minimum height at which to layout the text.
  double get minHeight => _paragraph.minHeight;
  void set minHeight(value) {
    if (_paragraph.minHeight == value)
      return;
    _paragraph.minHeight = value;
    _needsLayout = true;
  }

  /// The maximum height at which to layout the text.
  double get maxHeight => _paragraph.maxHeight;
  void set maxHeight(value) {
    if (_paragraph.maxHeight == value)
      return;
    _paragraph.maxHeight = value;
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
  double get minIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicWidth);
  }

  /// The width at which increasing the width of the text no longer decreases the height.
  double get maxIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);
  }

  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.width);
  }

  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  Size get size {
    assert(!_needsLayout);
    return new Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the given type.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
  }

  /// Computes the visual position of the glyphs for painting the text.
  void layout() {
    if (!_needsLayout)
      return;
    _paragraph.layout();
    _needsLayout = false;
  }

  /// Paints the text onto the given canvas at the given offset.
  void paint(Canvas canvas, Offset offset) {
    assert(!_needsLayout && "Please call layout() before paint() to position the text before painting it." is String);
    _paragraph.paint(canvas, offset);
  }

  Offset _getOffsetFromUpstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset - 1, offset);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretEnd = box.end;
    double dx = box.direction == TextDirection.rtl ? caretEnd : caretEnd - caretPrototype.width;
    return new Offset(dx, 0.0);
  }

  Offset _getOffsetFromDownstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset, offset + 1);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretStart = box.start;
    double dx = box.direction == TextDirection.rtl ? caretStart - caretPrototype.width : caretStart;
    return new Offset(dx, 0.0);
  }

  /// Returns the offset at which to paint the caret.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    int offset = position.offset;
    // TODO(abarth): Handle the directionality of the text painter itself.
    const Offset emptyOffset = Offset.zero;
    switch (position.affinity) {
      case TextAffinity.upstream:
        return _getOffsetFromUpstream(offset, caretPrototype)
            ?? _getOffsetFromDownstream(offset, caretPrototype)
            ?? emptyOffset;
      case TextAffinity.downstream:
        return _getOffsetFromDownstream(offset, caretPrototype)
            ?? _getOffsetFromUpstream(offset, caretPrototype)
            ?? emptyOffset;
    }
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

  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph.getPositionForOffset(offset);
  }

}
