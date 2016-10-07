// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cassowary.dart' as al; // "auto layout"
import 'package:meta/meta.dart';

import 'box.dart';
import 'object.dart';

/// Hosts the edge parameters and vends useful methods to construct expressions
/// for constraints. Also sets up and manages implicit constraints and edit
/// variables.
class AutoLayoutRect {
  /// Creates parameters for a rectangle for use with auto layout.
  AutoLayoutRect()
    : left = new al.Param(),
      right = new al.Param(),
      top = new al.Param(),
      bottom = new al.Param();

  /// A parameter that represents the left edge of the rectangle.
  final al.Param left;

  /// A parameter that represents the right edge of the rectangle.
  final al.Param right;

  /// A parameter that represents the top edge of the rectangle.
  final al.Param top;

  /// A parameter that represents the bottom edge of the rectangle.
  final al.Param bottom;

  /// An expression that represents the horizontal extent of the rectangle.
  al.Expression get width => right - left;

  /// An expression that represents the vertical extent of the rectangle.
  al.Expression get height => bottom - top;

  /// An expression that represents halfway between the left and right edges of the rectangle.
  al.Expression get horizontalCenter => (left + right) / al.cm(2.0);

  /// An expression that represents halfway between the top and bottom edges of the rectangle.
  al.Expression get verticalCenter => (top + bottom) / al.cm(2.0);

  /// Constraints that require that this rect contains the given rect.
  List<al.Constraint> contains(AutoLayoutRect other) {
    return <al.Constraint>[
      other.left >= left,
      other.right <= right,
      other.top >= top,
      other.bottom <= bottom,
    ];
  }
}

/// Parent data for use with [RenderAutoLayout].
class AutoLayoutParentData extends ContainerBoxParentDataMixin<RenderBox> {
  /// Creates parent data associated with the given render box.
  AutoLayoutParentData(this._renderBox);

  final RenderBox _renderBox;

  /// Parameters that represent the size and position of the render box.
  AutoLayoutRect get rect => _rect;
  AutoLayoutRect _rect;
  set rect(AutoLayoutRect value) {
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
      width: _rect.right.value - _rect.left.value,
      height: _rect.bottom.value - _rect.top.value
    );
  }

  Offset get _offsetFromSolver {
    return new Offset(_rect.left.value, _rect.top.value);
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
      _rect.left >= al.cm(0.0), // The left edge must be positive.
      _rect.right >= _rect.left, // Width must be positive.
      // TODO(chinmay): Check whether we need something similar for the top and
      // bottom.
    ];
  }
}

/// Subclass to control the layout of a [RenderAutoLayout].
abstract class AutoLayoutDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AutoLayoutDelegate();

  /// Returns the constraints to use when computing layout.
  ///
  /// The `parent` argument contains the parameters for the parent's position
  /// and size. Typical implementations will return constraints that determine
  /// the size and position of each child.
  ///
  /// The delegate interface does not provide a mechanism for obtaining the
  /// parameters for children. Subclasses are expected to obtain those
  /// parameters through some other mechanism.
  List<al.Constraint> getConstraints(AutoLayoutRect parent);

  /// Override this method to return true when new constraints need to be generated.
  bool shouldUpdateConstraints(@checked AutoLayoutDelegate oldDelegate);
}

/// A render object that uses the cassowary constraint solver to automatically size and position children.
class RenderAutoLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, AutoLayoutParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, AutoLayoutParentData> {
  /// Creates a render box that automatically sizes and positions its children.
  RenderAutoLayout({
    AutoLayoutDelegate delegate,
    List<RenderBox> children
  }) : _delegate = delegate, _needToUpdateConstraints = (delegate != null) {
    _solver.addEditVariables(<al.Variable>[
        _rect.left.variable,
        _rect.right.variable,
        _rect.top.variable,
        _rect.bottom.variable
      ], al.Priority.required - 1);

    addAll(children);
  }

  /// The delegate that generates constraints for the layout.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [AutoLayoutDelegate.shouldUpdateConstraints] called; if
  /// the result is `true`, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the delgate is null, the layout is unconstrained.
  AutoLayoutDelegate get delegate => _delegate;
  AutoLayoutDelegate _delegate;
  set delegate(AutoLayoutDelegate newDelegate) {
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
        ..suggestValueForVariable(_rect.left.variable, 0.0)
        ..suggestValueForVariable(_rect.top.variable, 0.0)
        ..suggestValueForVariable(_rect.bottom.variable, size.height)
        ..suggestValueForVariable(_rect.right.variable, size.width);
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
