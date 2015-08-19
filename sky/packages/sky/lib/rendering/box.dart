// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/base/debug.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/object.dart';
import 'package:vector_math/vector_math.dart';

export 'package:sky/painting/text_style.dart' show TextBaseline;

// GENERIC BOX RENDERING
// Anything that has a concept of x, y, width, height is going to derive from this

// This class should only be used in debug builds
class _DebugSize extends Size {
  _DebugSize(Size source, this._owner, this._canBeUsedByParent): super.copy(source);
  final RenderBox _owner;
  final bool _canBeUsedByParent;
}

class BoxConstraints extends Constraints {
  const BoxConstraints({
    this.minWidth: 0.0,
    this.maxWidth: double.INFINITY,
    this.minHeight: 0.0,
    this.maxHeight: double.INFINITY
  });

  BoxConstraints.tight(Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  const BoxConstraints.tightFor({
    double width,
    double height
  }): minWidth = width != null ? width : 0.0,
      maxWidth = width != null ? width : double.INFINITY,
      minHeight = height != null ? height : 0.0,
      maxHeight = height != null ? height : double.INFINITY;

  BoxConstraints.loose(Size size)
    : minWidth = 0.0,
      maxWidth = size.width,
      minHeight = 0.0,
      maxHeight = size.height;

  const BoxConstraints.expandWidth({
    this.maxHeight: double.INFINITY
  }): minWidth = double.INFINITY,
      maxWidth = double.INFINITY,
      minHeight = 0.0;

  const BoxConstraints.expandHeight({
    this.maxWidth: double.INFINITY
  }): minWidth = 0.0,
      minHeight = double.INFINITY,
      maxHeight = double.INFINITY;

  static const BoxConstraints expand = const BoxConstraints(
    minWidth: double.INFINITY,
    maxWidth: double.INFINITY,
    minHeight: double.INFINITY,
    maxHeight: double.INFINITY
  );

  BoxConstraints deflate(EdgeDims edges) {
    assert(edges != null);
    double horizontal = edges.left + edges.right;
    double vertical = edges.top + edges.bottom;
    return new BoxConstraints(
      minWidth: math.max(0.0, minWidth - horizontal),
      maxWidth: maxWidth - horizontal,
      minHeight: math.max(0.0, minHeight - vertical),
      maxHeight: maxHeight - vertical
    );
  }

  BoxConstraints loosen() {
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight
    );
  }

  BoxConstraints apply(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: clamp(min: constraints.minWidth, max: constraints.maxWidth, value: minWidth),
      maxWidth: clamp(min: constraints.minWidth, max: constraints.maxWidth, value: maxWidth),
      minHeight: clamp(min: constraints.minHeight, max: constraints.maxHeight, value: minHeight),
      maxHeight: clamp(min: constraints.minHeight, max: constraints.maxHeight, value: maxHeight)
    );
  }

  BoxConstraints applyWidth(double width) {
    return new BoxConstraints(minWidth: math.max(math.min(maxWidth, width), minWidth),
                              maxWidth: math.max(math.min(maxWidth, width), minWidth),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyMinWidth(double newMinWidth) {
    return new BoxConstraints(minWidth: math.max(minWidth, newMinWidth),
                              maxWidth: math.max(maxWidth, newMinWidth),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyMaxWidth(double newMaxWidth) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: math.min(maxWidth, newMaxWidth),
                              minHeight: minHeight,
                              maxHeight: maxHeight);
  }

  BoxConstraints applyHeight(double height) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: math.max(math.min(maxHeight, height), minHeight),
                              maxHeight: math.max(math.min(maxHeight, height), minHeight));
  }

  BoxConstraints applyMinHeight(double newMinHeight) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: math.max(minHeight, newMinHeight),
                              maxHeight: math.max(maxHeight, newMinHeight));
  }

  BoxConstraints applyMaxHeight(double newMaxHeight) {
    return new BoxConstraints(minWidth: minWidth,
                              maxWidth: maxWidth,
                              minHeight: minHeight,
                              maxHeight: math.min(maxHeight, newMaxHeight));
  }

  BoxConstraints widthConstraints() => new BoxConstraints(minWidth: minWidth, maxWidth: maxWidth);

  BoxConstraints heightConstraints() => new BoxConstraints(minHeight: minHeight, maxHeight: maxHeight);

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  double constrainWidth([double width = double.INFINITY]) {
    return clamp(min: minWidth, max: maxWidth, value: width);
  }

  double constrainHeight([double height = double.INFINITY]) {
    return clamp(min: minHeight, max: maxHeight, value: height);
  }

  Size constrain(Size size) {
    Size result = new Size(constrainWidth(size.width), constrainHeight(size.height));
    if (size is _DebugSize)
      result = new _DebugSize(result, size._owner, size._canBeUsedByParent);
    return result;
  }
  Size get biggest => new Size(constrainWidth(), constrainHeight());
  Size get smallest => new Size(constrainWidth(0.0), constrainHeight(0.0));

  bool get isInfinite => maxWidth >= double.INFINITY && maxHeight >= double.INFINITY;

  bool get hasTightWidth => minWidth >= maxWidth;
  bool get hasTightHeight => minHeight >= maxHeight;
  bool get isTight => hasTightWidth && hasTightHeight;

  bool contains(Size size) {
    return (minWidth <= size.width) && (size.width <= math.max(minWidth, maxWidth)) &&
           (minHeight <= size.height) && (size.height <= math.max(minHeight, maxHeight));
  }

  bool operator ==(other) {
    if (identical(this, other))
      return true;
    return other is BoxConstraints &&
           minWidth == other.minWidth &&
           maxWidth == other.maxWidth &&
           minHeight == other.minHeight &&
           maxHeight == other.maxHeight;
  }
  int get hashCode {
    int value = 373;
    value = 37 * value + minWidth.hashCode;
    value = 37 * value + maxWidth.hashCode;
    value = 37 * value + minHeight.hashCode;
    value = 37 * value + maxHeight.hashCode;
    return value;
  }

  String toString() => "BoxConstraints($minWidth<=w<$maxWidth, $minHeight<=h<$maxHeight)";
}

class BoxHitTestEntry extends HitTestEntry {
  const BoxHitTestEntry(HitTestTarget target, this.localPosition) : super(target);
  final Point localPosition;
}

class BoxParentData extends ParentData {
  Point _position = Point.origin;
  Point get position => _position;
  void set position(Point value) {
    assert(RenderObject.debugDoingLayout);
    _position = value;
  }
  String toString() => 'position=$position';
}

abstract class RenderBox extends RenderObject {

  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  // getMinIntrinsicWidth() should return the minimum width that this box could
  // be without failing to render its contents within itself.
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  // getMaxIntrinsicWidth() should return the smallest width beyond which
  // increasing the width never decreases the height.
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(0.0);
  }

  // getMinIntrinsicHeight() should return the minimum height that this box could
  // be without failing to render its contents within itself.
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  // getMaxIntrinsicHeight should return the smallest height beyond which
  // increasing the height never decreases the width.
  // If the layout algorithm used is width-in-height-out, i.e. the height
  // depends on the width and not vice versa, then this will return the same
  // as getMinIntrinsicHeight().
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(0.0);
  }

  Map<TextBaseline, double> _cachedBaselines;
  bool _ancestorUsesBaseline = false;
  static bool _debugDoingBaseline = false;
  static bool _debugSetDoingBaseline(bool value) {
    _debugDoingBaseline = value;
    return true;
  }
  // getDistanceToBaseline() returns the distance from the
  // y-coordinate of the position of the box to the y-coordinate of
  // the first given baseline in the box's contents. This is used by
  // certain layout models to align adjacent boxes on a common
  // baseline, regardless of padding, font size differences, etc. If
  // there is no baseline, and the 'onlyReal' argument was not set to
  // true, then it returns the distance from the y-coordinate of the
  // position of the box to the y-coordinate of the bottom of the box,
  // i.e., the height of the box. Only call this after layout has been
  // performed. You are only allowed to call this from the parent of
  // this node during that parent's performLayout() or paint().
  double getDistanceToBaseline(TextBaseline baseline, { bool onlyReal: false }) {
    assert(!needsLayout);
    assert(!_debugDoingBaseline);
    final parent = this.parent; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(parent is RenderObject);
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
    assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
    if (result == null && !onlyReal)
      return size.height;
    return result;
  }
  // getDistanceToActualBaseline() must only be called from
  // getDistanceToBaseline() and computeDistanceToActualBaseline(). Do
  // not call it directly from outside those two methods. It just
  // calls computeDistanceToActualBaseline() and caches the result.
  double getDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
    _ancestorUsesBaseline = true;
    if (_cachedBaselines == null)
      _cachedBaselines = new Map<TextBaseline, double>();
    _cachedBaselines.putIfAbsent(baseline, () => computeDistanceToActualBaseline(baseline));
    return _cachedBaselines[baseline];
  }
  // computeDistanceToActualBaseline() should return the distance from
  // the y-coordinate of the position of the box to the y-coordinate
  // of the first given baseline in the box's contents, if any, or
  // null otherwise. This is the method that you should override in
  // subclasses. This method (computeDistanceToActualBaseline())
  // should not be called directly. Use getDistanceToBaseline() if you
  // need to know the baseline of a child from performLayout(). If you
  // need the baseline during paint, cache it during performLayout().
  // Use getDistanceToActualBaseline() if you are implementing
  // computeDistanceToActualBaseline() and need to defer to a child.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
    return null;
  }

  BoxConstraints get constraints => super.constraints;
  bool debugDoesMeetConstraints() {
    assert(constraints != null);
    assert(_size != null);
    assert(!_size.isInfinite);
    bool result = constraints.contains(_size);
    if (!result)
      print("${this.runtimeType} does not meet its constraints. Constraints: $constraints, size: $_size");
    return result;
  }

  void markNeedsLayout() {
    if (_cachedBaselines != null && _cachedBaselines.isNotEmpty) {
      // if we have cached data, then someone must have used our data
      assert(_ancestorUsesBaseline);
      final parent = this.parent; // TODO(ianh): Remove this once the analyzer is cleverer
      assert(parent is RenderObject);
      parent.markNeedsLayout();
      assert(parent == this.parent); // TODO(ianh): Remove this once the analyzer is cleverer
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

  bool hitTest(HitTestResult result, { Point position }) {
    if (position.x >= 0.0 && position.x < _size.width &&
        position.y >= 0.0 && position.y < _size.height) {
      hitTestChildren(result, position: position);
      result.add(new BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
  void hitTestChildren(HitTestResult result, { Point position }) { }

  // TODO(ianh): move size up to before constraints
  // TODO(ianh): In non-debug builds, this should all just be:
  // Size size = Size.zero;
  // In debug builds, however:
  Size _size = Size.zero;
  Size get size {
    if (_size is _DebugSize) {
      final _DebugSize _size = this._size; // TODO(ianh): Remove this once the analyzer is cleverer
      assert(_size._owner == this);
      if (RenderObject.debugActiveLayout != null) {
        // we are always allowed to access our own size (for print debugging and asserts if nothing else)
        // other than us, the only object that's allowed to read our size is our parent, if they're said they will
        // if you hit this assert trying to access a child's size, pass parentUsesSize: true in layout()
        assert(debugDoingThisResize || debugDoingThisLayout ||
               (RenderObject.debugActiveLayout == parent && _size._canBeUsedByParent));
      }
      assert(_size == this._size); // TODO(ianh): Remove this once the analyzer is cleverer
    }
    return _size;
  }
  void set size(Size value) {
    assert((sizedByParent && debugDoingThisResize) ||
           (!sizedByParent && debugDoingThisLayout));
    if (value is _DebugSize) {
      assert(value._canBeUsedByParent);
      assert(value._owner.parent == this);
    }
    _size = inDebugBuild ? new _DebugSize(value, this, debugCanParentUseSize) : value;
  }

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

  Point globalToLocal(Point point) {
    assert(attached);
    Matrix4 transform = new Matrix4.identity();
    RenderObject renderer = this;
    while(renderer != null) {
      renderer.applyPaintTransform(transform);
      renderer = renderer.parent;
    }
    /* double det = */ transform.invert();
    // TODO(abarth): Check the determinant for degeneracy.
    return _transformPoint(transform, point);
  }

  Point localToGlobal(Point point) {
    List <RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this; renderer != null; renderer = renderer.parent)
      renderers.add(renderer);
    Matrix4 transform = new Matrix4.identity();
    for (RenderObject renderer in renderers.reversed)
      renderer.applyPaintTransform(transform);
    return _transformPoint(transform, point);
  }

  Rect get paintBounds => Point.origin & size;
  void debugPaint(PaintingContext context, Offset offset) {
    if (debugPaintSizeEnabled)
      debugPaintSize(context, offset);
    if (debugPaintBaselinesEnabled)
      debugPaintBaselines(context, offset);
  }
  void debugPaintSize(PaintingContext context, Offset offset) {
    Paint paint = new Paint();
    paint.setStyle(sky.PaintingStyle.stroke);
    paint.strokeWidth = 1.0;
    paint.color = debugPaintSizeColor;
    context.canvas.drawRect(offset & size, paint);
  }
  void debugPaintBaselines(PaintingContext context, Offset offset) {
    Paint paint = new Paint();
    paint.setStyle(sky.PaintingStyle.stroke);
    paint.strokeWidth = 0.25;
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

  String debugDescribeSettings(String prefix) => '${super.debugDescribeSettings(prefix)}${prefix}size: ${size}\n';
}


// HELPER METHODS FOR RENDERBOX CONTAINERS
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerParentDataMixin<ChildType>> implements ContainerRenderObjectMixin<ChildType, ParentDataType> {

  // This class, by convention, doesn't override any members of the superclass.
  // It only provides helper functions that subclasses can call.

  double defaultComputeDistanceToFirstActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      double result = child.getDistanceToActualBaseline(baseline);
      if (result != null)
        return result + child.parentData.position.y;
      child = child.parentData.nextSibling;
    }
    return null;
  }

  double defaultComputeDistanceToHighestActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    double result;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      double candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += child.parentData.position.y;
        if (result != null)
          result = math.min(result, candidate);
        else
          result = candidate;
      }
      child = child.parentData.nextSibling;
    }
    return result;
  }

  void defaultHitTestChildren(HitTestResult result, { Point position }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      Point transformed = new Point(position.x - child.parentData.position.x,
                                    position.y - child.parentData.position.y);
      if (child.hitTest(result, position: transformed))
        break;
      child = child.parentData.previousSibling;
    }
  }

  void defaultPaint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is ParentDataType);
      context.paintChild(child, child.parentData.position + offset);
      child = child.parentData.nextSibling;
    }
  }
}
