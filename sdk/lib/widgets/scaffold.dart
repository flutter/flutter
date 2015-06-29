// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../rendering/box.dart';
import '../rendering/object.dart';
import '../theme/view_configuration.dart';
import 'widget.dart';

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
      floatingActionButton.layout(new BoxConstraints.loose(area), parentUsesSize: true);
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = (area - floatingActionButton.size).toPoint();
    }
  }

  void paint(RenderCanvas canvas, Offset offset) {
    for (ScaffoldSlots slot in [ScaffoldSlots.body, ScaffoldSlots.statusBar, ScaffoldSlots.toolbar, ScaffoldSlots.floatingActionButton, ScaffoldSlots.drawer]) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        canvas.paintChild(box, box.parentData.position + offset);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    for (ScaffoldSlots slot in [ScaffoldSlots.drawer, ScaffoldSlots.floatingActionButton, ScaffoldSlots.toolbar, ScaffoldSlots.statusBar, ScaffoldSlots.body]) {
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

  // static final Style _style = new Style('''
  //   ${typography.typeface};
  //   ${typography.black.body1};''');

  Scaffold({
    String key,
    Widget toolbar,
    Widget body,
    Widget statusBar,
    Widget drawer,
    Widget floatingActionButton
  }) : _toolbar = toolbar,
       _body = body,
       _statusBar = statusBar,
       _drawer = drawer,
       _floatingActionButton = floatingActionButton,
       super(key: key);

  Widget _toolbar;
  Widget _body;
  Widget _statusBar;
  Widget _drawer;
  Widget _floatingActionButton;

  RenderScaffold get root => super.root;
  RenderScaffold createNode() => new RenderScaffold();

  void walkChildren(WidgetTreeWalker walker) {
    if (_toolbar != null)
      walker(_toolbar);
    if (_body != null)
      walker(_body);
    if (_statusBar != null)
      walker(_statusBar);
    if (_drawer != null)
      walker(_drawer);
    if (_floatingActionButton != null)
      walker(_floatingActionButton);
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
    _toolbar = syncChild(_toolbar, old is Scaffold ? old._toolbar : null, ScaffoldSlots.toolbar);
    _body = syncChild(_body, old is Scaffold ? old._body : null, ScaffoldSlots.body);
    _statusBar = syncChild(_statusBar, old is Scaffold ? old._statusBar : null, ScaffoldSlots.statusBar);
    _drawer = syncChild(_drawer, old is Scaffold ? old._drawer : null, ScaffoldSlots.drawer);
    _floatingActionButton = syncChild(_floatingActionButton, old is Scaffold ? old._floatingActionButton : null, ScaffoldSlots.floatingActionButton);
  }

}
