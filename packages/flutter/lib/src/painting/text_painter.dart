// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'basic_types.dart';
import 'text_editing.dart';
import 'text_style.dart';

/// An immutable span of text.
abstract class TextSpan {
  // This class must be immutable, because we won't notice when it changes.
  const TextSpan();
  void build(ui.ParagraphBuilder builder);
  ui.ParagraphStyle get paragraphStyle => null;
  String toPlainText(); // for semantics
  String toString([String prefix = '']); // for debugging
}

/// An immutable span of unstyled text.
class PlainTextSpan extends TextSpan {
  const PlainTextSpan(this.text);

  /// The text contained in the span.
  final String text;

  void build(ui.ParagraphBuilder builder) {
    assert(text != null);
    builder.addText(text);
  }

  bool operator ==(dynamic other) {
    if (other is! PlainTextSpan)
      return false;
    final PlainTextSpan typedOther = other;
    return text == typedOther.text;
  }

  int get hashCode => text.hashCode;

  String toPlainText() => text;
  String toString([String prefix = '']) => '$prefix$runtimeType: "$text"';
}

/// An immutable text span that applies a style to a list of children.
class StyledTextSpan extends TextSpan {
  const StyledTextSpan(this.style, this.children);

  /// The style to apply to the children.
  final TextStyle style;

  /// The children to which the style is applied.
  final List<TextSpan> children;

  void build(ui.ParagraphBuilder builder) {
    assert(style != null);
    assert(children != null);
    builder.pushStyle(style.textStyle);
    for (TextSpan child in children) {
      assert(child != null);
      child.build(builder);
    }
    builder.pop();
  }

  ui.ParagraphStyle get paragraphStyle => style.paragraphStyle;

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! StyledTextSpan)
      return false;
    final StyledTextSpan typedOther = other;
    if (style != typedOther.style ||
        children.length != typedOther.children.length)
      return false;
    for (int i = 0; i < children.length; ++i) {
      if (children[i] != typedOther.children[i])
        return false;
    }
    return true;
  }

  int get hashCode => hashValues(style, hashList(children));

  String toPlainText() => children.map((TextSpan child) => child.toPlainText()).join();

  String toString([String prefix = '']) {
    List<String> result = <String>[];
    result.add('$prefix$runtimeType:');
    var indent = '$prefix  ';
    result.add('${style.toString(indent)}');
    for (TextSpan child in children)
      result.add(child.toString(indent));
    return result.join('\n');
  }
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
    _paragraph = builder.build(_text.paragraphStyle ?? new ui.ParagraphStyle());
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
  void paint(ui.Canvas canvas, ui.Offset offset) {
    assert(!_needsLayout && "Please call layout() before paint() to position the text before painting it." is String);
    _paragraph.paint(canvas, offset);
  }

  Offset _getOffsetFromUpstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset - 1, offset);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretEnd = box.end;
    double dx = box.direction == ui.TextDirection.rtl ? caretEnd : caretEnd - caretPrototype.width;
    return new Offset(dx, 0.0);
  }

  Offset _getOffsetFromDownstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset, offset + 1);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretStart = box.start;
    double dx = box.direction == ui.TextDirection.rtl ? caretStart - caretPrototype.width : caretStart;
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
