// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../layout2.dart';
import '../theme/typography.dart' as typography;
import 'dart:sky' as sky;

// RenderNode
class RenderScaffold extends RenderDecoratedBox {

  RenderScaffold({
    BoxDecoration decoration,
    RenderBox toolbar,
    RenderBox body,
    RenderBox statusbar,
    RenderBox drawer,
    RenderBox floatingActionButton
  }) : super(decoration) {
    this.toolbar = toolbar;
    this.body = body;
    this.statusbar = statusbar;
    this.drawer = drawer;
    this.floatingActionButton = floatingActionButton;
  }

  RenderBox _toolbar;
  RenderBox get toolbar => _toolbar;
  void set toolbar (RenderBox value) {
    if (_toolbar != null)
      dropChild(_toolbar);
    _toolbar = value;
    if (_toolbar != null)
      adoptChild(_toolbar);
    markNeedsLayout();
  }

  RenderBox _body;
  RenderBox get body => _body;
  void set body (RenderBox value) {
    if (_body != null)
      dropChild(_body);
    _body = value;
    if (_body != null)
      adoptChild(_body);
    markNeedsLayout();
  }

  RenderBox _statusbar;
  RenderBox get statusbar => _statusbar;
  void set statusbar (RenderBox value) {
    if (_statusbar != null)
      dropChild(_statusbar);
    _statusbar = value;
    if (_statusbar != null)
      adoptChild(_statusbar);
    markNeedsLayout();
  }

  RenderBox _drawer;
  RenderBox get drawer => _drawer;
  void set drawer (RenderBox value) {
    if (_drawer != null)
      dropChild(_drawer);
    _drawer = value;
    if (_drawer != null)
      adoptChild(_drawer);
    markNeedsLayout();
  }

  RenderBox _floatingActionButton;
  RenderBox get floatingActionButton => _floatingActionButton;
  void set floatingActionButton (RenderBox value) {
    if (_floatingActionButton != null)
      dropChild(_floatingActionButton);
    _floatingActionButton = value;
    if (_floatingActionButton != null)
      adoptChild(_floatingActionButton);
    markNeedsLayout();
  }

  bool get sizedByParent => true;
  void performResize() {
    size = constraints.constrain(new sky.Size.infinite());
    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
  }

  static const kToolbarHeight = 100.0;
  static const kStatusbarHeight = 50.0;
  static const kButtonX = -16.0; // from right edge of body
  static const kButtonY = -16.0; // from bottom edge of body

  void performLayout() {
    double bodyHeight = size.height;
    double bodyPosition = 0.0;
    if (toolbar != null) {
      toolbar.layout(new BoxConstraints.tight(width: size.width, height: kToolbarHeight));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = new sky.Point(0.0, 0.0);
      bodyPosition = kToolbarHeight;
      bodyHeight -= kToolbarHeight;
    }
    if (statusbar != null) {
      statusbar.layout(new BoxConstraints.tight(width: size.width, height: kStatusbarHeight));
      assert(statusbar.parentData is BoxParentData);
      statusbar.parentData.position = new sky.Point(0.0, size.height - kStatusbarHeight);
      bodyHeight -= kStatusbarHeight;
    }
    if (body != null) {
      body.layout(new BoxConstraints.tight(width: size.width, height: bodyHeight));
      assert(body.parentData is BoxParentData);
      body.parentData.position = new sky.Point(0.0, bodyPosition);
    }
    if (drawer != null) {
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = new sky.Point(0.0, 0.0);
    }
    if (floatingActionButton != null) {
      floatingActionButton.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = new sky.Point(size.width - xButtonX, bodyPosition + bodyHeight - kButtonY);
    }
  }

  void paint(RenderNodeDisplayList canvas) {
    if (body != null)
      canvas.paintChild(body, (body.parentData as BoxParentData).position);
    if (statusbar != null)
      canvas.paintChild(statusbar, (statusbar.parentData as BoxParentData).position);
    if (toolbar != null)
      canvas.paintChild(toolbar, (toolbar.parentData as BoxParentData).position);
    if (floatingActionButton != null)
      canvas.paintChild(floatingActionButton, (floatingActionButton.parentData as BoxParentData).position);
    if (drawer != null)
      canvas.paintChild(drawer, (drawer.parentData as BoxParentData).position);
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    assert(floatingActionButton == null || floatingActionButton.parentData is BoxParentData);
    assert(statusbar == null || statusbar.parentData is BoxParentData);
    if ((drawer != null) && (x < drawer.size.width)) {
      drawer.hitTest(result, position: position);
    } else if ((floatingActionButton != null) && (position.x >= floatingActionButton.parentData.position.x) && (position.x < floatingActionButton.parentData.position.x + floatingActionButton.size.width)
                                              && (position.y >= floatingActionButton.parentData.position.y) && (position.y < floatingActionButton.parentData.position.y + floatingActionButton.size.height)) {
      floatingActionButton.hitTest(result, position: new sky.Point(position.x - floatingActionButton.parentData.position.x, position.y - floatingActionButton.parentData.position.y));
    } else if ((toolbar != null) && (position.y < toolbar.size.height)) {
      toolbar.hitTest(result, position: position);
    } else if ((statusbar != null) && (position.y > statusbar.parentData.position.y)) {
      statusbar.hitTest(result, position: new sky.Point(position.x, position.y - statusbar.parentData.position.y));
    } else if (body != null) {
      body.hitTest(result, position: new sky.Point(position.x, position.y - body.parentData.position.y));
    }
  }

}

class Scaffold extends RenderNodeWrapper {

  // static final Style _style = new Style('''
  //   ${typography.typeface};
  //   ${typography.black.body1};''');

  Scaffold({
    Object key,
    this.toolbar,
    this.body,
    this.statusbar,
    this.drawer,
    this.floatingActionButton
  }) : super(
    key: key
  );

  final UINode toolbar;
  final UINode body;
  final UINode statusbar;
  final UINode drawer;
  final UINode floatingActionButton;

  RenderScaffold root;
  RenderScaffold createNode() => new RenderScaffold();

  static final Scaffold _emptyScaffold = new Scaffold();
  RenderNodeWrapper get emptyNode => _emptyScaffold;

  void insert(RenderNodeWrapper child, dynamic slot) {
    switch (slot) {
      case #toolbar: root.toolbar = toolbar == null ? null : toolbar.root; break;
      case #body: root.body = body == null ? null : body.root; break;
      case #statusbar: root.statusbar = statusbar == null ? null : statusbar.root; break;
      case #drawer: root.drawer = drawer == null ? null : drawer.root; break;
      case #floatingActionButton: root.floatingActionButton = floatingActionButton == null ? null : floatingActionButton.root; break;
      default: assert(false);
    }
  }

  void removeChild(UINode node) {
    if (node == root.toolbar)
      root.toolbar = null;
    if (node == root.body)
      root.body = null;
    if (node == root.statusbar)
      root.statusbar = null;
    if (node == root.drawer)
      root.drawer = null;
    if (node == root.floatingActionButton)
      root.floatingActionButton = null;
    super.removeChild(node);
  }

  void syncRenderNode(UINode old) {
    super.syncRenderNode(old);
    syncChild(toolbar, old is Scaffold ? old.toolbar : null, #toolbar);
    syncChild(body, old is Scaffold ? old.body : null, #body);
    syncChild(statusbar, old is Scaffold ? old.statusbar : null, #statusbar);
    syncChild(drawer, old is Scaffold ? old.drawer : null, #drawer);
    syncChild(floatingActionButton, old is Scaffold ? old.floatingActionButton : null, #floatingActionButton);
  }

}
