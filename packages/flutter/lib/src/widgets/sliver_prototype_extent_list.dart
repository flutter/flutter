// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'sliver.dart';

/// A sliver that places its box children in a linear array and constrains them
/// to have the same extent as a prototype item along the main axis.
///
/// [SliverPrototypeExtentList] arranges its children in a line along
/// the main axis starting at offset zero and without gaps. Each child is
/// constrained to the same extent as the [prototypeItem] along the main axis
/// and the [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [SliverPrototypeExtentList] is more efficient than [SliverList] because
/// [SliverPrototypeExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. It's a little more flexible than
/// [SliverFixedExtentList] because there's no need to determine the appropriate
/// item extent in pixels.
///
/// See also:
///
///  * [SliverFixedExtentList], whose itemExtent is a pixel value.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
///  * [SliverList], which shows a list of variable-sized children in a
///    viewport.
class SliverPrototypeExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places its box children in a linear array and
  /// constrains them to have the same extent as a prototype item along
  /// the main axis.
  const SliverPrototypeExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.prototypeItem,
  }) : assert(prototypeItem != null),
       super(key: key, delegate: delegate);

  /// Defines the main axis extent of all of this sliver's children.
  ///
  /// The [prototypeItem] is laid out before the rest of the sliver's children
  /// and its size along the main axis fixes the size of each child. The
  /// [prototypeItem] is essentially [Offstage]: it is not painted and it
  /// cannot respond to input.
  final Widget prototypeItem;

  @override
  _RenderSliverPrototypeExtentList createRenderObject(BuildContext context) {
    final _SliverPrototypeExtentListElement element = context as _SliverPrototypeExtentListElement;
    return _RenderSliverPrototypeExtentList(childManager: element);
  }

  @override
  _SliverPrototypeExtentListElement createElement() => _SliverPrototypeExtentListElement(this);
}

class _SliverPrototypeExtentListElement extends SliverMultiBoxAdaptorElement {
  _SliverPrototypeExtentListElement(SliverPrototypeExtentList widget) : super(widget);

  @override
  SliverPrototypeExtentList get widget => super.widget as SliverPrototypeExtentList;

  @override
  _RenderSliverPrototypeExtentList get renderObject => super.renderObject as _RenderSliverPrototypeExtentList;

  Element _prototype;
  static final Object _prototypeSlot = Object();

  @override
  void insertRenderObjectChild(covariant RenderObject child, covariant dynamic slot) {
    if (slot == _prototypeSlot) {
      assert(child is RenderBox);
      renderObject.child = child as RenderBox;
    } else {
      super.insertRenderObjectChild(child, slot as int);
    }
  }

  @override
  void didAdoptChild(RenderBox child) {
    if (child != renderObject.child)
      super.didAdoptChild(child);
  }

  @override
  void moveRenderObjectChild(RenderBox child, dynamic oldSlot, dynamic newSlot) {
    if (newSlot == _prototypeSlot)
      assert(false); // There's only one prototype child so it cannot be moved.
    else
      super.moveRenderObjectChild(child, oldSlot as int, newSlot as int);
  }

  @override
  void removeRenderObjectChild(RenderBox child, dynamic slot) {
    if (renderObject.child == child)
      renderObject.child = null;
    else
      super.removeRenderObjectChild(child, slot as int);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_prototype != null)
      visitor(_prototype);
    super.visitChildren(visitor);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _prototype = updateChild(_prototype, widget.prototypeItem, _prototypeSlot);
  }

  @override
  void update(SliverPrototypeExtentList newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _prototype = updateChild(_prototype, widget.prototypeItem, _prototypeSlot);
  }
}

class _RenderSliverPrototypeExtentList extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverPrototypeExtentList({
    @required _SliverPrototypeExtentListElement childManager,
  }) : super(childManager: childManager);

  RenderBox _child;
  RenderBox get child => _child;
  set child(RenderBox value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    if (_child != null)
      adoptChild(_child);
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    super.performLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null)
      _child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_child != null)
      _child.detach();
  }

  @override
  void redepthChildren() {
    if (_child != null)
      redepthChild(_child);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null)
      visitor(_child);
    super.visitChildren(visitor);
  }

  @override
  double get itemExtent {
    assert(child != null && child.hasSize);
    return constraints.axis == Axis.vertical ? child.size.height : child.size.width;
  }
}
