// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cassowary.dart' as al; // "auto layout"

import 'box.dart';
import 'object.dart';

/// Hosts the edge parameters and vends useful methods to construct expressions
/// for constraints. Also sets up and manages implicit constraints and edit
/// variables.
class AutoLayoutRect {
  AutoLayoutRect() {
    _left = new al.Param();
    _right = new al.Param();
    _top = new al.Param();
    _bottom = new al.Param();
  }

  al.Param _left;
  al.Param _right;
  al.Param _top;
  al.Param _bottom;

  al.Param get left => _left;
  al.Param get right => _right;
  al.Param get top => _top;
  al.Param get bottom => _bottom;

  al.Expression get width => _right - _left;
  al.Expression get height => _bottom - _top;

  al.Expression get horizontalCenter => (_left + _right) / al.cm(2.0);
  al.Expression get verticalCenter => (_top + _bottom) / al.cm(2.0);

  List<al.Constraint> contains(AutoLayoutRect other) {
    return <al.Constraint>[
      other.left >= left,
      other.right <= right,
      other.top >= top,
      other.bottom <= bottom,
    ];
  }
}

class AutoLayoutParentData extends ContainerBoxParentDataMixin<RenderBox> {
  AutoLayoutParentData(this._renderBox);

  final RenderBox _renderBox;

  AutoLayoutRect get rect => _rect;
  AutoLayoutRect _rect;
  void set rect(AutoLayoutRect value) {
    if (_rect == value)
      return;
    if (_rect != null)
      _removeImplicitConstraints();
    _rect = value;
    if (_rect != null)
      _addImplicitConstraints();
  }

  BoxConstraints get _constraintsFromSolver {
    return new BoxConstraints.tightFor(
      width: _rect._right.value - _rect._left.value,
      height: _rect._bottom.value - _rect._top.value
    );
  }

  Offset get _offsetFromSolver {
    return new Offset(_rect._left.value, _rect._top.value);
  }

  List<al.Constraint> _implicitConstraints;

  void _addImplicitConstraints() {
    assert(_renderBox != null);
    if (_renderBox.parent == null || _rect == null)
      return;
    final List<al.Constraint> implicit = _constructImplicitConstraints();
    assert(implicit != null && implicit.isNotEmpty);
    assert(_renderBox.parent is RenderAutoLayout);
    final RenderAutoLayout parent = _renderBox.parent;
    final al.Result result = parent._solver.addConstraints(implicit);
    assert(result == al.Result.success);
    parent.markNeedsLayout();
    _implicitConstraints = implicit;
  }

  void _removeImplicitConstraints() {
    assert(_renderBox != null);
    if (_renderBox.parent == null || _implicitConstraints == null || _implicitConstraints.isEmpty)
      return;
    assert(_renderBox.parent is RenderAutoLayout);
    final RenderAutoLayout parent = _renderBox.parent;
    final al.Result result = parent._solver.removeConstraints(_implicitConstraints);
    assert(result == al.Result.success);
    parent.markNeedsLayout();
    _implicitConstraints = null;
  }

  /// Returns the set of implicit constraints that need to be applied to all
  /// instances of this class when they are moved into a render object with an
  /// active solver. If no implicit constraints needs to be applied, the object
  /// may return null.
  List<al.Constraint> _constructImplicitConstraints() {
    return <al.Constraint>[
      _rect._left >= al.cm(0.0), // The left edge must be positive.
      _rect._right >= _rect._left, // Width must be positive.
      // Why don't we need something similar for the top and the bottom?
    ];
  }
}

abstract class AutoLayoutDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AutoLayoutDelegate();

  List<al.Constraint> getConstraints(AutoLayoutRect parent);
  bool shouldUpdateConstraints(AutoLayoutDelegate oldDelegate);
}

class RenderAutoLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, AutoLayoutParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, AutoLayoutParentData> {

  RenderAutoLayout({
    AutoLayoutDelegate delegate,
    List<RenderBox> children
  }) : _delegate = delegate, _needToUpdateConstraints = (delegate != null) {
    _solver.addEditVariables(<al.Variable>[
        _rect._left.variable,
        _rect._right.variable,
        _rect._top.variable,
        _rect._bottom.variable
      ], al.Priority.required - 1);

    addAll(children);
  }

  AutoLayoutDelegate get delegate => _delegate;
  AutoLayoutDelegate _delegate;
  void set delegate(AutoLayoutDelegate newDelegate) {
    if (_delegate == newDelegate)
      return;
    AutoLayoutDelegate oldDelegate = _delegate;
    _delegate = newDelegate;
    if (newDelegate == null) {
      assert(oldDelegate != null);
      _needToUpdateConstraints = true;
      markNeedsLayout();
    } else if (oldDelegate == null ||
        newDelegate.runtimeType != oldDelegate.runtimeType ||
        newDelegate.shouldUpdateConstraints(oldDelegate)) {
      _needToUpdateConstraints = true;
      markNeedsLayout();
    }
  }

  bool _needToUpdateConstraints;

  final AutoLayoutRect _rect = new AutoLayoutRect();

  final al.Solver _solver = new al.Solver();
  final List<al.Constraint> _explicitConstraints = new List<al.Constraint>();

  void _setExplicitConstraints(List<al.Constraint> constraints) {
    assert(constraints != null);
    if (constraints.isEmpty)
      return;
    if (_solver.addConstraints(constraints) == al.Result.success)
      _explicitConstraints.addAll(constraints);
  }

  void _clearExplicitConstraints() {
    if (_explicitConstraints.isEmpty)
      return;
    if (_solver.removeConstraints(_explicitConstraints) == al.Result.success)
      _explicitConstraints.clear();
  }

  @override
  void adoptChild(RenderObject child) {
    // Make sure to call super first to setup the parent data
    super.adoptChild(child);
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._addImplicitConstraints();
    assert(child.parentData == childParentData);
  }

  @override
  void dropChild(RenderObject child) {
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._removeImplicitConstraints();
    assert(child.parentData == childParentData);
    super.dropChild(child);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! AutoLayoutParentData)
      child.parentData = new AutoLayoutParentData(child);
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  Size _previousSize;

  @override
  void performLayout() {
    bool needToFlushUpdates = false;

    if (_needToUpdateConstraints) {
      _clearExplicitConstraints();
      if (_delegate != null)
        _setExplicitConstraints(_delegate.getConstraints(_rect));
      _needToUpdateConstraints = false;
      needToFlushUpdates = true;
    }

    if (size != _previousSize) {
      _solver
        ..suggestValueForVariable(_rect._left.variable, 0.0)
        ..suggestValueForVariable(_rect._top.variable, 0.0)
        ..suggestValueForVariable(_rect._bottom.variable, size.height)
        ..suggestValueForVariable(_rect._right.variable, size.width);
      _previousSize = size;
      needToFlushUpdates = true;
    }

    if (needToFlushUpdates)
      _solver.flushUpdates();

    RenderBox child = firstChild;
    while (child != null) {
      final AutoLayoutParentData childParentData = child.parentData;
      child.layout(childParentData._constraintsFromSolver);
      childParentData.offset = childParentData._offsetFromSolver;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
