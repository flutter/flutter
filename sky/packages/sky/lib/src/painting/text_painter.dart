// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'basic_types.dart';
import 'text_style.dart';

/// An immutable span of text
abstract class TextSpan {
  // This class must be immutable, because we won't notice when it changes
  ui.Node _toDOM(ui.Document owner);
  String toString([String prefix = '']);

  void _applyStyleToContainer(ui.Element container) {
  }

  void build(ui.ParagraphBuilder builder);
  ui.ParagraphStyle get paragraphStyle => null;
}

/// An immutable span of unstyled text
class PlainTextSpan extends TextSpan {
  PlainTextSpan(this.text) {
    assert(text != null);
  }

  /// The text contained in the span
  final String text;

  ui.Node _toDOM(ui.Document owner) {
    return owner.createText(text);
  }

  void build(ui.ParagraphBuilder builder) {
    builder.addText(text);
  }

  bool operator ==(dynamic other) {
    if (other is! PlainTextSpan)
      return false;
    final PlainTextSpan typedOther = other;
    return text == typedOther.text;
  }

  int get hashCode => text.hashCode;

  String toString([String prefix = '']) => '$prefix$runtimeType: "$text"';
}

/// An immutable text span that applies a style to a list of children
class StyledTextSpan extends TextSpan {
  StyledTextSpan(this.style, this.children) {
    assert(style != null);
    assert(children != null);
  }

  /// The style to apply to the children
  final TextStyle style;

  /// The children to which the style is applied
  final List<TextSpan> children;

  ui.Node _toDOM(ui.Document owner) {
    ui.Element parent = owner.createElement('t');
    style.applyToCSSStyle(parent.style);
    for (TextSpan child in children) {
      parent.appendChild(child._toDOM(owner));
    }
    return parent;
  }

  void build(ui.ParagraphBuilder builder) {
    builder.pushStyle(style.textStyle);
    for (TextSpan child in children)
      child.build(builder);
    builder.pop();
  }

  ui.ParagraphStyle get paragraphStyle => style.paragraphStyle;

  void _applyStyleToContainer(ui.Element container) {
    style.applyToContainerCSSStyle(container.style);
  }

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

  int get hashCode {
    int value = 373;
    value = 37 * value + style.hashCode;
    for (TextSpan child in children)
      value = 37 * value + child.hashCode;
    return value;
  }

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

const bool _kEnableNewTextPainter = true;

abstract class TextPainter {

  factory TextPainter(TextSpan text) {
    if (_kEnableNewTextPainter)
      return new _NewTextPainter(text);
    return new _OldTextPainter(text);
  }

  /// The (potentially styled) text to paint
  TextSpan get text;
  void set text(TextSpan value);

  /// The minimum width at which to layout the text
  double get minWidth;
  void set minWidth(double value);

  /// The maximum width at which to layout the text
  double get maxWidth;
  void set maxWidth(double value);

  /// The minimum height at which to layout the text
  double get minHeight;
  void set minHeight(double value);

  /// The maximum height at which to layout the text
  double get maxHeight;
  void set maxHeight(double value);

  /// The width at which decreasing the width of the text would prevent it from
  /// painting itself completely within its bounds
  double get minContentWidth;

  /// The width at which increasing the width of the text no longer decreases
  /// the height
  double get maxContentWidth;

  /// The height required to paint the text completely within its bounds
  double get height;

  /// The distance from the top of the text to the first baseline of the given
  /// type
  double computeDistanceToActualBaseline(TextBaseline baseline);

  /// Compute the visual position of the glyphs for painting the text
  void layout();

  /// Paint the text onto the given canvas at the given offset
  void paint(ui.Canvas canvas, ui.Offset offset);

}

/// An object that paints a [TextSpan] into a canvas
class _OldTextPainter implements TextPainter {
  _OldTextPainter(TextSpan text) {
    _layoutRoot.rootElement = _document.createElement('p');
    assert(text != null);
    this.text = text;
  }

  ui.Paragraph _paragraph;

  final ui.Document _document = new ui.Document();
  final ui.LayoutRoot _layoutRoot = new ui.LayoutRoot();
  bool _needsLayout = true;

  TextSpan _text;
  /// The (potentially styled) text to paint
  TextSpan get text => _text;
  void set text(TextSpan value) {
    if (_text == value)
      return;
    _text = value;
    _layoutRoot.rootElement.setChild(_text._toDOM(_document));
    _layoutRoot.rootElement.removeAttribute('style');
    _text._applyStyleToContainer(_layoutRoot.rootElement);
    _needsLayout = true;
  }

  /// The minimum width at which to layout the text
  double get minWidth => _layoutRoot.minWidth;
  void set minWidth(value) {
    if (_layoutRoot.minWidth == value)
      return;
    _layoutRoot.minWidth = value;
    _needsLayout = true;
  }

  /// The maximum width at which to layout the text
  double get maxWidth => _layoutRoot.maxWidth;
  void set maxWidth(value) {
    if (_layoutRoot.maxWidth == value)
      return;
    _layoutRoot.maxWidth = value;
    _needsLayout = true;
  }

  /// The minimum height at which to layout the text
  double get minHeight => _layoutRoot.minHeight;
  void set minHeight(value) {
    if (_layoutRoot.minHeight == value)
      return;
    _layoutRoot.minHeight = value;
    _needsLayout = true;
  }

  /// The maximum height at which to layout the text
  double get maxHeight => _layoutRoot.maxHeight;
  void set maxHeight(value) {
    if (_layoutRoot.maxHeight == value)
      return;
    _layoutRoot.maxHeight = value;
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

  /// The width at which decreasing the width of the text would prevent it from painting itself completely within its bounds
  double get minContentWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_layoutRoot.rootElement.minContentWidth);
  }

  /// The width at which increasing the width of the text no longer decreases the height
  double get maxContentWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_layoutRoot.rootElement.maxContentWidth);
  }

  /// The height required to paint the text completely within its bounds
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_layoutRoot.rootElement.height);
  }

  /// The distance from the top of the text to the first baseline of the given type
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    ui.Element root = _layoutRoot.rootElement;
    switch (baseline) {
      case TextBaseline.alphabetic: return root.alphabeticBaseline;
      case TextBaseline.ideographic: return root.ideographicBaseline;
    }
  }

  /// Compute the visual position of the glyphs for painting the text
  void layout() {
    if (!_needsLayout)
      return;
    _layoutRoot.layout();
    _needsLayout = false;
  }

  /// Paint the text onto the given canvas at the given offset
  void paint(ui.Canvas canvas, ui.Offset offset) {
    assert(!_needsLayout && "Please call layout() before paint() to position the text before painting it." is String);
    // TODO(ianh): Make LayoutRoot support a paint offset so we don't
    // need to translate for each span of text.
    canvas.translate(offset.dx, offset.dy);
    _layoutRoot.paint(canvas);
    canvas.translate(-offset.dx, -offset.dy);
  }
}

class _NewTextPainter implements TextPainter {
  _NewTextPainter(TextSpan text) {
    this.text = text;
  }

  ui.Paragraph _paragraph;
  bool _needsLayout = true;

  TextSpan _text;
  /// The (potentially styled) text to paint
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

  /// The minimum width at which to layout the text
  double get minWidth => _paragraph.minWidth;
  void set minWidth(value) {
    if (_paragraph.minWidth == value)
      return;
    _paragraph.minWidth = value;
    _needsLayout = true;
  }

  /// The maximum width at which to layout the text
  double get maxWidth => _paragraph.maxWidth;
  void set maxWidth(value) {
    if (_paragraph.maxWidth == value)
      return;
    _paragraph.maxWidth = value;
    _needsLayout = true;
  }

  /// The minimum height at which to layout the text
  double get minHeight => _paragraph.minHeight;
  void set minHeight(value) {
    if (_paragraph.minHeight == value)
      return;
    _paragraph.minHeight = value;
    _needsLayout = true;
  }

  /// The maximum height at which to layout the text
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

  /// The width at which decreasing the width of the text would prevent it from painting itself completely within its bounds
  double get minContentWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicWidth);
  }

  /// The width at which increasing the width of the text no longer decreases the height
  double get maxContentWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);
  }

  /// The height required to paint the text completely within its bounds
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  /// The distance from the top of the text to the first baseline of the given type
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
  }

  /// Compute the visual position of the glyphs for painting the text
  void layout() {
    if (!_needsLayout)
      return;
    _paragraph.layout();
    _needsLayout = false;
  }

  /// Paint the text onto the given canvas at the given offset
  void paint(ui.Canvas canvas, ui.Offset offset) {
    assert(!_needsLayout && "Please call layout() before paint() to position the text before painting it." is String);
    _paragraph.paint(canvas, offset);
  }
}
