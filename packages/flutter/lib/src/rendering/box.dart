// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'object.dart';

// This class should only be used in debug builds
class _DebugSize extends Size {
  _DebugSize(Size source, this._owner, this._canBeUsedByParent): super.copy(source);
  final RenderBox _owner;
  final bool _canBeUsedByParent;
}

/// Immutable layout constraints for box layout.
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
/// [double.INFINITY] is a legal value for each constraint.
class BoxConstraints extends Constraints {
  /// Creates box constraints with the given constraints.
  const BoxConstraints({
    this.minWidth: 0.0,
    this.maxWidth: double.INFINITY,
    this.minHeight: 0.0,
    this.maxHeight: double.INFINITY
  });

  /// The minimum width that satisfies the constraints.
  final double minWidth;

  /// The maximum width that satisfies the constraints.
  ///
  /// Might be [double.INFINITY].
  final double maxWidth;

  /// The minimum height that satisfies the constraints.
  final double minHeight;

  /// The maximum height that satisfies the constraints.
  ///
  /// Might be [double.INFINITY].
  final double maxHeight;

  /// Creates box constraints that is respected only by the given size.
  BoxConstraints.tight(Size size)
    : minWidth = size.width,
      maxWidth = size.width,
      minHeight = size.height,
      maxHeight = size.height;

  /// Creates box constraints that require the given width or height.
  const BoxConstraints.tightFor({
    double width,
    double height
  }): minWidth = width != null ? width : 0.0,
      maxWidth = width != null ? width : double.INFINITY,
      minHeight = height != null ? height : 0.0,
      maxHeight = height != null ? height : double.INFINITY;

  /// Creates box constraints that require the given width or height, except if they are infinite.
  const BoxConstraints.tightForFinite({
    double width: double.INFINITY,
    double height: double.INFINITY
  }): minWidth = width != double.INFINITY ? width : 0.0,
      maxWidth = width != double.INFINITY ? width : double.INFINITY,
      minHeight = height != double.INFINITY ? height : 0.0,
      maxHeight = height != double.INFINITY ? height : double.INFINITY;

  /// Creates box constraints that forbid sizes larger than the given size.
  BoxConstraints.loose(Size size)
    : minWidth = 0.0,
      maxWidth = size.width,
      minHeight = 0.0,
      maxHeight = size.height;

  /// Creates box constraints that expand to fill another box contraints.
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

  /// Creates a copy of this box constraints but with the given fields replaced with the new values.
  BoxConstraints copyWith({
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight
  }) {
    return new BoxConstraints(
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight
    );
  }

  /// Returns new box constraints that are smaller by the given edge dimensions.
  BoxConstraints deflate(EdgeInsets edges) {
    assert(edges != null);
    assert(debugAssertIsValid());
    final double horizontal = edges.horizontal;
    final double vertical = edges.vertical;
    final double deflatedMinWidth = math.max(0.0, minWidth - horizontal);
    final double deflatedMinHeight = math.max(0.0, minHeight - vertical);
    return new BoxConstraints(
      minWidth: deflatedMinWidth,
      maxWidth: math.max(deflatedMinWidth, maxWidth - horizontal),
      minHeight: deflatedMinHeight,
      maxHeight: math.max(deflatedMinHeight, maxHeight - vertical)
    );
  }

  /// Returns new box constraints that remove the minimum width and height requirements.
  BoxConstraints loosen() {
    assert(debugAssertIsValid());
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight
    );
  }

  /// Returns new box constraints that respect the given constraints while being
  /// as close as possible to the original constraints.
  BoxConstraints enforce(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: minWidth.clamp(constraints.minWidth, constraints.maxWidth),
      maxWidth: maxWidth.clamp(constraints.minWidth, constraints.maxWidth),
      minHeight: minHeight.clamp(constraints.minHeight, constraints.maxHeight),
      maxHeight: maxHeight.clamp(constraints.minHeight, constraints.maxHeight)
    );
  }

  /// Returns new box constraints with a tight width and/or height as close to
  /// the given width and height as possible while still respecting the original
  /// box constraints.
  BoxConstraints tighten({ double width, double height }) {
    return new BoxConstraints(minWidth: width == null ? minWidth : width.clamp(minWidth, maxWidth),
                              maxWidth: width == null ? maxWidth : width.clamp(minWidth, maxWidth),
                              minHeight: height == null ? minHeight : height.clamp(minHeight, maxHeight),
                              maxHeight: height == null ? maxHeight : height.clamp(minHeight, maxHeight));
  }

  /// A box constraints with the width and height constraints flipped.
  BoxConstraints get flipped {
    return new BoxConstraints(
      minWidth: minHeight,
      maxWidth: maxHeight,
      minHeight: minWidth,
      maxHeight: maxWidth
    );
  }

  /// Returns box constraints with the same width constraints but with
  /// unconstrained height.
  BoxConstraints widthConstraints() => new BoxConstraints(minWidth: minWidth, maxWidth: maxWidth);

  /// Returns box constraints with the same height constraints but with
  /// unconstrained width
  BoxConstraints heightConstraints() => new BoxConstraints(minHeight: minHeight, maxHeight: maxHeight);

  /// Returns the width that both satisfies the constraints and is as close as
  /// possible to the given width.
  double constrainWidth([double width = double.INFINITY]) {
    assert(debugAssertIsValid());
    return width.clamp(minWidth, maxWidth);
  }

  /// Returns the height that both satisfies the constraints and is as close as
  /// possible to the given height.
  double constrainHeight([double height = double.INFINITY]) {
    assert(debugAssertIsValid());
    return height.clamp(minHeight, maxHeight);
  }

  /// Returns the size that both satisfies the constraints and is as close as
  /// possible to the given size.
  Size constrain(Size size) {
    Size result = new Size(constrainWidth(size.width), constrainHeight(size.height));
    assert(() {
      if (size is _DebugSize)
        result = new _DebugSize(result, size._owner, size._canBeUsedByParent);
      return true;
    });
    return result;
  }

  /// Returns a size that attempts to meet the following conditions, in order:
  ///
  ///  - The size must satisfy these constraints.
  ///  - The aspect ratio of the returned size matches the aspect ratio of the
  ///    given size.
  ///  - The returned size as big as possible while still being equal to or
  ///    smaller than the given size.
  Size constrainSizeAndAttemptToPreserveAspectRatio(Size size) {
    if (isTight)
      return smallest;

    double width = size.width;
    double height = size.height;
    assert(width > 0.0);
    assert(height > 0.0);
    double aspectRatio = width / height;

    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspectRatio;
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    if (width < minWidth) {
      width = minWidth;
      height = width / aspectRatio;
    }

    if (height < minHeight) {
      height = minHeight;
      width = height * aspectRatio;
    }

    return new Size(constrainWidth(width), constrainHeight(height));
  }

  /// The biggest size that satisifes the constraints.
  Size get biggest => new Size(constrainWidth(), constrainHeight());

  /// The smallest size that satisfies the constraints.
  Size get smallest => new Size(constrainWidth(0.0), constrainHeight(0.0));

  /// Whether there is exactly one width value that satisfies the constraints.
  bool get hasTightWidth => minWidth >= maxWidth;

  /// Whether there is exactly one height value that satisfies the constraints.
  bool get hasTightHeight => minHeight >= maxHeight;

  /// Whether there is exactly one size that satifies the constraints.
  @override
  bool get isTight => hasTightWidth && hasTightHeight;

  /// Whether there is an upper bound on the maximum width.
  bool get hasBoundedWidth => maxWidth < double.INFINITY;

  /// Whether there is an upper bound on the maximum height.
  bool get hasBoundedHeight => maxHeight < double.INFINITY;

  /// Whether the given size satisfies the constraints.
  bool isSatisfiedBy(Size size) {
    assert(debugAssertIsValid());
    return (minWidth <= size.width) && (size.width <= maxWidth) &&
           (minHeight <= size.height) && (size.height <= maxHeight);
  }

  /// Scales each constraint parameter by the given factor.
  BoxConstraints operator*(double factor) {
    return new BoxConstraints(
      minWidth: minWidth * factor,
      maxWidth: maxWidth * factor,
      minHeight: minHeight * factor,
      maxHeight: maxHeight * factor
    );
  }

  /// Scales each constraint parameter by the inverse of the given factor.
  BoxConstraints operator/(double factor) {
    return new BoxConstraints(
      minWidth: minWidth / factor,
      maxWidth: maxWidth / factor,
      minHeight: minHeight / factor,
      maxHeight: maxHeight / factor
    );
  }

  /// Scales each constraint parameter by the inverse of the given factor, rounded to the nearest integer.
  BoxConstraints operator~/(double factor) {
    return new BoxConstraints(
      minWidth: (minWidth ~/ factor).toDouble(),
      maxWidth: (maxWidth ~/ factor).toDouble(),
      minHeight: (minHeight ~/ factor).toDouble(),
      maxHeight: (maxHeight ~/ factor).toDouble()
    );
  }

  /// Computes the remainder of each constraint parameter by the given value.
  BoxConstraints operator%(double value) {
    return new BoxConstraints(
      minWidth: minWidth % value,
      maxWidth: maxWidth % value,
      minHeight: minHeight % value,
      maxHeight: maxHeight % value
    );
  }

  /// Linearly interpolate between two BoxConstraints.
  ///
  /// If either is null, this function interpolates from [BoxConstraints.zero].
  static BoxConstraints lerp(BoxConstraints a, BoxConstraints b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    assert(a.debugAssertIsValid());
    assert(b.debugAssertIsValid());
    return new BoxConstraints(
      minWidth: ui.lerpDouble(a.minWidth, b.minWidth, t),
      maxWidth: ui.lerpDouble(a.maxWidth, b.maxWidth, t),
      minHeight: ui.lerpDouble(a.minHeight, b.minHeight, t),
      maxHeight: ui.lerpDouble(a.maxHeight, b.maxHeight, t)
    );
  }

  /// Returns whether the object's constraints are normalized.
  /// Constraints are normalised if the minimums are less than or
  /// equal to the corresponding maximums.
  ///
  /// For example, a BoxConstraints object with a minWidth of 100.0
  /// and a maxWidth of 90.0 is not normalized.
  ///
  /// Most of the APIs on BoxConstraints expect the constraints to be
  /// normalized and have undefined behavior when they are not. In
  /// checked mode, many of these APIs will assert if the constraints
  /// are not normalized.
  @override
  bool get isNormalized {
    return minWidth >= 0.0 &&
           minWidth <= maxWidth &&
           minHeight >= 0.0 &&
           minHeight <= maxHeight;
  }

  @override
  bool debugAssertIsValid({
    bool isAppliedConstraint: false,
    InformationCollector informationCollector
  }) {
    assert(() {
      void throwError(String message) {
        StringBuffer information = new StringBuffer();
        if (informationCollector != null)
          informationCollector(information);
        throw new FlutterError('$message\n${information}The offending constraints were:\n  $this');
      }
      if (minWidth.isNaN || maxWidth.isNaN || minHeight.isNaN || maxHeight.isNaN) {
        List<String> affectedFieldsList = <String>[];
        if (minWidth.isNaN)
          affectedFieldsList.add('minWidth');
        if (maxWidth.isNaN)
          affectedFieldsList.add('maxWidth');
        if (minHeight.isNaN)
          affectedFieldsList.add('minHeight');
        if (maxHeight.isNaN)
          affectedFieldsList.add('maxHeight');
        assert(affectedFieldsList.length > 0);
        if (affectedFieldsList.length > 1)
          affectedFieldsList.add('and ${affectedFieldsList.removeLast()}');
        String whichFields = '';
        if (affectedFieldsList.length > 2) {
          whichFields = affectedFieldsList.join(', ');
        } else if (affectedFieldsList.length == 2) {
          whichFields = affectedFieldsList.join(' ');
        } else {
          whichFields = affectedFieldsList.single;
        }
        throwError('BoxConstraints has ${affectedFieldsList.length == 1 ? 'a NaN value' : 'NaN values' } in $whichFields.');
      }
      if (minWidth < 0.0 && minHeight < 0.0)
        throwError('BoxConstraints has both a negative minimum width and a negative minimum height.');
      if (minWidth < 0.0)
        throwError('BoxConstraints has a negative minimum width.');
      if (minHeight < 0.0)
        throwError('BoxConstraints has a negative minimum height.');
      if (maxWidth < minWidth && maxHeight < minHeight)
        throwError('BoxConstraints has both width and height constraints non-normalized.');
      if (maxWidth < minWidth)
        throwError('BoxConstraints has non-normalized width constraints.');
      if (maxHeight < minHeight)
        throwError('BoxConstraints has non-normalized height constraints.');
      if (isAppliedConstraint) {
        if (minWidth.isInfinite && minHeight.isInfinite)
          throwError('BoxConstraints forces an infinite width and infinite height.');
        if (minWidth.isInfinite)
          throwError('BoxConstraints forces an infinite width.');
        if (minHeight.isInfinite)
          throwError('BoxConstraints forces an infinite height.');
      }
      assert(isNormalized);
      return true;
    });
    return isNormalized;
  }

  /// Returns a box constraints that [isNormalized].
  ///
  /// The returned [maxWidth] is at least as large as the [minWidth]. Similarly,
  /// the returned [maxHeight] is at least as large as the [minHeight].
  BoxConstraints normalize() {
    if (isNormalized)
      return this;
    final double minWidth = this.minWidth >= 0.0 ? this.minWidth : 0.0;
    final double minHeight = this.minHeight >= 0.0 ? this.minHeight : 0.0;
    return new BoxConstraints(
      minWidth: minWidth,
      maxWidth: minWidth > maxWidth ? minWidth : maxWidth,
      minHeight: minHeight,
      maxHeight: minHeight > maxHeight ? minHeight : maxHeight
    );
  }

  @override
  bool operator ==(dynamic other) {
    assert(debugAssertIsValid());
    if (identical(this, other))
      return true;
    if (other is! BoxConstraints)
      return false;
    final BoxConstraints typedOther = other;
    assert(typedOther.debugAssertIsValid());
    return minWidth == typedOther.minWidth &&
           maxWidth == typedOther.maxWidth &&
           minHeight == typedOther.minHeight &&
           maxHeight == typedOther.maxHeight;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return hashValues(minWidth, maxWidth, minHeight, maxHeight);
  }

  @override
  String toString() {
    String annotation = isNormalized ? '' : '; NOT NORMALIZED';
    if (minWidth == double.INFINITY && minHeight == double.INFINITY)
      return 'BoxConstraints(biggest$annotation)';
    if (minWidth == 0 && maxWidth == double.INFINITY &&
        minHeight == 0 && maxHeight == double.INFINITY)
      return 'BoxConstraints(unconstrained$annotation)';
    String describe(double min, double max, String dim) {
      if (min == max)
        return '$dim=${min.toStringAsFixed(1)}';
      return '${min.toStringAsFixed(1)}<=$dim<=${max.toStringAsFixed(1)}';
    }
    final String width = describe(minWidth, maxWidth, 'w');
    final String height = describe(minHeight, maxHeight, 'h');
    return 'BoxConstraints($width, $height$annotation)';
  }
}

/// A hit test entry used by [RenderBox].
class BoxHitTestEntry extends HitTestEntry {
  /// Creates a box hit test entry.
  ///
  /// The [localPosition] argument must not be null.
  const BoxHitTestEntry(RenderBox target, this.localPosition) : super(target);

  @override
  RenderBox get target => super.target;

  /// The position of the hit test in the local coordinates of [target].
  final Point localPosition;

  @override
  String toString() => '${target.runtimeType}@$localPosition';
}

/// Parent data used by [RenderBox] and its subclasses.
class BoxParentData extends ParentData {
  /// The offset at which to paint the child in the parent's coordinate system.
  Offset offset = Offset.zero;

  @override
  String toString() => 'offset=$offset';
}

/// Abstract ParentData subclass for RenderBox subclasses that want the
/// ContainerRenderObjectMixin.
abstract class ContainerBoxParentDataMixin<ChildType extends RenderObject> extends BoxParentData with ContainerParentDataMixin<ChildType> { }

enum _IntrinsicDimension { minWidth, maxWidth, minHeight, maxHeight }
class _IntrinsicDimensionsCacheEntry {
  _IntrinsicDimensionsCacheEntry(this.dimension, this.argument);

  final _IntrinsicDimension dimension;
  final double argument;

  @override
  bool operator ==(dynamic other) {
    if (other is! _IntrinsicDimensionsCacheEntry)
      return false;
    final _IntrinsicDimensionsCacheEntry typedOther = other;
    return dimension == typedOther.dimension &&
           argument == typedOther.argument;
  }

  @override
  int get hashCode => hashValues(dimension, argument);
}

/// A render object in a 2D cartesian coordinate system.
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
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData)
      child.parentData = new BoxParentData();
  }

  Map<_IntrinsicDimensionsCacheEntry, double> _cachedIntrinsicDimensions;

  double _computeIntrinsicDimension(_IntrinsicDimension dimension, double argument, double computer(double argument)) {
    assert(RenderObject.debugCheckingIntrinsics || !debugDoingThisResize); // performResize should not depend on anything except the incoming constraints
    bool shouldCache = true;
    assert(() {
      // we don't want the checked-mode intrinsic tests to affect
      // who gets marked dirty, etc.
      if (RenderObject.debugCheckingIntrinsics)
        shouldCache = false;
      return true;
    });
    if (shouldCache) {
      _cachedIntrinsicDimensions ??= <_IntrinsicDimensionsCacheEntry, double>{};
      return _cachedIntrinsicDimensions.putIfAbsent(
        new _IntrinsicDimensionsCacheEntry(dimension, argument),
        () => computer(argument)
      );
    }
    return computer(argument);
  }

  /// Returns the minimum width that this box could be without failing to
  /// correctly paint its contents within itself, without clipping.
  ///
  /// The height argument may give a specific height to assume. The given height
  /// can be infinite, meaning that the intrinsic width in an unconstrained
  /// environment is being requested. The given height should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive and as it can result in O(N^2)
  /// behavior.
  ///
  /// Do not override this method. Instead, implement [computeMinIntrinsicWidth].
  @mustCallSuper
  double getMinIntrinsicWidth(double height) {
    assert(() {
      if (height == null) {
        throw new FlutterError(
          'The height argument to getMinIntrinsicWidth was null.\n'
          'The argument to getMinIntrinsicWidth must not be negative or null. '
          'If you do not have a specific height in mind, then pass double.INFINITY instead.'
        );
      }
      if (height < 0.0) {
        throw new FlutterError(
          'The height argument to getMinIntrinsicWidth was negative.\n'
          'The argument to getMinIntrinsicWidth must not be negative or null. '
          'If you perform computations on another height before passing it to '
          'getMinIntrinsicWidth, consider using math.max() or double.clamp() '
          'to force the value into the valid range.'
        );
      }
      return true;
    });
    return _computeIntrinsicDimension(_IntrinsicDimension.minWidth, height, computeMinIntrinsicWidth);
  }

  /// Computes the value returned by [getMinIntrinsicWidth]. Do not call this
  /// function directly, instead, call [getMinIntrinsicWidth].
  ///
  /// Override in subclasses that implement [performLayout]. This method should
  /// return the minimum width that this box could be without failing to
  /// correctly paint its contents within itself, without clipping.
  ///
  /// If the layout algorithm is independent of the context (e.g. it always
  /// tries to be a particular size), or if the layout algorithm is
  /// width-in-height-out, or if the layout algorithm uses both the incoming
  /// width and height constraints (e.g. it always sizes itself to
  /// [BoxConstraints.biggest]), then the `height` argument should be ignored.
  ///
  /// If the layout algorithm is strictly height-in-width-out, or is
  /// height-in-width-out when the width is unconstrained, then the height
  /// argument is the height to use.
  ///
  /// The `height` argument will never be negative or null. It may be infinite.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// ## Examples
  ///
  /// ### Text
  ///
  /// Text is the canonical example of a width-in-height-out algorithm. The
  /// `height` argument is therefore ignored.
  ///
  /// Consider the string "Hello World" The _maximum_ intrinsic width (as
  /// returned from [computeMaxIntrinsicWidth]) would be the width of the string
  /// with no line breaks.
  ///
  /// The minimum intrinsic width would be the width of the widest word, "Hello"
  /// or "World". If the text is rendered in an even narrower width, however, it
  /// might still not overflow. For example, maybe the rendering would put a
  /// line-break half-way through the words, as in "Hel⁞lo⁞Wor⁞ld". However,
  /// this wouldn't be a _correct_ rendering, and [computeMinIntrinsicWidth] is
  /// supposed to render the minimum width that the box could be without failing
  /// to _correctly_ paint the contents within itself.
  ///
  /// The minimum intrinsic _height_ for a given width smaller than the minimum
  /// intrinsic width could therefore be greater than the minimum intrinsic
  /// height for the minimum intrinsic width.
  ///
  /// ### Viewports (e.g. scrolling lists)
  ///
  /// Some render boxes are intended to clip their children. For example, the
  /// render box for a scrolling list might always size itself to its parents'
  /// size (or rather, to the maximum incoming constraints), regardless of the
  /// children's sizes, and then clip the children and position them based on
  /// the current scroll offset.
  ///
  /// The intrinsic dimensions in these cases still depend on the children, even
  /// though the layout algorithm sizes the box in a way independent of the
  /// children. It is the size that is needed to paint the box's contents (in
  /// this case, the children) _without clipping_ that matters.
  ///
  /// In many cases, viewports do not have efficient access to all the children,
  /// and therefore cannot actually return a valid answer. In this case, when
  /// [RenderObject.debugCheckingIntrinsics] is false and asserts are enabled,
  /// the intrinsic functions should throw; in other cases, they should return
  /// 0.0. See [RenderVirtualViewport.debugThrowIfNotCheckingIntrinsics].
  ///
  /// ### Aspect-ratio-driven boxes
  ///
  /// Some boxes always return a fixed size based on the constraints. For these
  /// boxes, the intrinsic functions should return the appropriate size when the
  /// incoming `height` or `width` argument is finite, treating that as a tight
  /// constraint in the respective direction and treating the other direction's
  /// constraints as unbounded. This is because the definitions of
  /// [computeMinIntrinsicWidth] and [computeMinIntrinsicHeight] are in terms of
  /// what the dimensions _could be_, and such boxes can only be one size in
  /// such cases.
  ///
  /// When the incoming argument is not finite, then they should return the
  /// actual intrinsic dimensions based on the contents, as any other box would.
  @protected
  double computeMinIntrinsicWidth(double height) {
    return 0.0;
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the preferred height. The preferred height is the value that
  /// would be returned by [getMinIntrinsicHeight] for that width.
  ///
  /// The height argument may give a specific height to assume. The given height
  /// can be infinite, meaning that the intrinsic width in an unconstrained
  /// environment is being requested. The given height should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive and as it can result in O(N^2)
  /// behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMaxIntrinsicWidth].
  @mustCallSuper
  double getMaxIntrinsicWidth(double height) {
    assert(() {
      if (height == null) {
        throw new FlutterError(
          'The height argument to getMaxIntrinsicWidth was null.\n'
          'The argument to getMaxIntrinsicWidth must not be negative or null. '
          'If you do not have a specific height in mind, then pass double.INFINITY instead.'
        );
      }
      if (height < 0.0) {
        throw new FlutterError(
          'The height argument to getMaxIntrinsicWidth was negative.\n'
          'The argument to getMaxIntrinsicWidth must not be negative or null. '
          'If you perform computations on another height before passing it to '
          'getMaxIntrinsicWidth, consider using math.max() or double.clamp() '
          'to force the value into the valid range.'
        );
      }
      return true;
    });
    return _computeIntrinsicDimension(_IntrinsicDimension.maxWidth, height, computeMaxIntrinsicWidth);
  }

  /// Computes the value returned by [getMaxIntrinsicWidth]. Do not call this
  /// function directly, instead, call [getMaxIntrinsicWidth].
  ///
  /// Override in subclasses that implement [performLayout]. This should return
  /// the smallest width beyond which increasing the width never decreases the
  /// preferred height. The preferred height is the value that would be returned
  /// by [computeMinIntrinsicHeight] for that width.
  ///
  /// If the layout algorithm is strictly height-in-width-out, or is
  /// height-in-width-out when the width is unconstrained, then this should
  /// return the same value as [computeMinIntrinsicWidth] for the same height.
  ///
  /// Otherwise, the height argument should be ignored, and the returned value
  /// should be equal to or bigger than the value returned by
  /// [computeMinIntrinsicWidth].
  ///
  /// The `height` argument will never be negative or null. It may be infinite.
  ///
  /// The value returned by this method might not match the size that the object
  /// would actually take. For example, a [RenderBox] subclass that always
  /// exactly sizes itself using [BoxConstraints.biggest] might well size itself
  /// bigger than its max intrinsic size.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// See also examples in the definition of [computeMinIntrinsicWidth].
  @protected
  double computeMaxIntrinsicWidth(double height) {
    return 0.0;
  }

  /// Returns the minimum height that this box could be without failing to
  /// correctly paint its contents within itself, without clipping.
  ///
  /// The width argument may give a specific width to assume. The given width
  /// can be infinite, meaning that the intrinsic height in an unconstrained
  /// environment is being requested. The given width should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive and as it can result in O(N^2)
  /// behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMinIntrinsicHeight].
  @mustCallSuper
  double getMinIntrinsicHeight(double width) {
    assert(() {
      if (width == null) {
        throw new FlutterError(
          'The width argument to getMinIntrinsicHeight was null.\n'
          'The argument to getMinIntrinsicHeight must not be negative or null. '
          'If you do not have a specific width in mind, then pass double.INFINITY instead.'
        );
      }
      if (width < 0.0) {
        throw new FlutterError(
          'The width argument to getMinIntrinsicHeight was negative.\n'
          'The argument to getMinIntrinsicHeight must not be negative or null. '
          'If you perform computations on another width before passing it to '
          'getMinIntrinsicHeight, consider using math.max() or double.clamp() '
          'to force the value into the valid range.'
        );
      }
      return true;
    });
    return _computeIntrinsicDimension(_IntrinsicDimension.minHeight, width, computeMinIntrinsicHeight);
  }

  /// Computes the value returned by [getMinIntrinsicHeight]. Do not call this
  /// function directly, instead, call [getMinIntrinsicHeight].
  ///
  /// Override in subclasses that implement [performLayout]. Should return the
  /// minimum height that this box could be without failing to correctly paint
  /// its contents within itself, without clipping.
  ///
  /// If the layout algorithm is independent of the context (e.g. it always
  /// tries to be a particular size), or if the layout algorithm is
  /// height-in-width-out, or if the layout algorithm uses both the incoming
  /// height and width constraints (e.g. it always sizes itself to
  /// [BoxConstraints.biggest]), then the `width` argument should be ignored.
  ///
  /// If the layout algorithm is strictly width-in-height-out, or is
  /// width-in-height-out when the height is unconstrained, then the width
  /// argument is the width to use.
  ///
  /// The `width` argument will never be negative or null. It may be infinite.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// See also examples in the definition of [computeMinIntrinsicWidth].
  @protected
  double computeMinIntrinsicHeight(double height) {
    return 0.0;
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the preferred width. The preferred width is the value that
  /// would be returned by [getMinIntrinsicWidth] for that height.
  ///
  /// The width argument may give a specific width to assume. The given width
  /// can be infinite, meaning that the intrinsic height in an unconstrained
  /// environment is being requested. The given width should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive and as it can result in O(N^2)
  /// behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMaxIntrinsicHeight].
  @mustCallSuper
  double getMaxIntrinsicHeight(double width) {
    assert(() {
      if (width == null) {
        throw new FlutterError(
          'The width argument to getMaxIntrinsicHeight was null.\n'
          'The argument to getMaxIntrinsicHeight must not be negative or null. '
          'If you do not have a specific width in mind, then pass double.INFINITY instead.'
        );
      }
      if (width < 0.0) {
        throw new FlutterError(
          'The width argument to getMaxIntrinsicHeight was negative.\n'
          'The argument to getMaxIntrinsicHeight must not be negative or null. '
          'If you perform computations on another width before passing it to '
          'getMaxIntrinsicHeight, consider using math.max() or double.clamp() '
          'to force the value into the valid range.'
        );
      }
      return true;
    });
    return _computeIntrinsicDimension(_IntrinsicDimension.maxHeight, width, computeMaxIntrinsicHeight);
  }

  /// Computes the value returned by [getMaxIntrinsicHeight]. Do not call this
  /// function directly, instead, call [getMaxIntrinsicHeight].
  ///
  /// Override in subclasses that implement [performLayout]. Should return the
  /// smallest height beyond which increasing the height never decreases the
  /// preferred width. The preferred width is the value that would be returned
  /// by [computeMinIntrinsicWidth] for that height.
  ///
  /// If the layout algorithm is strictly width-in-height-out, or is
  /// width-in-height-out when the height is unconstrained, then this should
  /// return the same value as [computeMinIntrinsicHeight] for the same width.
  ///
  /// Otherwise, the width argument should be ignored, and the returned value
  /// should be equal to or bigger than the value returned by
  /// [computeMinIntrinsicHeight].
  ///
  /// The `width` argument will never be negative or null. It may be infinite.
  ///
  /// The value returned by this method might not match the size that the object
  /// would actually take. For example, a [RenderBox] subclass that always
  /// exactly sizes itself using [BoxConstraints.biggest] might well size itself
  /// bigger than its max intrinsic size.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// See also examples in the definition of [computeMinIntrinsicWidth].
  @protected
  double computeMaxIntrinsicHeight(double height) {
    return 0.0;
  }

  /// Whether this render object has undergone layout and has a [size].
  bool get hasSize => _size != null;

  /// The size of this render box computed during layout.
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
  Size _size;
  @protected
  set size(Size value) {
    assert(!(debugDoingThisResize && debugDoingThisLayout));
    assert(sizedByParent || !debugDoingThisResize);
    assert(() {
      if ((sizedByParent && debugDoingThisResize) ||
          (!sizedByParent && debugDoingThisLayout))
        return true;
      assert(!debugDoingThisResize);
      String contract, violation, hint;
      if (debugDoingThisLayout) {
        assert(sizedByParent);
        violation = 'It appears that the size setter was called from performLayout().';
        hint = '';
      } else {
        violation = 'The size setter was called from outside layout (neither performResize() nor performLayout() were being run for this object).';
        if (owner != null && owner.debugDoingLayout)
          hint = 'Only the object itself can set its size. It is a contract violation for other objects to set it.';
      }
      if (sizedByParent)
        contract = 'Because this RenderBox has sizedByParent set to true, it must set its size in performResize().';
      else
        contract = 'Because this RenderBox has sizedByParent set to false, it must set its size in performLayout().';
      throw new FlutterError(
        'RenderBox size setter called incorrectly.\n'
        '$violation\n'
        '$hint\n'
        '$contract\n'
        'The RenderBox in question is:\n'
        '  $this'
      );
    });
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
    assert(() { debugAssertDoesMeetConstraints(); return true; });
  }

  @override
  Rect get semanticBounds => Point.origin & size;

  @override
  void debugResetSize() {
    // updates the value of size._canBeUsedByParent if necessary
    size = size;
  }

  Map<TextBaseline, double> _cachedBaselines;
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
  /// (i.e., the height of the box) unless the caller passes true
  /// for `onlyReal`, in which case the function returns null.
  ///
  /// Only call this function after calling [layout] on this box. You
  /// are only allowed to call this from the parent of this box during
  /// that parent's [performLayout] or [paint] functions.
  double getDistanceToBaseline(TextBaseline baseline, { bool onlyReal: false }) {
    assert(!needsLayout);
    assert(!_debugDoingBaseline);
    assert(() {
      final RenderObject parent = this.parent;
      if (owner.debugDoingLayout)
        return (RenderObject.debugActiveLayout == parent) && parent.debugDoingThisLayout;
      if (owner.debugDoingPaint)
        return ((RenderObject.debugActivePaint == parent) && parent.debugDoingThisPaint) ||
               ((RenderObject.debugActivePaint == this) && debugDoingThisPaint);
      assert(parent == this.parent);
      return false;
    });
    assert(_debugSetDoingBaseline(true));
    double result = getDistanceToActualBaseline(baseline);
    assert(_debugSetDoingBaseline(false));
    if (result == null && !onlyReal)
      return size.height;
    return result;
  }

  /// Calls [computeDistanceToActualBaseline] and caches the result.
  ///
  /// This function must only be called from [getDistanceToBaseline] and
  /// [computeDistanceToActualBaseline]. Do not call this function directly from
  /// outside those two methods.
  @protected
  @mustCallSuper
  double getDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
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
  /// Subclasses should override this method to supply the distances to their
  /// baselines.
  @protected
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline);
    return null;
  }

  /// The box constraints most recently received from the parent.
  @override
  BoxConstraints get constraints => super.constraints;

  // We check the intrinsic sizes of each render box once by default.
  bool _debugNeedsIntrinsicSizeCheck = true;

  @override
  void debugAssertDoesMeetConstraints() {
    assert(constraints != null);
    assert(() {
      if (!hasSize) {
        assert(!needsLayout); // this is called in the size= setter during layout, but in that case we have a size
        String contract;
        if (sizedByParent)
          contract = 'Because this RenderBox has sizedByParent set to true, it must set its size in performResize().\n';
        else
          contract = 'Because this RenderBox has sizedByParent set to false, it must set its size in performLayout().\n';
        throw new FlutterError(
          'RenderBox did not set its size during layout.\n'
          '$contract'
          'It appears that this did not happen; layout completed, but the size property is still null.\n'
          'The RenderBox in question is:\n'
          '  $this'
        );
      }
      // verify that the size is not infinite
      if (_size.isInfinite) {
        StringBuffer information = new StringBuffer();
        if (!constraints.hasBoundedWidth) {
          RenderBox node = this;
          while (!node.constraints.hasBoundedWidth && node.parent is RenderBox)
            node = node.parent;
          information.writeln('The nearest ancestor providing an unbounded width constraint is:');
          information.writeln('  $node');
          List<String> description = <String>[];
          node.debugFillDescription(description);
          for (String line in description)
            information.writeln('  $line');
        }
        if (!constraints.hasBoundedHeight) {
          RenderBox node = this;
          while (!node.constraints.hasBoundedHeight && node.parent is RenderBox)
            node = node.parent;
          information.writeln('The nearest ancestor providing an unbounded height constraint is:');
          information.writeln('  $node');
          List<String> description = <String>[];
          node.debugFillDescription(description);
          for (String line in description)
            information.writeln('  $line');
        }
        throw new FlutterError(
          '$runtimeType object was given an infinite size during layout.\n'
          'This probably means that it is a render object that tries to be '
          'as big as possible, but it was put inside another render object '
          'that allows its children to pick their own size.\n'
          '$information'
          'The constraints that applied to the $runtimeType were:\n'
          '  $constraints\n'
          'The exact size it was given was:\n'
          '  $_size\n'
          'See https://flutter.io/layout/ for more information.'
        );
      }
      // verify that the size is within the constraints
      if (!constraints.isSatisfiedBy(_size)) {
        throw new FlutterError(
          '$runtimeType does not meet its constraints.\n'
          'Constraints: $constraints\n'
          'Size: $_size\n'
          'If you are not writing your own RenderBox subclass, then this is not '
          'your fault. Contact support: https://github.com/flutter/flutter/issues/new'
        );
      }
      if (_debugNeedsIntrinsicSizeCheck || debugCheckIntrinsicSizes) {
        // verify that the intrinsics are sane
        assert(!RenderObject.debugCheckingIntrinsics);
        RenderObject.debugCheckingIntrinsics = true;
        StringBuffer failures = new StringBuffer();
        int failureCount = 0;

        double testIntrinsic(double function(double extent), String name, double constraint) {
          final double result = function(constraint);
          if (result < 0) {
            failures.writeln(' * $name($constraint) returned a negative value: $result');
            failureCount += 1;
          }
          if (!result.isFinite) {
            failures.writeln(' * $name($constraint) returned a non-finite value: $result');
            failureCount += 1;
          }
          return result;
        }

        void testIntrinsicsForValues(double getMin(double extent), double getMax(double extent), String name, double constraint) {
          final double min = testIntrinsic(getMin, 'getMinIntrinsic$name', constraint);
          final double max = testIntrinsic(getMax, 'getMaxIntrinsic$name', constraint);
          if (min > max) {
            failures.writeln(' * getMinIntrinsic$name($constraint) returned a larger value ($min) than getMaxIntrinsic$name($constraint) ($max)');
            failureCount += 1;
          }
        }

        testIntrinsicsForValues(getMinIntrinsicWidth, getMaxIntrinsicWidth, 'Width', double.INFINITY);
        testIntrinsicsForValues(getMinIntrinsicHeight, getMaxIntrinsicHeight, 'Height', double.INFINITY);
        if (constraints.hasBoundedWidth)
          testIntrinsicsForValues(getMinIntrinsicWidth, getMaxIntrinsicWidth, 'Width', constraints.maxWidth);
        if (constraints.hasBoundedHeight)
          testIntrinsicsForValues(getMinIntrinsicHeight, getMaxIntrinsicHeight, 'Height', constraints.maxHeight);

        // TODO(ianh): Test that values are internally consistent in more ways than the above.

        RenderObject.debugCheckingIntrinsics = false;
        _debugNeedsIntrinsicSizeCheck = false;
        if (failures.isNotEmpty) {
          assert(failureCount > 0);
          throw new FlutterError(
            'The intrinsic dimension methods of the $runtimeType class returned values that violate the intrinsic protocol contract.\n'
            'The following ${failureCount > 1 ? "failures" : "failure"} was detected:\n'
            '$failures'
            'If you are not writing your own RenderBox subclass, then this is not\n'
            'your fault. Contact support: https://github.com/flutter/flutter/issues/new'
          );
        }
      }
      return true;
    });
  }

  @override
  void markNeedsLayout() {
    if ((_cachedBaselines != null && _cachedBaselines.isNotEmpty) ||
        (_cachedIntrinsicDimensions != null && _cachedIntrinsicDimensions.isNotEmpty)) {
      // If we have cached data, then someone must have used our data.
      // Since the parent will shortly be marked dirty, we can forget that they
      // used the baseline and/or intrinsic dimensions. If they use them again,
      // then we'll fill the cache again, and if we get dirty again, we'll
      // notify them again.
      _cachedBaselines?.clear();
      _cachedIntrinsicDimensions?.clear();
       if (parent is RenderObject) {
        markParentNeedsLayout();
        return;
      }
    }
    super.markNeedsLayout();
  }

  @override
  void performResize() {
    // default behavior for subclasses that have sizedByParent = true
    size = constraints.constrain(Size.zero);
    assert(!size.isInfinite);
  }

  @override
  void performLayout() {
    assert(() {
      if (!sizedByParent) {
        throw new FlutterError(
          '$runtimeType did not implement performLayout().\n'
          'RenderBox subclasses need to either override performLayout() to '
          'set a size and lay out any children, or, set sizedByParent to true '
          'so that performResize() sizes the render object.'
        );
      }
      return true;
    });
  }

  /// Determines the set of render objects located at the given position.
  ///
  /// Returns true if the given point is contained in this render object or one
  /// of its descendants. Adds any render objects that contain the point to the
  /// given hit test result.
  ///
  /// The caller is responsible for transforming [position] into the local
  /// coordinate space of the callee.  The callee is responsible for checking
  /// whether the given position is within its bounds.
  ///
  /// Hit testing requires layout to be up-to-date but does not require painting
  /// to be up-to-date. That means a render object can rely upon [performLayout]
  /// having been called in [hitTest] but cannot rely upon [paint] having been
  /// called. For example, a render object might be a child of a [RenderOpacity]
  /// object, which calls [hitTest] on its children when its opacity is zero
  /// even through it does not [paint] its children.
  bool hitTest(HitTestResult result, { @required Point position }) {
    assert(() {
      if (needsLayout) {
        throw new FlutterError(
          'Cannot hit test a dirty render box.\n'
          'The hitTest() method was called on this RenderBox:\n'
          '  $this\n'
          'Unfortunately, since this object has been marked as needing layout, its geometry is not known at this time. '
          'This means it cannot be accurately hit-tested. Make sure to only mark nodes as needing layout during a pipeline '
          'flush, so that it is marked clean before any event handling occurs. If you are trying to perform a hit test '
          'during the layout phase itself, make sure you only hit test nodes that have completed layout (e.g. the node\'s '
          'children, after their layout() method has been called).'
        );
      }
      if (!hasSize) {
        throw new FlutterError(
          'Cannot hit test a render box with no size.\n'
          'The hitTest() method was called on this RenderBox:\n'
          '  $this\n'
          'Although this node is not marked as needing layout, its size is not set. A RenderBox object must have an '
          'explicit size before it can be hit-tested. Make sure that the RenderBox in question sets its size during layout.'
        );
      }
      return true;
    });
    if (position.x >= 0.0 && position.x < _size.width &&
        position.y >= 0.0 && position.y < _size.height) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(new BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  /// Override this method if this render object can be hit even if its
  /// children were not hit.
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  @protected
  bool hitTestSelf(Point position) => false;

  /// Override this method to check whether any children are located at the
  /// given position.
  ///
  /// Typically children should be hit tested in reverse paint order so that
  /// hit tests at locations where children overlap hit the child that is
  /// visually "on top" (i.e., paints later).
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  @protected
  bool hitTestChildren(HitTestResult result, { Point position }) => false;

  /// Multiply the transform from the parent's coordinate system to this box's
  /// coordinate system into the given transform.
  ///
  /// This function is used to convert coordinate systems between boxes.
  /// Subclasses that apply transforms during painting should override this
  /// function to factor those transforms into the calculation.
  ///
  /// The RenderBox implementation takes care of adjusting the matrix for the
  /// position of the given child as determined during layout and stored on the
  /// child's [parentData] in the [BoxParentData.offset] field.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child.parent == this);
    BoxParentData childParentData = child.parentData;
    Offset offset = childParentData.offset;
    transform.translate(offset.dx, offset.dy);
  }

  Matrix4 _collectPaintTransform() {
    assert(attached);
    final List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this; renderer != null; renderer = renderer.parent)
      renderers.add(renderer);
    final Matrix4 transform = new Matrix4.identity();
    for (int index = renderers.length - 1; index > 0; index -= 1)
      renderers[index].applyPaintTransform(renderers[index - 1], transform);
    return transform;
  }

  /// Convert the given point from the global coodinate system to the local
  /// coordinate system for this box.
  ///
  /// If the transform from global coordinates to local coordinates is
  /// degenerate, this function returns Point.origin.
  Point globalToLocal(Point point) {
    final Matrix4 transform = _collectPaintTransform();
    double det = transform.invert();
    if (det == 0.0)
      return Point.origin;
    return MatrixUtils.transformPoint(transform, point);
  }

  /// Convert the given point from the local coordinate system for this box to
  /// the global coordinate system.
  Point localToGlobal(Point point) {
    return MatrixUtils.transformPoint(_collectPaintTransform(), point);
  }

  /// Returns a rectangle that contains all the pixels painted by this box.
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
  @override
  Rect get paintBounds => Point.origin & size;

  /// Override this method to handle pointer events that hit this render object.
  ///
  /// For [RenderBox] objects, the `entry` argument is a [BoxHitTestEntry]. From this
  /// object you can determine the [PointerDownEvent]'s position in local coordinates.
  /// (This is useful because [PointerEvent.position] is in global coordinates.)
  ///
  /// If you override this, consider calling [debugHandleEvent] as follows, so
  /// that you can support [debugPaintPointersEnabled]:
  ///
  /// ```dart
  /// @override
  /// void handleEvent(PointerEvent event, HitTestEntry entry) {
  ///   assert(debugHandleEvent(event, entry));
  ///   // ... handle the event ...
  /// }
  /// ```
  // TODO(ianh): Fix the type of the argument here once https://github.com/dart-lang/sdk/issues/25232 is fixed
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
  }

  int _debugActivePointers = 0;

  /// Implements the [debugPaintPointersEnabled] debugging feature.
  ///
  /// [RenderBox] subclasses that implement [handleEvent] should call
  /// [debugHandleEvent] from their [handleEvent] method, as follows:
  ///
  /// ```dart
  /// @override
  /// void handleEvent(PointerEvent event, HitTestEntry entry) {
  ///   assert(debugHandleEvent(event, entry));
  ///   // ... handle the event ...
  /// }
  /// ```
  ///
  /// If you call this for a [PointerDownEvent], make sure you also call it for
  /// the corresponding [PointerUpEvent] or [PointerCancelEvent].
  bool debugHandleEvent(PointerEvent event, HitTestEntry entry) {
    assert(() {
      if (debugPaintPointersEnabled) {
        if (event is PointerDownEvent) {
          _debugActivePointers += 1;
        } else if (event is PointerUpEvent || event is PointerCancelEvent) {
          _debugActivePointers -= 1;
        }
        markNeedsPaint();
      }
      return true;
    });
    return true;
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled)
        debugPaintSize(context, offset);
      if (debugPaintBaselinesEnabled)
        debugPaintBaselines(context, offset);
      if (debugPaintPointersEnabled)
        debugPaintPointers(context, offset);
      return true;
    });
  }

  /// In debug mode, paints a border around this render box.
  ///
  /// Called for every [RenderBox] when [debugPaintSizeEnabled] is true.
  @protected
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      Paint paint = new Paint()
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1.0
       ..color = debugPaintSizeColor;
      context.canvas.drawRect((offset & size).deflate(0.5), paint);
      return true;
    });
  }

  /// In debug mode, paints a line for each baseline.
  ///
  /// Called for every [RenderBox] when [debugPaintBaselinesEnabled] is true.
  @protected
  void debugPaintBaselines(PaintingContext context, Offset offset) {
    assert(() {
      Paint paint = new Paint()
       ..style = PaintingStyle.stroke
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
      return true;
    });
  }

  /// In debug mode, paints a rectangle if this render box has counted more
  /// pointer downs than pointer up events.
  ///
  /// Called for every [RenderBox] when [debugPaintPointersEnabled] is true.
  ///
  /// By default, events are not counted. For details on how to ensure that
  /// events are counted for your class, see [debugHandleEvent].
  @protected
  void debugPaintPointers(PaintingContext context, Offset offset) {
    assert(() {
      if (_debugActivePointers > 0) {
        Paint paint = new Paint()
         ..color = new Color(debugPaintPointersColorValue | ((0x04000000 * depth) & 0xFF000000));
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('size: ${ hasSize ? size : "MISSING" }');
  }
}

/// A mixin that provides useful default behaviors for boxes with children
/// managed by the [ContainerRenderObjectMixin] mixin.
///
/// By convention, this class doesn't override any members of the superclass.
/// Instead, it provides helpful functions that subclasses can call as
/// appropriate.
abstract class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerBoxParentDataMixin<ChildType>> implements ContainerRenderObjectMixin<ChildType, ParentDataType> {

  /// Returns the baseline of the first child with a baseline.
  ///
  /// Useful when the children are displayed vertically in the same order they
  /// appear in the child list.
  double defaultComputeDistanceToFirstActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      double result = child.getDistanceToActualBaseline(baseline);
      if (result != null)
        return result + childParentData.offset.dy;
      child = childParentData.nextSibling;
    }
    return null;
  }

  /// Returns the minimum baseline value among every child.
  ///
  /// Useful when the vertical position of the children isn't determined by the
  /// order in the child list.
  double defaultComputeDistanceToHighestActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    double result;
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      double candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += childParentData.offset.dy;
        if (result != null)
          result = math.min(result, candidate);
        else
          result = candidate;
      }
      child = childParentData.nextSibling;
    }
    return result;
  }

  /// Performs a hit test on each child by walking the child list backwards.
  ///
  /// Stops walking once after the first child reports that it contains the
  /// given point. Returns whether any children contain the given point.
  bool defaultHitTestChildren(HitTestResult result, { Point position }) {
    // the x, y parameters have the top left of the node's box as the origin
    ChildType child = lastChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      Point transformed = new Point(position.x - childParentData.offset.dx,
                                    position.y - childParentData.offset.dy);
      if (child.hitTest(result, position: transformed))
        return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  /// Paints each child by walking the child list forwards.
  void defaultPaint(PaintingContext context, Offset offset) {
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  /// Returns a list containing the children of this render object.
  ///
  /// This function is useful when you need random-access to the children of
  /// this render object. If you're accessing the children in order, consider
  /// walking the child list directly.
  List<ChildType> getChildrenAsList() {
    final List<ChildType> result = <ChildType>[];
    RenderBox child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      result.add(child);
      child = childParentData.nextSibling;
    }
    return result;
  }
}
