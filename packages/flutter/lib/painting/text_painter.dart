// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/text_style.dart';

export 'package:sky/painting/text_style.dart';

/// An immutable span of text
abstract class TextSpan {
  // This class must be immutable, because we won't notice when it changes
  sky.Node _toDOM(sky.Document owner);
  String toString([String prefix = '']);

  void _applyStyleToContainer(sky.Element container) {
  }
}

/// An immutable span of unstyled text
class PlainTextSpan extends TextSpan {
  PlainTextSpan(this.text) {
    assert(text != null);
  }

  /// The text contained in the span
  final String text;

  sky.Node _toDOM(sky.Document owner) {
    return owner.createText(text);
  }

  bool operator ==(other) => other is PlainTextSpan && text == other.text;
  int get hashCode => text.hashCode;

  String toString([String prefix = '']) => '${prefix}${runtimeType}: "${text}"';
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

  sky.Node _toDOM(sky.Document owner) {
    sky.Element parent = owner.createElement('t');
    style.applyToCSSStyle(parent.style);
    for (TextSpan child in children) {
      parent.appendChild(child._toDOM(owner));
    }
    return parent;
  }

  void _applyStyleToContainer(sky.Element container) {
    style.applyToContainerCSSStyle(container.style);
  }

  bool operator ==(other) {
    if (identical(this, other))
      return true;
    if (other is! StyledTextSpan
        || style != other.style
        || children.length != other.children.length)
      return false;
    for (int i = 0; i < children.length; ++i) {
      if (children[i] != other.children[i])
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
    List<String> result = [];
    result.add('${prefix}${runtimeType}:');
    var indent = '${prefix}  ';
    result.add('${style.toString(indent)}');
    for (TextSpan child in children) {
      result.add(child.toString(indent));
    }
    return result.join('\n');
  }
}

/// An object that paints a [TextSpan] into a canvas
class TextPainter {
  TextPainter(TextSpan text) {
    _layoutRoot.rootElement = _document.createElement('p');
    assert(text != null);
    this.text = text;
  }

  final sky.Document _document = new sky.Document();
  final sky.LayoutRoot _layoutRoot = new sky.LayoutRoot();
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

  /// The width at which decreasing the width of the text would prevent it from painting itself completely within its bounds
  double get minContentWidth {
    assert(!_needsLayout);
    return _layoutRoot.rootElement.minContentWidth;
  }

  /// The width at which increasing the width of the text no longer decreases the height
  double get maxContentWidth {
    assert(!_needsLayout);
    return _layoutRoot.rootElement.maxContentWidth;
  }

  /// The height required to paint the text completely within its bounds
  double get height {
    assert(!_needsLayout);
    return _layoutRoot.rootElement.height;
  }

  /// The distance from the top of the text to the first baseline of the given type
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    sky.Element root = _layoutRoot.rootElement;
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
  void paint(sky.Canvas canvas, sky.Offset offset) {
    assert(!_needsLayout && "Please call layout() before paint() to position the text before painting it." is String);
    // TODO(ianh): Make LayoutRoot support a paint offset so we don't
    // need to translate for each span of text.
    canvas.translate(offset.dx, offset.dy);
    _layoutRoot.paint(canvas);
    canvas.translate(-offset.dx, -offset.dy);
  }
}
