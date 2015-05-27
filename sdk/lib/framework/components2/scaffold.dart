// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../layout2.dart';
import '../theme/typography.dart' as typography;

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

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    width = constraints.constrainWidth(double.INFINITY);
    assert(width < double.INFINITY);
    height = constraints.constrainHeight(double.INFINITY);
    assert(height < double.INFINITY);
    relayout();
  }

  static const kToolbarHeight = 100.0;
  static const kStatusbarHeight = 50.0;
  static const kButtonX = -16.0; // from right edge of body
  static const kButtonY = -16.0; // from bottom edge of body

  void relayout() {
    double bodyHeight = height;
    double bodyPosition = 0.0;
    if (toolbar != null) {
    print("laying out toolbar...");
      toolbar.layout(new BoxConstraints.tight(width: width, height: kToolbarHeight));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.x = 0.0;
      toolbar.parentData.y = 0.0;
    print("...at ${toolbar.parentData.x},${toolbar.parentData.y} dim ${toolbar.width}x${toolbar.height}");
      bodyPosition = kToolbarHeight;
      bodyHeight -= kToolbarHeight;
    }
    if (statusbar != null) {
      statusbar.layout(new BoxConstraints.tight(width: width, height: kStatusbarHeight));
      assert(statusbar.parentData is BoxParentData);
      statusbar.parentData.x = 0.0;
      statusbar.parentData.y = height - kStatusbarHeight;
      bodyHeight -= kStatusbarHeight;
    }
    if (body != null) {
      body.layout(new BoxConstraints.tight(width: width, height: bodyHeight));
      assert(body.parentData is BoxParentData);
      body.parentData.x = 0.0;
      body.parentData.y = bodyPosition;
    }
    if (drawer != null) {
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: width, minHeight: height, maxHeight: height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.x = 0.0;
      drawer.parentData.y = 0.0;
    }
    if (floatingActionButton != null) {
      floatingActionButton.layout(new BoxConstraints(minWidth: 0.0, maxWidth: width, minHeight: height, maxHeight: height));
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.x = width - xButtonX;
      floatingActionButton.parentData.y = bodyPosition + bodyHeight - kButtonY;
    }
    layoutDone();
  }

  void paint(RenderNodeDisplayList canvas) {
    if (body != null)
      canvas.paintChild(body, (body.parentData as BoxParentData).x, (body.parentData as BoxParentData).y);
    if (statusbar != null)
      canvas.paintChild(statusbar, (statusbar.parentData as BoxParentData).x, (statusbar.parentData as BoxParentData).y);
    if (toolbar != null)
      canvas.paintChild(toolbar, (toolbar.parentData as BoxParentData).x, (toolbar.parentData as BoxParentData).y);
    if (floatingActionButton != null)
      canvas.paintChild(floatingActionButton, (floatingActionButton.parentData as BoxParentData).x, (floatingActionButton.parentData as BoxParentData).y);
    if (drawer != null)
      canvas.paintChild(drawer, (drawer.parentData as BoxParentData).x, (drawer.parentData as BoxParentData).y);
  }

  void hitTestChildren(HitTestResult result, { double x, double y }) {
    assert(floatingActionButton == null || floatingActionButton.parentData is BoxParentData);
    assert(statusBar == null || statusBar.parentData is BoxParentData);
    if ((drawer != null) && (x < drawer.width)) {
      drawer.hitTest(result, x: x, y: y);
    } else if ((floatingActionButton != null) && (x >= floatingActionButton.parentData.x) && (x < floatingActionButton.parentData.x + floatingActionButton.width)
                                              && (y >= floatingActionButton.parentData.y) && (y < floatingActionButton.parentData.y + floatingActionButton.height)) {
      floatingActionButton.hitTest(result, x: x-floatingActionButton.parentData.x, y: y-floatingActionButton.parentData.y);
    } else if ((toolbar != null) && (y < toolbar.height)) {
      toolbar.hitTest(result, x: x, y: y);
    } else if ((statusbar != null) && (y > statusbar.parentData.y)) {
      statusbar.hitTest(result, x: x, y: y-statusbar.parentData.y);
    } else {
      body.hitTest(result, x: x, y: y-body.parentData.y);
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
