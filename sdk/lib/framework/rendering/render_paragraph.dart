// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'render_box.dart';
import 'render_node.dart';

class RenderInline extends RenderNode {
  String data;

  RenderInline(this.data);
}

class RenderParagraph extends RenderBox {

  RenderParagraph({
    String text,
    int color
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

  int _color = 0xFF000000;
  int get color => _color;
  void set color (int value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  sky.Size getIntrinsicDimensions(BoxConstraints constraints) {
    assert(false);
    return null;
    // we don't currently support this for RenderParagraph
  }

  void performLayout() {
    _layoutRoot.maxWidth = constraints.maxWidth;
    _layoutRoot.minWidth = constraints.minWidth;
    _layoutRoot.minHeight = constraints.minHeight;
    _layoutRoot.maxHeight = constraints.maxHeight;
    _layoutRoot.layout();
    size = constraints.constrain(new sky.Size(_layoutRoot.rootElement.width, _layoutRoot.rootElement.height));
  }

  void paint(RenderNodeDisplayList canvas) {
    // _layoutRoot.rootElement.style['color'] = 'rgba(' + ...color... + ')';
    _layoutRoot.paint(canvas);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing
}
