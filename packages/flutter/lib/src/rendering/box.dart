// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'object.dart';

export 'package:flutter/painting.dart' show FractionalOffset, TextBaseline;

// This class should only be used in debug builds
class _DebugSize extends Size {
  _DebugSize(Size source, this._owner, this._canBeUsedByParent): super.copy(source);
  final RenderBox _owner;
  final bool _canBeUsedByParent;
}

/// Immutable layout constraints for box layout
///
/// A size respects a BoxConstraints if, and only if, all of the following
/// relations hold:
///
/// * `minWidth <= size.width <= maxWidth`
/// * `minHeight <= size.height <= maxHeight`
///
/// The constraints themselves must satisfy these relations:
///
/// * `0.0 <= minWidth <= maxWidth <= double.INFINITY`
/// * `0.0 <= minHeight <= maxHeight <= double.INFINITY`
///
/// Note: `double.INFINITY` is a legal value for each constraint.
class BoxConstraints extends Constraints {
  /// Constructs box constraints with the given constraints
  const BoxConstraints({
    this.minWidth: 0.0,
    this.maxWidth: double.INFINITY,
    this.minHeight: 0.0,
    this.maxHeight: double.INFINITY
  });

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  /// Constructs box constraints that is respected only by the given size
  BoxConstraints.tight(Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  /// Constructs box constraints that require the given width or height
  const BoxConstraints.tightFor({
    double width,
    double height
  }): minWidth = width != null ? width : 0.0,
      maxWidth = width != null ? width : double.INFINITY,
      minHeight = height != null ? height : 0.0,
      maxHeight = height != null ? height : double.INFINITY;

  /// Constructs box constraints that forbid sizes larger than the given size
  BoxConstraints.loose(Size size)
    : minWidth = 0.0,
      maxWidth = size.width,
      minHeight = 0.0,
      maxHeight = size.height;

  /// Constructs box constraints that expand to fill another box contraints
  ///
  /// If width or height is given, the constraints will require exactly the
  /// given value in the given dimension.
  const BoxConstraints.expand({
    double width,
    double height
  }): minWidth = width != null ? width : double.INFINITY,
      maxWidth = width != null ? width : double.INFINITY,
      minHeight = height != null ? height : double.INFINITY,
      maxHeight = height != null ? height : double.INFINITY;

  /// Returns new box constraints that are smaller by the given edge dimensions
  BoxConstraints deflate(EdgeDims edges) {
    assert(edges != null);
    double horizontal = edges.left + edges.right;
    double vertical = edges.top + edges.bottom;
    double deflatedMinWidth = math.max(0.0, minWidth - horizontal);
    double deflatedMinHeight = math.max(0.0, minHeight - vertical);
    return new BoxConstraints(
      minWidth: deflatedMinWidth,
      maxWidth: math.max(deflatedMinWidth, maxWidth - horizontal),
      minHeight: deflatedMinHeight,
      maxHeight: math.max(deflatedMinHeight, maxHeight - vertical)
    );
  }

  /// Returns new box constraints that remove the minimum width and height requirements
  BoxConstraints loosen() {
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight
    );
  }

  /// Returns new box constraints that respect the given constraints while being as close as possible to the original constraints
  BoxConstraints enforce(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: clamp(min: constraints.minWidth, max: constraints.maxWidth, value: minWidth),
      maxWidth: clamp(min: constraints.minWidth, max: constraints.maxWidth, value: maxWidth),
      minHeight: clamp(min: constraints.minHeight, max: constraints.maxHeight, value: minHeight),
      maxHeight: clamp(min: constraints.minHeight, max: constraints.maxHeight, value: maxHeight)
    );
  }

  /// Returns new box constraints with a tight width as close to the given width as possible while still respecting the original box constraints
  BoxConstraints tightenWidth(double width) {
    return new BoxConstraints(minWidth: math.max(math.min(maxWidth, width), minWidth),
                              maxWidth: math.max(math.min(maxWidth, width), minWidth),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  /// Returns new box constraints with a tight height as close to the given height as possible while still respecting the original box constraints
  BoxConstraints tightenHeight(double height) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: math.max(math.min(maxHeight, height), minHeight),
                              maxHeight: math.max(math.min(maxHeight, height), minHeight));
  }

  /// Returns box constraints with the same width constraints but with unconstrainted height
  BoxConstraints widthConstraints() => new BoxConstraints(minWidth: minWidth, maxWidth: maxWidth);

  /// Returns box constraints with the same height constraints but with unconstrainted width
  BoxConstraints heightConstraints() => new BoxConstraints(minHeight: minHeight, maxHeight: maxHeight);

  /// Returns the width that both satisfies the constraints and is as close as possible to the given width
  double constrainWidth([double width = double.INFINITY]) {
    return clamp(min: minWidth, max: maxWidth, value: width);
  }

  /// Returns the height that both satisfies the constraints and is as close as possible to the given height
  double constrainHeight([double height = double.INFINITY]) {
    return clamp(min: minHeight, max: maxHeight, value: height);
  }

  /// Returns the size that both satisfies the constraints and is as close as possible to the given size
  Size constrain(Size size) {
    Size result = new Size(constrainWidth(size.width), constrainHeight(size.height));
    if (size is _DebugSize)
      result = new _DebugSize(result, size._owner, size._canBeUsedByParent);
    return result;
  }

  /// The biggest size that satisifes the constraints
  Size get biggest => new Size(constrainWidth(), constrainHeight());

  /// The smallest size that satisfies the constraints
  Size get smallest => new Size(constrainWidth(0.0), constrainHeight(0.0));

  /// Whether there is exactly one width value that satisfies the constraints
  bool get hasTightWidth => minWidth >= maxWidth;

  /// Whether there is exactly one height value that satisfies the constraints
  bool get hasTightHeight => minHeight >= maxHeight;

  /// Whether there is exactly one size that satifies the constraints
  bool get isTight => hasTightWidth && hasTightHeight;

  /// Whether the given size satisfies the constraints
  bool isSatisfiedBy(Size size) {
    return (minWidth <= size.width) && (size.width <= math.max(minWidth, maxWidth)) &&
           (minHeight <= size.height) && (size.height <= math.max(minHeight, maxHeight));
  }

  BoxConstraints operator*(double other) {
    return new BoxConstraints(
      minWidth: minWidth * other,
      maxWidth: maxWidth * other,
      minHeight: minHeight * other,
      maxHeight: maxHeight * other
    );
  }

  BoxConstraints operator/(double other) {
    return new BoxConstraints(
      minWidth: minWidth / other,
      maxWidth: maxWidth / other,
      minHeight: minHeight / other,
      maxHeight: maxHeight / other
    );
  }

  BoxConstraints operator~/(double other) {
    return new BoxConstraints(
      minWidth: (minWidth ~/ other).toDouble(),
      maxWidth: (maxWidth ~/ other).toDouble(),
      minHeight: (minHeight ~/ other).toDouble(),
      maxHeight: (maxHeight ~/ other).toDouble()
    );
  }

  BoxConstraints operator%(double other) {
    return new BoxConstraints(
      minWidth: minWidth % other,
      maxWidth: maxWidth % other,
      minHeight: minHeight % other,
      maxHeight: maxHeight % other
    );
  }

  /// Linearly interpolate between two BoxConstraints
  ///
  /// If either is null, this function interpolates from [BoxConstraints.zero].
  static BoxConstraints lerp(BoxConstraints a, BoxConstraints b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new BoxConstraints(
      minWidth: ui.lerpDouble(a.minWidth, b.minWidth, t),
      maxWidth: ui.lerpDouble(a.maxWidth, b.maxWidth, t),
      minHeight: ui.lerpDouble(a.minHeight, b.minHeight, t),
      maxHeight: ui.lerpDouble(a.maxHeight, b.maxHeight, t)
    );
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BoxConstraints)
      return false;
    final BoxConstraints typedOther = other;
    return minWidth == typedOther.minWidth &&
           maxWidth == typedOther.maxWidth &&
           minHeight == typedOther.minHeight &&
           maxHeight == typedOther.maxHeight;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + minWidth.hashCode;
    value = 37 * value + maxWidth.hashCode;
    value = 37 * value + minHeight.hashCode;
    value = 37 * value + maxHeight.hashCode;
    return value;
  }

  String toString() {
    if (minWidth == double.INFINITY && minHeight == double.INFINITY)
      return 'BoxConstraints(biggest)';
    if (minWidth == 0 && maxWidth == double.INFINITY &&
        minHeight == 0 && maxHeight == double.INFINITY)
      return 'BoxConstraints(unconstrained)';
    String describe(double min, double max, String dim) {
      if (min == max)
        return '$dim=${min.toStringAsFixed(1)}';
      return '${min.toStringAsFixed(1)}<=$dim<=${max.toStringAsFixed(1)}';
    }
    final String width = describe(minWidth, maxWidth, 'w');
    final String height = describe(minHeight, maxHeight, 'h');
    return 'BoxConstraints($width, $height)';
  }
}

/// A hit test entry used by [RenderBox]
class BoxHitTestEntry extends HitTestEntry {
  const BoxHitTestEntry(RenderBox target, this.localPosition) : super(target);

  RenderBox get target => super.target;

  /// The position of the hit test in the local coordinates of [target]
  final Point localPosition;

  String toString() => '${target.runtimeType}@$localPosition';
}

/// Parent data used by [RenderBox] and its subclasses
class BoxParentData extends ParentData {
  // TODO(abarth): Switch to using an Offset rather than a Point here. This
  //               value is really the offset from the parent.
  Point _position = Point.origin;
  /// The point at which to paint the child in the parent's coordinate system
  Point get position => _position;
  void set position(Point value) {
    assert(RenderObject.debugDoingLayout);
    _position = value;
  }
  Offset get offset => _position.toOffset();
  String toString() => 'position=$position';
}

/// Abstract ParentData subclass for RenderBox subclasses that want the
/// ContainerRenderObjectMixin.
abstract class ContainerBoxParentDataMixin<ChildType extends RenderObject> extends BoxParentData with ContainerParentDataMixin<ChildType> { }

/// A render object in a 2D cartesian coordinate system
///
/// The size of each box is expressed as a width and a height. Each box has its
/// own coordinate system in which its upper left corner is placed at (0, 0).
/// The lower right corner of the box is therefore at (width, height). The box
/// contains all the points including the upper left corner and extending to,
/// but not including, the lower right corner.
///
/// Box layout is performed by passing a [BoxConstraints] object down the tree.
/// The box constraints establish a min and max value for the child's width
/// and height. In determining its size, the child must respect the constraints
/// given to it by its parent.
///
/// This protocol is sufficient for expressing a number of common box layout
/// data flows.  For example, to implement a width-in-height-out data flow, call
/// your child's [layout] function with a set of box constraints with a tight
/// width value (and pass true for parentUsesSize). After the child determines
/// its height, use the child's height to determine your size.
abstract class RenderBox extends RenderObject {

  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  /// Returns the minimum width that this box could be without failing to paint
  /// its contents within itself
  ///
  /// Override in subclasses that implement [performLayout].
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the height
  ///
  /// Override in subclasses that implement [performLayout].
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  /// Return the minimum height that this box could be without failing to render
  /// its contents within itself.
  ///
  /// Override in subclasses that implement [performLayout].
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the width.
  ///
  /// If the layout algorithm used is width-in-height-out, i.e. the height
  /// depends on the width and not vice versa, then this will return the same
  /// as getMinIntrinsicHeight().
  ///
  /// Override in subclasses that implement [performLayout].
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  /// The size of this render box computed during layout
  ///
  /// This value is stale whenever this object is marked as needing layout.
  /// During [performLayout], do not read the size of a child unless you pass
  /// true for parentUsesSize when calling the child's [layout] function.
  ///
  /// The size of a box should be set only during the box's [performLayout] or
  /// [performResize] functions. If you wish to change the size of a box outside
  /// of those functins, call [markNeedsLayout] instead to schedule a layout of
  /// the box.
  Size get size {
    assert(hasSize);
    assert(() {
      if (_size is _DebugSize) {
        final _DebugSize _size = this._size;
        assert(_size._owner == this);
        if (RenderObject.debugActiveLayout != null) {
          // We are always allowed to access our own size (for print debugging
          // and asserts if nothing else). Other than us, the only object that's
          // allowed to read our size is our parent, if they've said they will.
          // If you hit this assert trying to access a child's size, pass
          // "parentUsesSize: true" to that child's layout().
          assert(debugDoingThisResize || debugDoingThisLayout ||
                 (RenderObject.debugActiveLayout == parent && _size._canBeUsedByParent));
        }
        assert(_size == this._size);
      }
      return true;
    });
    return _size;
  }
  bool get hasSize => _size != null;
  Size _size;
  void set size(Size value) {
    assert((sizedByParent && debugDoingThisResize) ||
           (!sizedByParent && debugDoingThisLayout));
    assert(() {
      if (value is _DebugSize) {
        if (value._owner != this) {
          assert(value._owner.parent == this);
          assert(value._canBeUsedByParent);
        }
      }
      return true;
    });
    _size = value;
    assert(() {
      _size = new _DebugSize(_size, this, debugCanParentUseSize);
      return true;
    });
    assert(debugDoesMeetConstraints());
  }

  void debugResetSize() {
    // updates the value of size._canBeUsedByParent if necessary
    size = size;
  }

  Map<TextBaseline, double> _cachedBaselines;
  bool _ancestorUsesBaseline = false;
  static bool _debugDoingBaseline = false;
  static bool _debugSetDoingBaseline(bool value) {
    _debugDoingBaseline = value;
    return true;
  }

  /// Returns the distance from the y-coordinate of the position of the box to
  /// the y-coordinate of the first given baseline in the box's contents.
  ///
  /// Used by certain layout models to align adjacent boxes on a common
  /// baseline, regardless of padding, font size differences, etc. If there is
  /// no baseline, this function returns the distance from the y-coordinate of
  /// the position of the box to the y-coordinate of the bottom of the box
  /// (i.e., the height of the box) unless the the caller passes true
  /// for `onlyReal`, in which case the function returns null.
  ///
  /// Only call this function calling [layout] on this box. You are only
  /// allowed to call this from the parent of this box during that parent's
  /// [performLayout] or [paint] functions.
  double getDistanceToBaseline(TextBaseline baseline, { bool onlyReal: false }) {
    assert(!needsLayout);
    assert(!_debugDoingBaseline);
    final RenderObject parent = this.parent;
    assert(() {
      if (RenderObject.debugDoingLayout)
        return (RenderObject.debugActiveLayout == parent) && parent.debugDoingThisLayout;
      if (RenderObject.debugDoingPaint)
        return ((RenderObject.debugActivePaint == parent) && parent.debugDoingThisPaint) ||
               ((RenderObject.debugActivePaint == this) && debugDoingThisPaint);
      return false;
    });
    assert(_debugSetDoingBaseline(true));
    double result = getDistanceToActualBaseline(baseline);
    assert(_debugSetDoingBaseline(false));
    assert(parent == this.parent);
    if (result == null && !onlyReal)
      return size.height;
    return result;
  }

  /// Calls [computeDistanceToActualBaseline] and caches the result.
  ///
  /// This function must only be called from [getDistanceToBaseline] and
  /// [computeDistanceToActualBaseline]. Do not call this function directly from
  /// outside those two methods.
  double getDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
    _ancestorUsesBaseline = true;
    if (_cachedBaselines == null)
      _cachedBaselines = new Map<TextBaseline, double>();
    _cachedBaselines.putIfAbsent(baseline, () => computeDistanceToActualBaseline(baseline));
    return _cachedBaselines[baseline];
  }

  /// Returns the distance from the y-coordinate of the position of the box to
  /// the y-coordinate of the first given baseline in the box's contents, if
  /// any, or null otherwise.
  ///
  /// Do not call this function directly. Instead, call [getDistanceToBaseline]
  /// if you need to know the baseline of a child from an invocation of
  /// [performLayout] or [paint] and call [getDistanceToActualBaseline] if you
  /// are implementing [computeDistanceToActualBaseline] and need to defer to a
  /// child.
  ///
  /// Subclasses should override this function to supply the distances to their
  /// baselines.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
    return null;
  }

  /// The box constraints most recently received from the parent
  BoxConstraints get constraints => super.constraints;
  bool debugDoesMeetConstraints() {
    assert(constraints != null);
    assert(_size != null);
    assert(() {
      'See https://flutter.github.io/layout/#unbounded-constraints';
      return !_size.isInfinite;
    });
    bool result = constraints.isSatisfiedBy(_size);
    if (!result)
      debugPrint("${this.runtimeType} does not meet its constraints. Constraints: $constraints, size: $_size");
    return result;
  }

  void markNeedsLayout() {
    if (_cachedBaselines != null && _cachedBaselines.isNotEmpty) {
      // if we have cached data, then someone must have used our data
      assert(_ancestorUsesBaseline);
      final RenderObject parent = this.parent;
      parent.markNeedsLayout();
      assert(parent == this.parent);
      // Now that they're dirty, we can forget that they used the
      // baseline. If they use it again, then we'll set the bit
      // again, and if we get dirty again, we'll notify them again.
      _ancestorUsesBaseline = false;
      _cachedBaselines.clear();
    } else {
      // if we've never cached any data, then nobody can have used it
      assert(!_ancestorUsesBaseline);
    }
    super.markNeedsLayout();
  }
  void performResize() {
    // default behaviour for subclasses that have sizedByParent = true
    size = constraints.constrain(Size.zero);
    assert(!size.isInfinite);
  }
  void performLayout() {
    // descendants have to either override performLayout() to set both
    // width and height and lay out children, or, set sizedByParent to
    // true so that performResize()'s logic above does its thing.
    assert(sizedByParent);
  }

  /// Determines the set of render objects located at the given position
  ///
  /// Returns true if the given point is contained in this render object or one
  /// of its descendants. Adds any render objects that contain the point to the
  /// given hit test result.
  ///
  /// The caller is responsible for transforming [position] into the local
  /// coordinate space of the callee.  The callee is responsible for checking
  /// whether the given position is within its bounds.
  bool hitTest(HitTestResult result, { Point position }) {
    assert(!needsLayout);
    if (position.x >= 0.0 && position.x < _size.width &&
        position.y >= 0.0 && position.y < _size.height) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(new BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  /// Override this function if this render object can be hit even if its
  /// children were not hit
  bool hitTestSelf(Point position) => false;

  /// Override this function to check whether any children are located at the
  /// given position
  ///
  /// Typically children should be hit tested in reverse paint order so that
  /// hit tests at locations where children overlap hit the child that is
  /// visually "on top" (i.e., paints later).
  bool hitTestChildren(HitTestResult result, { Point position }) => false;

  /// Multiply the transform from the parent's coordinate system to this box's
  /// coordinate system into the given transform
  ///
  /// This function is used to convert coordinate systems between boxes.
  /// Subclasses that apply transforms during painting should override this
  /// function to factor those transforms into the calculation.
  void applyPaintTransform(Matrix4 transform) {
    if (parentData is BoxParentData) {
      Point position = (parentData as BoxParentData).position;
      transform.translate(position.x, position.y);
    }
  }

  static Point _transformPoint(Matrix4 transform, Point point) {
    Vector3 position3 = new Vector3(point.x, point.y, 0.0);
    Vector3 transformed3 = transform.transform3(position3);
    return new Point(transformed3.x, transformed3.y);
  }

  /// Convert the given point from the global coodinate system to the local
  /// coordinate system for this box
  Point globalToLocal(Point point) {
    assert(attached);
    Matrix4 transform = new Matrix4.identity();
    RenderObject renderer = this;
    while (renderer != null) {
      renderer.applyPaintTransform(transform);
      renderer = renderer.parent;
    }
    /* double det = */ transform.invert();
    // TODO(abarth): Check the determinant for degeneracy.
    return _transformPoint(transform, point);
  }

  /// Convert the given point from the local coordiante system for this box to
  /// the global coordinate sytem
  Point localToGlobal(Point point) {
    List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this; renderer != null; renderer = renderer.parent)
      renderers.add(renderer);
    Matrix4 transform = new Matrix4.identity();
    for (RenderObject renderer in renderers.reversed)
      renderer.applyPaintTransform(transform);
    return _transformPoint(transform, point);
  }

  /// Returns a rectangle that contains all the pixels painted by this box
  ///
  /// The paint bounds can be larger or smaller than [size], which is the amount
  /// of space this box takes up during layout. For example, if this box casts a
  /// shadow, that shadow might extend beyond the space allocated to this box
  /// during layout.
  ///
  /// The paint bounds are used to size the buffers into which this box paints.
  /// If the box attempts to paints outside its paint bounds, there might not be
  /// enough memory allocated to represent the box's visual appearance, which
  /// can lead to undefined behavior.
  ///
  /// The returned paint bounds are in the local coordinate system of this box.
  Rect get paintBounds => Point.origin & size;

  int _debugActivePointers = 0;
  void handleEvent(InputEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    assert(() {
      if (debugPaintPointersEnabled) {
        if (event.type == 'pointerdown')
          _debugActivePointers += 1;
        if (event.type == 'pointerup' || event.type == 'pointercancel')
          _debugActivePointers -= 1;
        markNeedsPaint();
      }
      return true;
    });
  }

  void debugPaint(PaintingContext context, Offset offset) {
    if (debugPaintSizeEnabled)
      debugPaintSize(context, offset);
    if (debugPaintBaselinesEnabled)
      debugPaintBaselines(context, offset);
    if (debugPaintPointersEnabled)
      debugPaintPointers(context, offset);
  }
  void debugPaintSize(PaintingContext context, Offset offset) {
    Paint paint = new Paint()
     ..style = ui.PaintingStyle.stroke
     ..strokeWidth = 1.0
     ..color = debugPaintSizeColor;
    context.canvas.drawRect(offset & size, paint);
  }
  void debugPaintBaselines(PaintingContext context, Offset offset) {
    Paint paint = new Paint()
     ..style = ui.PaintingStyle.stroke
     ..strokeWidth = 0.25;
    Path path;
    // ideographic baseline
    double baselineI = getDistanceToBaseline(TextBaseline.ideographic, onlyReal: true);
    if (baselineI != null) {
      paint.color = debugPaintIdeographicBaselineColor;
      path = new Path();
      path.moveTo(offset.dx, offset.dy + baselineI);
      path.lineTo(offset.dx + size.width, offset.dy + baselineI);
      context.canvas.drawPath(path, paint);
    }
    // alphabetic baseline
    double baselineA = getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);
    if (baselineA != null) {
      paint.color = debugPaintAlphabeticBaselineColor;
      path = new Path();
      path.moveTo(offset.dx, offset.dy + baselineA);
      path.lineTo(offset.dx + size.width, offset.dy + baselineA);
      context.canvas.drawPath(path, paint);
    }
  }
  void debugPaintPointers(PaintingContext context, Offset offset) {
    if (_debugActivePointers > 0) {
      Paint paint = new Paint()
       ..color = new Color(debugPaintPointersColorValue | ((0x04000000 * depth) & 0xFF000000));
      context.canvas.drawRect(offset & size, paint);
    }
  }

  void debugDescribeSettings(List<String> settings) {
    super.debugDescribeSettings(settings);
    settings.add('size: ${ hasSize ? size : "MISSING" }');
  }
}

/// A mixin that provides useful default behaviors for boxes with children
/// managed by the [ContainerRenderObjectMixin] mixin.
///
/// By convention, this class doesn't override any members of the superclass.
/// Instead, it provides helpful functions that subclasses can call as
/// appropriate.
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerBoxParentDataMixin<ChildType>> implements ContainerRenderObjectMixin<ChildType, ParentDataType> {

  /// Returns the baseline of the first child with a baseline
  ///
  /// Useful when the children are displayed vertically in the same order they
  /// appear in the child list.
  double defaultComputeDistanceToFirstActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    RenderBox child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      double result = child.getDistanceToActualBaseline(baseline);
      if (result != null)
        return result + childParentData.position.y;
      child = childParentData.nextSibling;
    }
    return null;
  }

  /// Returns the minimum baseline value among every child
  ///
  /// Useful when the vertical position of the children isn't determined by the
  /// order in the child list.
  double defaultComputeDistanceToHighestActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    double result;
    RenderBox child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      double candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += childParentData.position.y;
        if (result != null)
          result = math.min(result, candidate);
        else
          result = candidate;
      }
      child = childParentData.nextSibling;
    }
    return result;
  }

  /// Performs a hit test on each child by walking the child list backwards
  ///
  /// Stops walking once after the first child reports that it contains the
  /// given point. Returns whether any children contain the given point.
  bool defaultHitTestChildren(HitTestResult result, { Point position }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      Point transformed = new Point(position.x - childParentData.position.x,
                                    position.y - childParentData.position.y);
      if (child.hitTest(result, position: transformed))
        return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  /// Paints each child by walking the child list forwards
  void defaultPaint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }
}

class AnimatedFractionalOffsetValue extends AnimatedValue<FractionalOffset> {
  AnimatedFractionalOffsetValue(FractionalOffset begin, { FractionalOffset end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  FractionalOffset lerp(double t) => FractionalOffset.lerp(begin, end, t);
}
