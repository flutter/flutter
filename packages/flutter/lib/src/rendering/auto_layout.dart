// Copyright 2015 The Chromium Authors. All rights reserved.
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
    _leftEdge = new al.Param.withContext(this);
    _rightEdge = new al.Param.withContext(this);
    _topEdge = new al.Param.withContext(this);
    _bottomEdge = new al.Param.withContext(this);
  }

  /// The render box with which these parameters are associated.
  RenderBox _renderBox;

  al.Param _leftEdge;
  al.Param _rightEdge;
  al.Param _topEdge;
  al.Param _bottomEdge;

  al.Param get leftEdge => _leftEdge;
  al.Param get rightEdge => _rightEdge;
  al.Param get topEdge => _topEdge;
  al.Param get bottomEdge => _bottomEdge;

  al.Expression get width => _rightEdge - _leftEdge;
  al.Expression get height => _bottomEdge - _topEdge;

  al.Expression get horizontalCenter => (_leftEdge + _rightEdge) / al.cm(2.0);
  al.Expression get verticalCenter => (_topEdge + _bottomEdge) / al.cm(2.0);

  List<al.Constraint> _implicitConstraints;

  void _addImplicitConstraints() {
    assert(_renderBox != null);
    if (_renderBox.parent == null)
      return;
    assert(_renderBox.parent is RenderAutoLayout);
    final RenderAutoLayout parent = _renderBox.parent;
    final AutoLayoutParentData parentData = _renderBox.parentData;
    final List<al.Constraint> implicit = parentData._constructImplicitConstraints();
    if (implicit == null || implicit.isEmpty)
      return;
    final al.Result result = parent._solver.addConstraints(implicit);
    assert(result == al.Result.success);
    parent.markNeedsLayout();
    _implicitConstraints = implicit;
  }

  void _removeImplicitConstraints() {
    assert(_renderBox != null);
    if (_renderBox.parent == null)
      return;
    if (_implicitConstraints == null || _implicitConstraints.isEmpty)
      return;
    assert(_renderBox.parent is RenderAutoLayout);
    final RenderAutoLayout parent = _renderBox.parent;
    final al.Result result = parent._solver.removeConstraints(_implicitConstraints);
    assert(result == al.Result.success);
    parent.markNeedsLayout();
    _implicitConstraints = null;
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
    if (_params != null) {
      _params._removeImplicitConstraints();
      _params._renderBox = null;
    }
    _params = value;
    if (_params != null) {
      assert(_params._renderBox == null);
      _params._renderBox = _renderBox;
      _params._addImplicitConstraints();
    }
  }

  BoxConstraints get _constraints {
    return new BoxConstraints.tightFor(
      width: _params._rightEdge.value - _params._leftEdge.value,
      height: _params._bottomEdge.value - _params._topEdge.value
    );
  }

  /// Returns the set of implicit constraints that need to be applied to all
  /// instances of this class when they are moved into a render object with an
  /// active solver. If no implicit constraints needs to be applied, the object
  /// may return null.
  List<al.Constraint> _constructImplicitConstraints() {
    return <al.Constraint>[
      _params._leftEdge >= al.cm(0.0), // The left edge must be positive.
      _params._rightEdge >= _params._leftEdge, // Width must be positive.
    ];
  }
}

abstract class AutoLayoutDelegate {
  const AutoLayoutDelegate();

  List<al.Constraint> getConstraints(AutoLayoutParams parentParams);
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
        _params._leftEdge.variable,
        _params._rightEdge.variable,
        _params._topEdge.variable,
        _params._bottomEdge.variable
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

  void _addExplicitConstraints(List<al.Constraint> constraints) {
    if (constraints == null || constraints.isEmpty)
      return;
    if (_solver.addConstraints(constraints) == al.Result.success)
      _explicitConstraints.addAll(constraints);
  }

  void _clearExplicitConstraints() {
    if (_solver.removeConstraints(_explicitConstraints) == al.Result.success)
      _explicitConstraints.clear();
  }

  void adoptChild(RenderObject child) {
    // Make sure to call super first to setup the parent data
    super.adoptChild(child);
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._params?._addImplicitConstraints();
    assert(child.parentData == childParentData);
  }

  void dropChild(RenderObject child) {
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._params?._removeImplicitConstraints();
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

  void performLayout() {
    // Step 1: Update constraints if needed.
    if (_needToUpdateConstraints) {
      _clearExplicitConstraints();
      if (_delegate != null)
        _addExplicitConstraints(_delegate.getConstraints(_params));
      _needToUpdateConstraints = false;
    }

    // Step 2: Update dimensions of this render object.
    _solver
      ..suggestValueForVariable(_params._leftEdge.variable, 0.0)
      ..suggestValueForVariable(_params._topEdge.variable, 0.0)
      ..suggestValueForVariable(_params._bottomEdge.variable, size.height)
      ..suggestValueForVariable(_params._rightEdge.variable, size.width);

    // Step 3: Resolve solver updates and flush parameters

    // We don't iterate over the children, instead, we ask the solver to tell
    // us the updated parameters. Attached to the parameters (via the context)
    // are the AutoLayoutParams instances.
    for (AutoLayoutParams update in _solver.flushUpdates()) {
      RenderBox child = update._renderBox;
      if (child != null)
        _layoutChild(child);
    }
  }

  void _layoutChild(RenderBox child) {
    assert(debugDoingThisLayout);
    assert(child.parent == this);
    final AutoLayoutParentData childParentData = child.parentData;
    child.layout(childParentData._constraints);
    childParentData.offset = new Offset(childParentData._params._leftEdge.value,
                                        childParentData._params._topEdge.value);
    assert(child.parentData == childParentData);
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
