// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../rendering/box.dart';
import '../rendering/object.dart';
import '../theme/view_configuration.dart';
import 'widget.dart';

// Slots are painted in this order and hit tested in reverse of this order
enum ScaffoldSlots {
  body,
  statusBar,
  toolbar,
  snackBar,
  floatingActionButton,
  drawer
}

class RenderScaffold extends RenderBox {

  RenderScaffold({
    RenderBox body,
    RenderBox statusBar,
    RenderBox toolbar,
    RenderBox snackBar,
    RenderBox floatingActionButton,
    RenderBox drawer
  }) {
    this[ScaffoldSlots.body] = body;
    this[ScaffoldSlots.statusBar] = statusBar;
    this[ScaffoldSlots.toolbar] = toolbar;
    this[ScaffoldSlots.snackBar] = snackBar;
    this[ScaffoldSlots.floatingActionButton] = floatingActionButton;
    this[ScaffoldSlots.drawer] = drawer;
  }

  Map<ScaffoldSlots, RenderBox> _slots = new Map<ScaffoldSlots, RenderBox>();
  RenderBox operator[] (ScaffoldSlots slot) => _slots[slot];
  void operator[]= (ScaffoldSlots slot, RenderBox value) {
    RenderBox old = _slots[slot];
    if (old == value)
      return;
    if (old != null)
      dropChild(old);
    if (value == null) {
      _slots.remove(slot);
    } else {
      _slots[slot] = value;
      adoptChild(value);
    }
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
    size = constraints.biggest;
    assert(!size.isInfinite);
  }

  // TODO(eseidel): These change based on device size!
  // http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
  static const kButtonX = 16.0; // left from right edge of body
  static const kButtonY = 16.0; // up from bottom edge of body

  void performLayout() {
    double bodyHeight = size.height;
    double bodyPosition = 0.0;
    if (_slots[ScaffoldSlots.statusBar] != null) {
      RenderBox statusBar = _slots[ScaffoldSlots.statusBar];
      statusBar.layout(new BoxConstraints.tight(new Size(size.width, kStatusBarHeight)));
      assert(statusBar.parentData is BoxParentData);
      statusBar.parentData.position = new Point(0.0, size.height - kStatusBarHeight);
      bodyHeight -= kStatusBarHeight;
    }
    if (_slots[ScaffoldSlots.toolbar] != null) {
      RenderBox toolbar = _slots[ScaffoldSlots.toolbar];
      double toolbarHeight = kToolBarHeight + sky.view.paddingTop;
      toolbar.layout(new BoxConstraints.tight(new Size(size.width, toolbarHeight)));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = Point.origin;
      bodyPosition += toolbarHeight;
      bodyHeight -= toolbarHeight;
    }
    if (_slots[ScaffoldSlots.body] != null) {
      RenderBox body = _slots[ScaffoldSlots.body];
      body.layout(new BoxConstraints.tight(new Size(size.width, bodyHeight)));
      assert(body.parentData is BoxParentData);
      body.parentData.position = new Point(0.0, bodyPosition);
    }
    double snackBarHeight = 0.0;
    if (_slots[ScaffoldSlots.snackBar] != null) {
      RenderBox snackBar = _slots[ScaffoldSlots.snackBar];
      // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
      snackBar.layout(new BoxConstraints(minWidth: size.width, maxWidth: size.width, minHeight: 0.0, maxHeight: size.height),
                      parentUsesSize: true);
      assert(snackBar.parentData is BoxParentData);
      snackBar.parentData.position = new Point(0.0, size.height - snackBar.size.height);
      snackBarHeight = snackBar.size.height;
    }
    if (_slots[ScaffoldSlots.floatingActionButton] != null) {
      RenderBox floatingActionButton = _slots[ScaffoldSlots.floatingActionButton];
      Size area = new Size(size.width - kButtonX, size.height - kButtonY - snackBarHeight);
      floatingActionButton.layout(new BoxConstraints.loose(area), parentUsesSize: true);
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = (area - floatingActionButton.size).toPoint();
    }
    if (_slots[ScaffoldSlots.drawer] != null) {
      RenderBox drawer = _slots[ScaffoldSlots.drawer];
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = Point.origin;
    }
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        canvas.paintChild(box, box.parentData.position + offset);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    for (ScaffoldSlots slot in ScaffoldSlots.values.reversed) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        if ((box.parentData.position & box.size).contains(position)) {
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

  Scaffold({
    String key,
    Widget body,
    Widget statusBar,
    Widget toolbar,
    Widget snackBar,
    Widget floatingActionButton,
    Widget drawer
  }) : super(key: key) {
    _slots[ScaffoldSlots.body] = body;
    _slots[ScaffoldSlots.statusBar] = statusBar;
    _slots[ScaffoldSlots.toolbar] = toolbar;
    _slots[ScaffoldSlots.snackBar] = snackBar;
    _slots[ScaffoldSlots.floatingActionButton] = floatingActionButton;
    _slots[ScaffoldSlots.drawer] = drawer;
  }

  Map<ScaffoldSlots, Widget> _slots = new Map<ScaffoldSlots, Widget>();

  RenderScaffold get root => super.root;
  RenderScaffold createNode() => new RenderScaffold();

  void walkChildren(WidgetTreeWalker walker) {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      Widget widget = _slots[slot];
      if (widget != null)
        walker(widget);
    }
  }

  void insertChildRoot(RenderObjectWrapper child, ScaffoldSlots slot) {
    root[slot] = child != null ? child.root : null;
  }

  void detachChildRoot(RenderObjectWrapper child) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is RenderScaffold);
    assert(root == child.root.parent);
    root.remove(child.root);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void remove() {
    walkChildren((Widget child) => removeChild(child));
    super.remove();
  }

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      Widget widget = _slots[slot];
      _slots[slot] = syncChild(widget, old is Scaffold ? old._slots[slot] : null, slot);
      assert((_slots[slot] == null) == (widget == null));
      assert(_slots[slot] == null || _slots[slot].parent == this);
    }
  }

}
