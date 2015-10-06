// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/src/widgets/framework.dart';

// Slots are painted in this order and hit tested in reverse of this order
enum _ScaffoldSlots {
  body,
  statusBar,
  toolbar,
  snackBar,
  floatingActionButton,
  drawer
}

class _RenderScaffold extends RenderBox {

  _RenderScaffold({
    RenderBox body,
    RenderBox statusBar,
    RenderBox toolbar,
    RenderBox snackBar,
    RenderBox floatingActionButton,
    RenderBox drawer
  }) {
    this[_ScaffoldSlots.body] = body;
    this[_ScaffoldSlots.statusBar] = statusBar;
    this[_ScaffoldSlots.toolbar] = toolbar;
    this[_ScaffoldSlots.snackBar] = snackBar;
    this[_ScaffoldSlots.floatingActionButton] = floatingActionButton;
    this[_ScaffoldSlots.drawer] = drawer;
  }

  Map<_ScaffoldSlots, RenderBox> _slots = new Map<_ScaffoldSlots, RenderBox>();
  RenderBox operator[] (_ScaffoldSlots slot) => _slots[slot];
  void operator[]= (_ScaffoldSlots slot, RenderBox value) {
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
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        box.attach();
    }
  }

  void detachChildren() {
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        box.detach();
    }
  }

  void visitChildren(RenderObjectVisitor visitor) {
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        visitor(box);
    }
  }

  _ScaffoldSlots remove(RenderBox child) {
    assert(child != null);
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
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
    double fabOffset = 0.0;
    if (_slots[_ScaffoldSlots.statusBar] != null) {
      RenderBox statusBar = _slots[_ScaffoldSlots.statusBar];
      statusBar.layout(new BoxConstraints.tight(new Size(size.width, kStatusBarHeight)));
      assert(statusBar.parentData is BoxParentData);
      statusBar.parentData.position = new Point(0.0, size.height - kStatusBarHeight);
      bodyHeight -= kStatusBarHeight;
    }
    if (_slots[_ScaffoldSlots.toolbar] != null) {
      RenderBox toolbar = _slots[_ScaffoldSlots.toolbar];
      double toolbarHeight = kToolBarHeight + sky.view.paddingTop;
      toolbar.layout(new BoxConstraints.tight(new Size(size.width, toolbarHeight)));
      assert(toolbar.parentData is BoxParentData);
      toolbar.parentData.position = Point.origin;
      bodyPosition += toolbarHeight;
      bodyHeight -= toolbarHeight;
    }
    if (_slots[_ScaffoldSlots.body] != null) {
      RenderBox body = _slots[_ScaffoldSlots.body];
      body.layout(new BoxConstraints.tight(new Size(size.width, bodyHeight)));
      assert(body.parentData is BoxParentData);
      body.parentData.position = new Point(0.0, bodyPosition);
    }
    if (_slots[_ScaffoldSlots.snackBar] != null) {
      RenderBox snackBar = _slots[_ScaffoldSlots.snackBar];
      // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
      snackBar.layout(
        new BoxConstraints(minWidth: size.width, maxWidth: size.width, minHeight: 0.0, maxHeight: bodyHeight),
        parentUsesSize: true
      );
      assert(snackBar.parentData is BoxParentData);
      snackBar.parentData.position = new Point(0.0, bodyPosition + bodyHeight - snackBar.size.height);
      fabOffset += snackBar.size.height;
    }
    if (_slots[_ScaffoldSlots.floatingActionButton] != null) {
      RenderBox floatingActionButton = _slots[_ScaffoldSlots.floatingActionButton];
      Size area = new Size(size.width - kButtonX, size.height - kButtonY);
      floatingActionButton.layout(new BoxConstraints.loose(area), parentUsesSize: true);
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = (area - floatingActionButton.size).toPoint() + new Offset(0.0, -fabOffset);
    }
    if (_slots[_ScaffoldSlots.drawer] != null) {
      RenderBox drawer = _slots[_ScaffoldSlots.drawer];
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = Point.origin;
    }
  }

  void paint(PaintingContext context, Offset offset) {
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        context.paintChild(box, box.parentData.position + offset);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    for (_ScaffoldSlots slot in _ScaffoldSlots.values.reversed) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        if (box.hitTest(result, position: (position - box.parentData.position).toPoint()))
          return;
      }
    }
  }

  String debugDescribeChildren(String prefix) {
    return _slots.keys.map((slot) => '${prefix}${slot}: ${_slots[slot].toStringDeep(prefix)}').join();
  }
}

class Scaffold extends RenderObjectWidget {
  Scaffold({
    Key key,
    Widget body,
    Widget statusBar,
    Widget toolbar,
    Widget snackBar,
    Widget floatingActionButton,
    Widget drawer
  }) : super(key: key) {
    _children[_ScaffoldSlots.body] = body;
    _children[_ScaffoldSlots.statusBar] = statusBar;
    _children[_ScaffoldSlots.toolbar] = toolbar;
    _children[_ScaffoldSlots.snackBar] = snackBar;
    _children[_ScaffoldSlots.floatingActionButton] = floatingActionButton;
    _children[_ScaffoldSlots.drawer] = drawer;
  }

  final Map<_ScaffoldSlots, Widget> _children = new Map<_ScaffoldSlots, Widget>();

  _RenderScaffold createRenderObject() => new _RenderScaffold();

  _ScaffoldElement createElement() => new _ScaffoldElement(this);
}

class _ScaffoldElement extends RenderObjectElement<Scaffold> {
  _ScaffoldElement(Scaffold widget) : super(widget);

  Map<_ScaffoldSlots, Element> _children;

  _RenderScaffold get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      Element element = _children[slot];
      if (element != null)
        visitor(element);
    }
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new Map<_ScaffoldSlots, Element>();
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      Element newChild = widget._children[slot]?.createElement();
      _children[slot] = newChild;
      newChild?.mount(this, slot);
    }
  }

  void update(Scaffold newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    for (_ScaffoldSlots slot in _ScaffoldSlots.values) {
      _children[slot] = updateChild(_children[slot], widget._children[slot], slot);
      assert((_children[slot] == null) == (widget._children[slot] == null));
    }
  }

  void insertChildRenderObject(RenderObject child, _ScaffoldSlots slot) {
    renderObject[slot] = child;
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    removeChildRenderObject(child);
    insertChildRenderObject(child, slot);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(renderObject == child.parent);
    renderObject.remove(child);
  }
}
