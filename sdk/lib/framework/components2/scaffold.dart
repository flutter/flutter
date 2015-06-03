// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import 'dart:sky' as sky;
import '../rendering/box.dart';
import '../rendering/node.dart';


enum ScaffoldSlots {
  Toolbar,
  Body,
  StatusBar,
  Drawer,
  FloatingActionButton
}

class RenderScaffold extends RenderBox {

  RenderScaffold({
    RenderBox toolbar,
    RenderBox body,
    RenderBox statusbar,
    RenderBox drawer,
    RenderBox floatingActionButton
  }) {
    this[ScaffoldSlots.Toolbar] = toolbar;
    this[ScaffoldSlots.Body] = body;
    this[ScaffoldSlots.StatusBar] = statusbar;
    this[ScaffoldSlots.Drawer] = drawer;
    this[ScaffoldSlots.FloatingActionButton] = floatingActionButton;
  }

  Map<ScaffoldSlots, RenderBox> _slots = new Map<ScaffoldSlots, RenderBox>();
  RenderBox operator[] (ScaffoldSlots slot) => _slots[slot];
  void operator[]= (ScaffoldSlots slot, RenderBox value) {
    RenderBox old = _slots[slot];
    if (old == value)
      return;
    if (old != null)
      dropChild(old);
    _slots[slot] = value;
    if (value != null)
      adoptChild(value);
    markNeedsLayout();
  }

  ScaffoldSlots remove(RenderBox child) {
    assert(child != null);
    for (ScaffoldSlots slot in ScaffoldSlots) {
      if (_slots[slot] == child) {
        this[slot] = null;
        return slot;
      }
    }
    return null;
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
    if (_slots[ScaffoldSlots.Toolbar] != null) {
      RenderBox toolbar = _slots[ScaffoldSlots.Toolbar];
      toolbar.layout(new BoxConstraints.tight(new sky.Size(size.width, kToolbarHeight)));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = new sky.Point(0.0, 0.0);
      bodyPosition = kToolbarHeight;
      bodyHeight -= kToolbarHeight;
    }
    if (_slots[ScaffoldSlots.StatusBar] != null) {
      RenderBox statusbar = _slots[ScaffoldSlots.StatusBar];
      statusbar.layout(new BoxConstraints.tight(new sky.Size(size.width, kStatusbarHeight)));
      assert(statusbar.parentData is BoxParentData);
      statusbar.parentData.position = new sky.Point(0.0, size.height - kStatusbarHeight);
      bodyHeight -= kStatusbarHeight;
    }
    if (_slots[ScaffoldSlots.Body] != null) {
      RenderBox body = _slots[ScaffoldSlots.Body];
      body.layout(new BoxConstraints.tight(new sky.Size(size.width, bodyHeight)));
      assert(body.parentData is BoxParentData);
      body.parentData.position = new sky.Point(0.0, bodyPosition);
    }
    if (_slots[ScaffoldSlots.Drawer] != null) {
      RenderBox drawer = _slots[ScaffoldSlots.Drawer];
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = new sky.Point(0.0, 0.0);
    }
    if (_slots[ScaffoldSlots.FloatingActionButton] != null) {
      RenderBox floatingActionButton = _slots[ScaffoldSlots.FloatingActionButton];
      floatingActionButton.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = new sky.Point(size.width - kButtonX, bodyPosition + bodyHeight - kButtonY);
    }
  }

  void paint(RenderNodeDisplayList canvas) {
    for (ScaffoldSlots slot in [ScaffoldSlots.Body, ScaffoldSlots.StatusBar, ScaffoldSlots.Toolbar, ScaffoldSlots.FloatingActionButton, ScaffoldSlots.Drawer]) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        canvas.paintChild(box, box.parentData.position);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { sky.Point position }) {
    for (ScaffoldSlots slot in [ScaffoldSlots.Drawer, ScaffoldSlots.FloatingActionButton, ScaffoldSlots.Toolbar, ScaffoldSlots.StatusBar, ScaffoldSlots.Body]) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        if (new sky.Rect.fromPointAndSize(box.parentData.position, box.size).contains(position)) {
          if (box.hitTest(result, position: (position - box.parentData.position).toPoint()))
            return;
        }
      }
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

  void insert(RenderNodeWrapper child, ScaffoldSlots slot) {
    root[slot] = child != null ? child.root : null;
  }

  void removeChild(UINode node) {
    assert(node != null);
    root.remove(node.root);
    super.removeChild(node);
  }

  void syncRenderNode(UINode old) {
    super.syncRenderNode(old);
    syncChild(toolbar, old is Scaffold ? old.toolbar : null, ScaffoldSlots.Toolbar);
    syncChild(body, old is Scaffold ? old.body : null, ScaffoldSlots.Body);
    syncChild(statusbar, old is Scaffold ? old.statusbar : null, ScaffoldSlots.StatusBar);
    syncChild(drawer, old is Scaffold ? old.drawer : null, ScaffoldSlots.Drawer);
    syncChild(floatingActionButton, old is Scaffold ? old.floatingActionButton : null, ScaffoldSlots.FloatingActionButton);
  }

}
