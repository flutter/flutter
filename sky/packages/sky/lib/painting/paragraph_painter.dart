// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/text_style.dart';

export 'package:sky/painting/text_style.dart';

// This must be immutable, because we won't notice when it changes
abstract class TextSpan {
  sky.Node _toDOM(sky.Document owner);
  String toString([String prefix = '']);

  void _applyStyleToContainer(sky.Element container) {
  }
}

class PlainTextSpan extends TextSpan {
  PlainTextSpan(this.text) {
    assert(text != null);
  }

  final String text;

  sky.Node _toDOM(sky.Document owner) {
    return owner.createText(text);
  }

  bool operator ==(other) => other is PlainTextSpan && text == other.text;
  int get hashCode => text.hashCode;

  String toString([String prefix = '']) => '${prefix}${runtimeType}: "${text}"';
}

class StyledTextSpan extends TextSpan {
  StyledTextSpan(this.style, this.children) {
    assert(style != null);
    assert(children != null);
  }

  final TextStyle style;
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

class ParagraphPainter {
  ParagraphPainter(TextSpan text) {
    _layoutRoot.rootElement = _document.createElement('p');
    assert(text != null);
    this.text = text;
  }

  final sky.Document _document = new sky.Document();
  final sky.LayoutRoot _layoutRoot = new sky.LayoutRoot();

  TextSpan _text;
  TextSpan get text => _text;
  void set text(TextSpan value) {
    _text = value;
    _layoutRoot.rootElement.setChild(_text._toDOM(_document));
    _layoutRoot.rootElement.removeAttribute('style');
    _text._applyStyleToContainer(_layoutRoot.rootElement);
  }

  double get minWidth => _layoutRoot.minWidth;
  void set minWidth(value) {
    _layoutRoot.minWidth = value;
  }

  double get maxWidth => _layoutRoot.maxWidth;
  void set maxWidth(value) {
    _layoutRoot.maxWidth = value;
  }

  double get minHeight => _layoutRoot.minHeight;
  void set minHeight(value) {
    _layoutRoot.minHeight = value;
  }

  double get maxHeight => _layoutRoot.maxHeight;
  void set maxHeight(value) {
    _layoutRoot.maxHeight = value;
  }

  double get minContentWidth => _layoutRoot.rootElement.minContentWidth;
  double get maxContentWidth => _layoutRoot.rootElement.maxContentWidth;
  double get height => _layoutRoot.rootElement.height;
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    sky.Element root = _layoutRoot.rootElement;
    switch (baseline) {
      case TextBaseline.alphabetic: return root.alphabeticBaseline;
      case TextBaseline.ideographic: return root.ideographicBaseline;
    }
  }

  void layout() => _layoutRoot.layout();

  void paint(sky.Canvas canvas, sky.Offset offset) {
    // TODO(ianh): Make LayoutRoot support a paint offset so we don't
    // need to translate for each span of text.
    canvas.translate(offset.dx, offset.dy);
    _layoutRoot.paint(canvas);
    canvas.translate(-offset.dx, -offset.dy);
  }
}
