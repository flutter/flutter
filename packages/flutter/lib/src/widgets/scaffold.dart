// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/src/widgets/framework.dart';

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

  void visitChildren(RenderObjectVisitor visitor) {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null)
        visitor(box);
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
    double fabOffset = 0.0;
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
    if (_slots[ScaffoldSlots.snackBar] != null) {
      RenderBox snackBar = _slots[ScaffoldSlots.snackBar];
      // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
      snackBar.layout(
        new BoxConstraints(minWidth: size.width, maxWidth: size.width, minHeight: 0.0, maxHeight: bodyHeight),
        parentUsesSize: true
      );
      assert(snackBar.parentData is BoxParentData);
      snackBar.parentData.position = new Point(0.0, bodyPosition + bodyHeight - snackBar.size.height);
      fabOffset += snackBar.size.height;
    }
    if (_slots[ScaffoldSlots.floatingActionButton] != null) {
      RenderBox floatingActionButton = _slots[ScaffoldSlots.floatingActionButton];
      Size area = new Size(size.width - kButtonX, size.height - kButtonY);
      floatingActionButton.layout(new BoxConstraints.loose(area), parentUsesSize: true);
      assert(floatingActionButton.parentData is BoxParentData);
      floatingActionButton.parentData.position = (area - floatingActionButton.size).toPoint() + new Offset(0.0, -fabOffset);
    }
    if (_slots[ScaffoldSlots.drawer] != null) {
      RenderBox drawer = _slots[ScaffoldSlots.drawer];
      drawer.layout(new BoxConstraints(minWidth: 0.0, maxWidth: size.width, minHeight: size.height, maxHeight: size.height));
      assert(drawer.parentData is BoxParentData);
      drawer.parentData.position = Point.origin;
    }
  }

  void paint(PaintingContext context, Offset offset) {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      RenderBox box = _slots[slot];
      if (box != null) {
        assert(box.parentData is BoxParentData);
        context.paintChild(box, box.parentData.position + offset);
      }
    }
  }

  void hitTestChildren(HitTestResult result, { Point position }) {
    for (ScaffoldSlots slot in ScaffoldSlots.values.reversed) {
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
    _children[ScaffoldSlots.body] = body;
    _children[ScaffoldSlots.statusBar] = statusBar;
    _children[ScaffoldSlots.toolbar] = toolbar;
    _children[ScaffoldSlots.snackBar] = snackBar;
    _children[ScaffoldSlots.floatingActionButton] = floatingActionButton;
    _children[ScaffoldSlots.drawer] = drawer;
  }

  final Map<ScaffoldSlots, Widget> _children = new Map<ScaffoldSlots, Widget>();

  RenderScaffold createRenderObject() => new RenderScaffold();

  ScaffoldElement createElement() => new ScaffoldElement(this);
}

class ScaffoldElement extends RenderObjectElement<Scaffold> {
  ScaffoldElement(Scaffold widget) : super(widget);

  Map<ScaffoldSlots, Element> _children;

  RenderScaffold get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      Element element = _children[slot];
      if (element != null)
        visitor(element);
    }
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new Map<ScaffoldSlots, Element>();
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      Element newChild = widget._children[slot]?.createElement();
      _children[slot] = newChild;
      newChild?.mount(this, slot);
    }
  }

  void update(Scaffold newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    for (ScaffoldSlots slot in ScaffoldSlots.values) {
      _children[slot] = updateChild(_children[slot], widget._children[slot], slot);
      assert((_children[slot] == null) == (widget._children[slot] == null));
    }
  }

  void insertChildRenderObject(RenderObject child, ScaffoldSlots slot) {
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
