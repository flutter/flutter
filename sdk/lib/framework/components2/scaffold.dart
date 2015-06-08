// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/box.dart';
import '../rendering/object.dart';

enum ScaffoldSlots {
  toolbar,
  body,
  statusBar,
  drawer,
  floatingActionButton
}

class RenderScaffold extends RenderBox {

  RenderScaffold({
    RenderBox toolbar,
    RenderBox body,
    RenderBox statusbar,
    RenderBox drawer,
    RenderBox floatingActionButton
  }) {
    this[ScaffoldSlots.toolbar] = toolbar;
    this[ScaffoldSlots.body] = body;
    this[ScaffoldSlots.statusBar] = statusbar;
    this[ScaffoldSlots.drawer] = drawer;
    this[ScaffoldSlots.floatingActionButton] = floatingActionButton;
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

  void attachChildren() {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        box.attach();
    }
  }

  void detachChildren() {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        box.detach();
    }
  }

  ScaffoldSlots remove(RenderBox child) {
    assert(child != null);
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      if (_slots[slot] == child) {
        this[slot] = null;
        return slot;
      }
    }
    return null;
  }

  bool get sizedByParent => true;
  void performResize() {
    size = constraints.constrain(Size.infinite);
    assert(size.width < double.INFINITY);
    assert(size.height < double.INFINITY);
  }

  static const kToolbarHeight = 100.0;
  static const kStatusbarHeight = 50.0;
  static const kButtonX = 16.0; // left from right edge of body
  static const kButtonY = 16.0; // up from bottom edge of body

  void performLayout() {
    double bodyHeight = size.height;
    double bodyPosition = 0.0;
    if (_slots[ScaffoldSlots.toolbar] != null) {
      RenderBox toolbar = _slots[ScaffoldSlots.toolbar];
      toolbar.layout(new BoxConstraints.tight(new Size(size.width, kToolbarHeight)));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = Point.origin;
      bodyPosition = kToolbarHeight;
      bodyHeight -= kToolbarHeight;
    }
    if (_slots[ScaffoldSlots.statusBar] != null) {
      RenderBox statusbar = _slots[ScaffoldSlots.statusBar];
      statusbar.layout(new BoxConstraints.tight(new Size(size.width, kStatusbarHeight)));
      assert(statusbar.parentData is BoxParentData);
      statusbar.parentData.position = new Point(0.0, size.height - kStatusbarHeight);
      bodyHeight -= kStatusbarHeight;
    }
    if (_slots[ScaffoldSlots.body] != null) {
      RenderBox body = _slots[ScaffoldSlots.body];
      body.layout(new BoxConstraints.tight(new Size(size.width, bodyHeight)));
      assert(body.parentData is BoxParentData);
      body.parentData.position = new Point(0.0, bodyPosition);
    }
    if (_slots[ScaffoldSlots.drawer] != null) {
      RenderBox drawer = _slots[ScaffoldSlots.drawer];
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = Point.origin;
    }
    if (_slots[ScaffoldSlots.floatingActionButton] != null) {
      RenderBox floatingActionButton = _slots[ScaffoldSlots.floatingActionButton];
      Size area = new Size(size.width - kButtonX, size.height - kButtonY);
      floatingActionButton.layout(new BoxConstraints.loose(area));
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = (area - floatingActionButton.size).toPoint();
    }
  }

  void paint(RenderObjectDisplayList canvas) {
    for (ScaffoldSlots slot in [ScaffoldSlots.body, ScaffoldSlots.statusBar, ScaffoldSlots.toolbar, ScaffoldSlots.floatingActionButton, ScaffoldSlots.drawer]) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        canvas.paintChild(box, box.parentData.position);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    for (ScaffoldSlots slot in [ScaffoldSlots.drawer, ScaffoldSlots.floatingActionButton, ScaffoldSlots.toolbar, ScaffoldSlots.statusBar, ScaffoldSlots.body]) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        if (new Rect.fromPointAndSize(box.parentData.position, box.size).contains(position)) {
          if (box.hitTest(result, position: (position - box.parentData.position).toPoint()))
            return;
        }
      }
    }
  }

  String debugDescribeChildren(String prefix) {
    return _slots.keys.map((slot) => '${prefix}${slot}: ${_slots[slot].toString(prefix)}').join();
  }
}

class Scaffold extends RenderObjectWrapper {

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

  void insert(RenderObjectWrapper child, ScaffoldSlots slot) {
    root[slot] = child != null ? child.root : null;
  }

  void removeChild(UINode node) {
    assert(node != null);
    root.remove(node.root);
    super.removeChild(node);
  }

  void remove() {
    if (toolbar != null)
      removeChild(toolbar);
    if (body != null)
      removeChild(body);
    if (statusbar != null)
      removeChild(statusbar);
    if (drawer != null)
      removeChild(drawer);
    if (floatingActionButton != null)
      removeChild(floatingActionButton);
    super.remove();
  }

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    syncChild(toolbar, old is Scaffold ? old.toolbar : null, ScaffoldSlots.toolbar);
    syncChild(body, old is Scaffold ? old.body : null, ScaffoldSlots.body);
    syncChild(statusbar, old is Scaffold ? old.statusbar : null, ScaffoldSlots.statusBar);
    syncChild(drawer, old is Scaffold ? old.drawer : null, ScaffoldSlots.drawer);
    syncChild(floatingActionButton, old is Scaffold ? old.floatingActionButton : null, ScaffoldSlots.floatingActionButton);
  }

}
