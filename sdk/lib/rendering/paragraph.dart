// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'box.dart';
import 'object.dart';

enum FontWeight {
  light, // 300
  regular, // 400
  medium, // 500
}

enum TextAlign {
  left,
  right,
  center
}

class TextStyle {
  const TextStyle({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign
  });

  final Color color;
  final double fontSize; // in pixels
  final FontWeight fontWeight;
  final TextAlign textAlign;

  TextStyle copyWith({
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign textAlign
  }) {
    return new TextStyle(
      color: color != null ? color : this.color,
      fontSize: fontSize != null ? fontSize : this.fontSize,
      fontWeight: fontWeight != null ? fontWeight : this.fontWeight,
      textAlign: textAlign != null ? textAlign : this.textAlign
    );
  }

  bool operator ==(other) {
    return other is TextStyle &&
      color == other.color &&
      fontSize == other.fontSize &&
      fontWeight == other.fontWeight &&
      textAlign == other.textAlign;
  }

  int get hashCode {
    // Use Quiver: https://github.com/domokit/mojo/issues/236
    int value = 373;
    value = 37 * value + color.hashCode;
    value = 37 * value + fontSize.hashCode;
    value = 37 * value + fontWeight.hashCode;
    value = 37 * value + textAlign.hashCode;
    return value;
  }

  void _applyToCSSStyle(sky.CSSStyleDeclaration cssStyle) {
    if (color != null) {
      cssStyle['color'] = 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.alpha / 255.0})';
    }
    if (fontSize != null) {
      cssStyle['font-size'] = "${fontSize}px";
    }
    if (fontWeight != null) {
      cssStyle['font-weight'] = const {
        FontWeight.light: '300',
        FontWeight.regular: '400',
        FontWeight.medium: '500',
      }[fontWeight];
    }
    if (textAlign != null) {
      cssStyle['text-align'] = const {
        TextAlign.left: 'left',
        TextAlign.right: 'right',
        TextAlign.center: 'center',
      }[textAlign];
    }
  }

  String toString([String prefix = '']) {
    List<String> result = [];
    if (color != null)
      result.add('${prefix}color: $color');
    if (fontSize != null)
      result.add('${prefix}fontSize: $fontSize');
    if (fontWeight != null)
      result.add('${prefix}fontWeight: $fontWeight');
    if (textAlign != null)
      result.add('${prefix}textAlign: $textAlign');
    if (result.isEmpty)
      return '${prefix}<no style specified>';
    return result.join('\n');
  }
}

class InlineBase {
  sky.Node _toDOM(sky.Document owner);
  String toString([String prefix = '']);
}

class InlineText extends InlineBase {
  InlineText(this.text) {
    assert(text != null);
  }

  final String text;

  sky.Node _toDOM(sky.Document owner) {
    return owner.createText(text);
  }

  String toString([String prefix = '']) => '${prefix}InlineText: "${text}"';
}

class InlineStyle extends InlineBase {
  InlineStyle(this.style, this.children) {
    assert(style != null && children != null);
  }

  final TextStyle style;
  final List<InlineBase> children;

  sky.Node _toDOM(sky.Document owner) {
    sky.Element parent = owner.createElement('t');
    style._applyToCSSStyle(parent.style);
    for (InlineBase child in children) {
      parent.appendChild(child._toDOM(owner));
    }
    return parent;
  }

  String toString([String prefix = '']) {
    List<String> result = [];
    result.add('${prefix}InlineStyle:');
    var indent = '${prefix}  ';
    result.add('${style.toString(indent)}');
    for (InlineBase child in children) {
      result.add(child.toString(indent));
    }
    return result.join('\n');
  }
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

class RenderParagraph extends RenderBox {

  RenderParagraph(InlineBase inlineValue) {
    _layoutRoot.rootElement = _document.createElement('p');
    inline = inlineValue;
  }

  final sky.Document _document = new sky.Document();
  final sky.LayoutRoot _layoutRoot = new sky.LayoutRoot();

  InlineBase _inline;
  BoxConstraints _constraintsForCurrentLayout;

  String get inline => _inline;
  void set inline (InlineBase value) {
    _inline = value;
    _layoutRoot.rootElement.setChild(_inline._toDOM(_document));
    markNeedsLayout();
  }

  sky.Element _layout(BoxConstraints constraints) {
    _layoutRoot.maxWidth = constraints.maxWidth;
    _layoutRoot.minWidth = constraints.minWidth;
    _layoutRoot.minHeight = constraints.minHeight;
    _layoutRoot.maxHeight = constraints.maxHeight;
    _layoutRoot.layout();
    _constraintsForCurrentLayout = constraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_layoutRoot.rootElement.minContentWidth));
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_layoutRoot.rootElement.maxContentWidth));
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainHeight(
        _applyFloatingPointHack(_layoutRoot.rootElement.height));
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  void performLayout() {
    _layout(constraints);
    sky.Element root = _layoutRoot.rootElement;
    // rootElement.width always expands to fill, use maxContentWidth instead.
    size = constraints.constrain(new Size(_applyFloatingPointHack(root.maxContentWidth),
                                          _applyFloatingPointHack(root.height)));
  }

  void paint(RenderObjectDisplayList canvas) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the layout root. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height a
    //               non-destructive operation.
    if (_constraintsForCurrentLayout != constraints && constraints != null)
      _layout(constraints);

    _layoutRoot.paint(canvas);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing

  String debugDescribeSettings(String prefix) {
    String result = '${super.debugDescribeSettings(prefix)}';
    result += '${prefix}inline: ${inline}\n';
    return result;
  }
}
