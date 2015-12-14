// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cassowary/cassowary.dart' as al; // "auto layout"

import 'box.dart';
import 'object.dart';

/// Hosts the edge parameters and vends useful methods to construct expressions
/// for constraints. Also sets up and manages implicit constraints and edit
/// variables. Used as a mixin by layout containers and parent data instances
/// of render boxes taking part in auto layout.
abstract class _AutoLayoutParamMixin {

  void _setupLayoutParameters(dynamic context) {
    _leftEdge = new al.Param.withContext(context);
    _rightEdge = new al.Param.withContext(context);
    _topEdge = new al.Param.withContext(context);
    _bottomEdge = new al.Param.withContext(context);
  }

  al.Param _leftEdge;
  al.Param _rightEdge;
  al.Param _topEdge;
  al.Param _bottomEdge;

  List<al.Constraint> _implicitConstraints;

  al.Param get leftEdge => _leftEdge;
  al.Param get rightEdge => _rightEdge;
  al.Param get topEdge => _topEdge;
  al.Param get bottomEdge => _bottomEdge;

  al.Expression get width => _rightEdge - _leftEdge;
  al.Expression get height => _bottomEdge - _topEdge;

  al.Expression get horizontalCenter => (_leftEdge + _rightEdge) / al.cm(2.0);
  al.Expression get verticalCenter => (_topEdge + _bottomEdge) / al.cm(2.0);

  void _setupEditVariablesInSolver(al.Solver solver, double priority) {
    solver.addEditVariables(<al.Variable>[
        _leftEdge.variable,
        _rightEdge.variable,
        _topEdge.variable,
        _bottomEdge.variable
      ], priority);
  }

  void _applyEditsAtSize(al.Solver solver, Size size) {
    solver.suggestValueForVariable(_leftEdge.variable, 0.0);
    solver.suggestValueForVariable(_topEdge.variable, 0.0);
    solver.suggestValueForVariable(_bottomEdge.variable, size.height);
    solver.suggestValueForVariable(_rightEdge.variable, size.width);
  }

  /// Applies the parameter updates.
  ///
  /// This method is called when the solver has updated at least one of the
  /// layout parameters of this object. The object is now responsible for
  /// applying this update to its other properties (if necessary).
  void _applyAutolayoutParameterUpdates();

  /// Returns the set of implicit constraints that need to be applied to all
  /// instances of this class when they are moved into a render object with an
  /// active solver. If no implicit constraints needs to be applied, the object
  /// may return null.
  List<al.Constraint> _constructImplicitConstraints();

  void _setupImplicitConstraints(al.Solver solver) {
    List<al.Constraint> implicit = _constructImplicitConstraints();

    if (implicit == null || implicit.length == 0) {
      return;
    }

    al.Result result = solver.addConstraints(implicit);
    assert(result == al.Result.success);

    _implicitConstraints = implicit;
  }

  void _removeImplicitConstraints(al.Solver solver) {
    if (_implicitConstraints == null || _implicitConstraints.length == 0) {
      return;
    }

    al.Result result = solver.removeConstraints(_implicitConstraints);
    assert(result == al.Result.success);

    _implicitConstraints = null;
  }
}

class AutoLayoutParentData extends ContainerBoxParentDataMixin<RenderBox> with _AutoLayoutParamMixin {

  AutoLayoutParentData(this._renderBox) {
    _setupLayoutParameters(this);
  }

  final RenderBox _renderBox;

  void _applyAutolayoutParameterUpdates() {
    // This is called by the parent's layout function
    // to lay our box out.
    assert(_renderBox.parentData == this);
    assert(() {
      final RenderAutoLayout parent = _renderBox.parent;
      assert(parent.debugDoingThisLayout);
    });
    BoxConstraints size = new BoxConstraints.tightFor(
      width: _rightEdge.value - _leftEdge.value,
      height: _bottomEdge.value - _topEdge.value
    );
    _renderBox.layout(size);
    position = new Point(_leftEdge.value, _topEdge.value);
  }

  List<al.Constraint> _constructImplicitConstraints() {
    return <al.Constraint>[
      _leftEdge >= al.cm(0.0), // The left edge must be positive.
      _rightEdge >= _leftEdge, // Width must be positive.
    ];
  }

}

class RenderAutoLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, AutoLayoutParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, AutoLayoutParentData>,
         _AutoLayoutParamMixin {

  RenderAutoLayout({ List<RenderBox> children }) {
    _setupLayoutParameters(this);
    _setupEditVariablesInSolver(_solver, al.Priority.required - 1);
    addAll(children);
  }

  final al.Solver _solver = new al.Solver();
  List<al.Constraint> _explicitConstraints = new List<al.Constraint>();

  /// Adds all the given constraints to the solver. Either all constraints are
  /// added or none.
  al.Result addConstraints(List<al.Constraint> constraints) {
    al.Result result = _solver.addConstraints(constraints);
    if (result == al.Result.success) {
      markNeedsLayout();
      _explicitConstraints.addAll(constraints);
    }
    return result;
  }

  /// Adds the given constraint to the solver.
  al.Result addConstraint(al.Constraint constraint) {
    al.Result result = _solver.addConstraint(constraint);

    if (result == al.Result.success) {
      markNeedsLayout();
      _explicitConstraints.add(constraint);
    }

    return result;
  }

  /// Removes all explicitly added constraints.
  al.Result clearAllConstraints() {
    al.Result result = _solver.removeConstraints(_explicitConstraints);

    if (result == al.Result.success) {
      markNeedsLayout();
      _explicitConstraints = new List<al.Constraint>();
    }

    return result;
  }

  void adoptChild(RenderObject child) {
    // Make sure to call super first to setup the parent data
    super.adoptChild(child);
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._setupImplicitConstraints(_solver);
    assert(child.parentData == childParentData);
  }

  void dropChild(RenderObject child) {
    final AutoLayoutParentData childParentData = child.parentData;
    childParentData._removeImplicitConstraints(_solver);
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
    // Step 1: Update dimensions of self
    _applyEditsAtSize(_solver, size);

    // Step 2: Resolve solver updates and flush parameters

    // We don't iterate over the children, instead, we ask the solver to tell
    // us the updated parameters. Attached to the parameters (via the context)
    // are the _AutoLayoutParamMixin instances.
    for (_AutoLayoutParamMixin update in _solver.flushUpdates()) {
      update._applyAutolayoutParameterUpdates();
    }
  }

  void _applyAutolayoutParameterUpdates() {
    // Nothing to do since the size update has already been presented to the
    // solver as an edit variable modification. The invokation of this method
    // only indicates that the value has been flushed to the variable.
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  List<al.Constraint> _constructImplicitConstraints() {
    // Only edits variables are present on layout containers. If, in the future,
    // implicit constraints (for say margins, padding, etc.) need to be added,
    // they must be returned from here.
    return null;
  }
}
