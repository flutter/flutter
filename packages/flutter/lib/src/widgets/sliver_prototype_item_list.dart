// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'sliver.dart';

export 'package:flutter/rendering.dart' show RenderSliverFixedExtentBoxAdaptor;

class SliverPrototypeExtentListElement extends SliverMultiBoxAdaptorElement {
  SliverPrototypeExtentListElement(SliverPrototypeExtentList widget) : super(widget);

  @override
  SliverPrototypeExtentList get widget => super.widget;

  @override
  RenderSliverPrototypeExtentList get renderObject => super.renderObject;

  Element _prototype;
  static final Object _prototypeSlot = new Object();

  @override
  void insertChildRenderObject(covariant RenderObject child, covariant dynamic slot) {
    if (slot == _prototypeSlot) {
      assert(child is RenderBox);
      renderObject.child = child;
    } else {
      super.insertChildRenderObject(child, slot);
    }
  }

  @override
  void didAdoptChild(RenderBox child) {
    if (child != renderObject.child)
      super.didAdoptChild(child);
  }

  @override
  void moveChildRenderObject(RenderBox child, dynamic slot) {
    if (slot == _prototypeSlot) {
      renderObject.remove(child);
      assert(child is RenderBox);
      renderObject.child = child;
    } else {
      super.moveChildRenderObject(child, slot);
    }
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    if (renderObject.child == child)
      renderObject.child = null;
    else
      super.removeChildRenderObject(child);
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

class RenderSliverPrototypeExtentList extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverPrototypeExtentList({
    @required SliverPrototypeExtentListElement childManager,
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

/// A sliver that places its box children in a linear array and constrains them
/// to have the same extent as a prototype item along the main axis.
///
/// [RenderSliverPrototypeExtentList] places its children in a linear array along
/// the main axis starting at offset zero and without gaps. Each child is forced
/// to have the same extent as the [prototypeItem] along the main axis and the
/// [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [RenderSliverPrototypeExtentList] is more efficient than [RenderSliverList]
/// because [RenderSliverPrototypeExtentList] does not need to perform layout on
/// its children to obtain their extent in the main axis. It's a little
/// more flexible than [RenderSliverFixedExtentList] because there's no need to
/// determine the approriate item extent in pixels.
///
/// See also:
///
///  * [RenderSliverFixedExtentList], which has a configurable [itemExtent].
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [RenderSliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [RenderSliverFillRemaining], which determines the [itemExtent] based on
///    [SliverConstraints.remainingPaintExtent].
class SliverPrototypeExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places its box children in a linear array and
  /// constrains them to have the same extent as a prototype item along
  /// the main axis.
  const SliverPrototypeExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.prototypeItem,
  }) : super(key: key, delegate: delegate);

  /// Defines the main axis extent of all of this sliver's children.
  ///
  /// The [prototypeItem] is laid out before the rest of the sliver's children
  /// and its size along the main axis fixes the size of each child. The
  /// [prototypeItem] is essentially [Offstage]: it is not painted and it
  /// can not respond to input.
  final Widget prototypeItem;

  @override
  RenderSliverPrototypeExtentList createRenderObject(BuildContext context) {
    final SliverPrototypeExtentListElement element = context;
    return new RenderSliverPrototypeExtentList(childManager: element);
  }

  @override
  SliverPrototypeExtentListElement createElement() => new SliverPrototypeExtentListElement(this);
}
