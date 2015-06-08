// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'box.dart';
import 'object.dart';

class RenderInline extends RenderObject {
  String data;

  RenderInline(this.data);
}

class RenderParagraph extends RenderBox {

  RenderParagraph({
    String text,
    Color color
  }) : _color = color {
    _layoutRoot.rootElement = _document.createElement('p');
    this.text = text;
  }

  final sky.Document _document = new sky.Document();
  final sky.LayoutRoot _layoutRoot = new sky.LayoutRoot();

  String get text => (_layoutRoot.rootElement.firstChild as sky.Text).data;
  void set text (String value) {
    _layoutRoot.rootElement.setChild(_document.createText(value));
    markNeedsLayout();
  }

  Color _color = const Color(0xFF000000);
  Color get color => _color;
  void set color (Color value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  // We don't currently support this for RenderParagraph
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainWidth(0.0);
  }

  // We don't currently support this for RenderParagraph
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainWidth(0.0);
  }

  // We don't currently support this for RenderParagraph
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainHeight(0.0);
  }

  // We don't currently support this for RenderParagraph
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(false);
    return constraints.constrainHeight(0.0);
  }

  void performLayout() {
    _layoutRoot.maxWidth = constraints.maxWidth;
    _layoutRoot.minWidth = constraints.minWidth;
    _layoutRoot.minHeight = constraints.minHeight;
    _layoutRoot.maxHeight = constraints.maxHeight;
    _layoutRoot.layout();
    // rootElement.width always expands to fill, use maxContentWidth instead.
    sky.Element root = _layoutRoot.rootElement;
    size = constraints.constrain(new Size(root.maxContentWidth, root.height));
  }

  void paint(RenderObjectDisplayList canvas) {
    if (_color != null)
      _layoutRoot.rootElement.style['color'] =
          'rgba(${_color.red}, ${_color.green}, ${_color.blue}, ${_color.alpha / 255.0 })';
    _layoutRoot.paint(canvas);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}color: ${color}\n${prefix}text: ${text}\n';
}
