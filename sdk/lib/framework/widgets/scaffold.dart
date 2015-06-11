// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../rendering/box.dart';
import '../rendering/object.dart';
import '../theme2/view_configuration.dart';
import 'ui_node.dart';

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
    RenderBox statusBar,
    RenderBox drawer,
    RenderBox floatingActionButton
  }) {
    this[ScaffoldSlots.toolbar] = toolbar;
    this[ScaffoldSlots.body] = body;
    this[ScaffoldSlots.statusBar] = statusBar;
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

  // TODO(eseidel): These change based on device size!
  // http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
  static const kButtonX = 16.0; // left from right edge of body
  static const kButtonY = 16.0; // up from bottom edge of body

  void performLayout() {
    double bodyHeight = size.height;
    double bodyPosition = 0.0;
    if (_slots[ScaffoldSlots.toolbar] != null) {
      RenderBox toolbar = _slots[ScaffoldSlots.toolbar];
      double toolbarHeight = kToolBarHeight + kNotificationAreaHeight;
      toolbar.layout(new BoxConstraints.tight(new Size(size.width, toolbarHeight)));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = Point.origin;
      bodyPosition += toolbarHeight;
      bodyHeight -= toolbarHeight;
    }
    if (_slots[ScaffoldSlots.statusBar] != null) {
      RenderBox statusBar = _slots[ScaffoldSlots.statusBar];
      statusBar.layout(new BoxConstraints.tight(new Size(size.width, kStatusBarHeight)));
      assert(statusBar.parentData is BoxParentData);
      statusBar.parentData.position = new Point(0.0, size.height - kStatusBarHeight);
      bodyHeight -= kStatusBarHeight;
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
    UINode toolbar,
    UINode body,
    UINode statusBar,
    UINode drawer,
    UINode floatingActionButton
  }) : _toolbar = toolbar,
       _body = body,
       _statusBar = statusBar,
       _drawer = drawer,
       _floatingActionButton = floatingActionButton,
       super(key: key);

  UINode _toolbar;
  UINode _body;
  UINode _statusBar;
  UINode _drawer;
  UINode _floatingActionButton;

  RenderScaffold get root { RenderScaffold result = super.root; return result; }
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
    if (_toolbar != null)
      removeChild(_toolbar);
    if (_body != null)
      removeChild(_body);
    if (_statusBar != null)
      removeChild(_statusBar);
    if (_drawer != null)
      removeChild(_drawer);
    if (_floatingActionButton != null)
      removeChild(_floatingActionButton);
    super.remove();
  }

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    _toolbar = syncChild(_toolbar, old is Scaffold ? old._toolbar : null, ScaffoldSlots.toolbar);
    _body = syncChild(_body, old is Scaffold ? old._body : null, ScaffoldSlots.body);
    _statusBar = syncChild(_statusBar, old is Scaffold ? old._statusBar : null, ScaffoldSlots.statusBar);
    _drawer = syncChild(_drawer, old is Scaffold ? old._drawer : null, ScaffoldSlots.drawer);
    _floatingActionButton = syncChild(_floatingActionButton, old is Scaffold ? old._floatingActionButton : null, ScaffoldSlots.floatingActionButton);
  }

}
