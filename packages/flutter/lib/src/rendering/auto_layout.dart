// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cassowary/cassowary.dart' as al; // "auto layout"

import 'box.dart';
import 'object.dart';

/// Hosts the edge parameters and vends useful methods to construct expressions
/// for constraints. Also sets up and manages implicit constraints and edit
/// variables.
class AutoLayoutParams {
  AutoLayoutParams() {
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

  List<al.Constraint> contains(AutoLayoutParams other) {
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

  AutoLayoutParams get params => _params;
  AutoLayoutParams _params;
  void set params(AutoLayoutParams value) {
    if (_params == value)
      return;
    if (_params != null)
      _removeImplicitConstraints();
    _params = value;
    if (_params != null)
      _addImplicitConstraints();
  }

  BoxConstraints get _constraintsFromSolver {
    return new BoxConstraints.tightFor(
      width: _params._right.value - _params._left.value,
      height: _params._bottom.value - _params._top.value
    );
  }

  Offset get _offsetFromSolver {
    return new Offset(_params._left.value, _params._top.value);
  }

  List<al.Constraint> _implicitConstraints;

  void _addImplicitConstraints() {
    assert(_renderBox != null);
    if (_renderBox.parent == null || _params == null)
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
      _params._left >= al.cm(0.0), // The left edge must be positive.
      _params._right >= _params._left, // Width must be positive.
    ];
  }
}

abstract class AutoLayoutDelegate {
  const AutoLayoutDelegate();

  List<al.Constraint> getConstraints(AutoLayoutParams parent);
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
        _params._left.variable,
        _params._right.variable,
        _params._top.variable,
        _params._bottom.variable
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

  final AutoLayoutParams _params = new AutoLayoutParams();

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

  void adoptChild(RenderObject child) {
    // Make sure to call super first to setup the parent data
    super.adoptChild(child);
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._addImplicitConstraints();
    assert(child.parentData == childParentData);
  }

  void dropChild(RenderObject child) {
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._removeImplicitConstraints();
    assert(child.parentData == childParentData);
    super.dropChild(child);
  }

  void setupParentData(RenderObject child) {
    if (child.parentData is! AutoLayoutParentData)
      child.parentData = new AutoLayoutParentData(child);
  }

  bool get sizedByParent => true;

  void performResize() {
    size = constraints.biggest;
  }

  Size _previousSize;

  void performLayout() {
    bool needToFlushUpdates = false;

    if (_needToUpdateConstraints) {
      _clearExplicitConstraints();
      if (_delegate != null)
        _setExplicitConstraints(_delegate.getConstraints(_params));
      _needToUpdateConstraints = false;
      needToFlushUpdates = true;
    }

    if (size != _previousSize) {
      _solver
        ..suggestValueForVariable(_params._left.variable, 0.0)
        ..suggestValueForVariable(_params._top.variable, 0.0)
        ..suggestValueForVariable(_params._bottom.variable, size.height)
        ..suggestValueForVariable(_params._right.variable, size.width);
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

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
