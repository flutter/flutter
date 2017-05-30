// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'semantics.dart';

export 'package:flutter/gestures.dart' show
  PointerEvent,
  PointerDownEvent,
  PointerMoveEvent,
  PointerUpEvent,
  PointerCancelEvent;

/// A base class for render objects that resemble their children.
///
/// A proxy box has a single child and simply mimics all the properties of that
/// child by calling through to the child for each function in the render box
/// protocol. For example, a proxy box determines its size by askings its child
/// to layout with the same constraints and then matching the size.
///
/// A proxy box isn't useful on its own because you might as well just replace
/// the proxy box with its child. However, RenderProxyBox is a useful base class
/// for render objects that wish to mimic most, but not all, of the properties
/// of their child.
class RenderProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin {
  /// Creates a proxy render box.
  ///
  /// Proxy render boxes are rarely created directly because they simply proxy
  /// the render box protocol to [child]. Instead, consider using one of the
  /// subclasses.
  RenderProxyBox([RenderBox child = null]) {
    this.child = child;
  }
}

/// Implementation of [RenderProxyBox].
///
/// This class can be used as a mixin for situations where the proxying behavior
/// of [RenderProxyBox] is desired but inheriting from [RenderProxyBox] is
/// impractical (e.g. because you want to mix in other classes as well).
// TODO(ianh): Remove this class once https://github.com/dart-lang/sdk/issues/15101 is fixed
abstract class RenderProxyBoxMixin implements RenderBox, RenderObjectWithChildMixin<RenderBox> {
  @override
  void setupParentData(RenderObject child) {
    // We don't actually use the offset argument in BoxParentData, so let's
    // avoid allocating it at all.
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null)
      return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) { }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

/// How to behave during hit tests.
enum HitTestBehavior {
  /// Targets that defer to their children receive events within their bounds
  /// only if one of their children is hit by the hit test.
  deferToChild,

  /// Opaque targets can be hit by hit tests, causing them to both receive
  /// events within their bounds and prevent targets visually behind them from
  /// also receiving events.
  opaque,

  /// Translucent targets both receive events within their bounds and permit
  /// targets visually behind them to also receive events.
  translucent,
}

/// A RenderProxyBox subclass that allows you to customize the
/// hit-testing behavior.
abstract class RenderProxyBoxWithHitTestBehavior extends RenderProxyBox {
  /// Initializes member variables for subclasses.
  ///
  /// By default, the [behavior] is [HitTestBehavior.deferToChild].
  RenderProxyBoxWithHitTestBehavior({
    this.behavior: HitTestBehavior.deferToChild,
    RenderBox child
  }) : super(child);

  /// How to behave during hit testing.
  HitTestBehavior behavior;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    bool hitTarget = false;
    if (size.contains(position)) {
      hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position);
      if (hitTarget || behavior == HitTestBehavior.translucent)
        result.add(new BoxHitTestEntry(this, position));
    }
    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) => behavior == HitTestBehavior.opaque;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    switch (behavior) {
      case HitTestBehavior.translucent:
        description.add('behavior: translucent');
        break;
      case HitTestBehavior.opaque:
        description.add('behavior: opaque');
        break;
      case HitTestBehavior.deferToChild:
        description.add('behavior: defer-to-child');
        break;
    }
  }
}

/// Imposes additional constraints on its child.
///
/// A render constrained box proxies most functions in the render box protocol
/// to its child, except that when laying out its child, it tightens the
/// constraints provided by its parent by enforcing the [additionalConstraints]
/// as well.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)`` as the
/// [additionalConstraints].
class RenderConstrainedBox extends RenderProxyBox {
  /// Creates a render box that constrains its child.
  ///
  /// The [additionalConstraints] argument must not be null and must be valid.
  RenderConstrainedBox({
    RenderBox child,
    @required BoxConstraints additionalConstraints,
  }) : _additionalConstraints = additionalConstraints, super(child) {
    assert(additionalConstraints != null);
    assert(additionalConstraints.debugAssertIsValid());
  }

  /// Additional constraints to apply to [child] during layout
  BoxConstraints get additionalConstraints => _additionalConstraints;
  BoxConstraints _additionalConstraints;
  set additionalConstraints(BoxConstraints value) {
    assert(value != null);
    assert(value.debugAssertIsValid());
    if (_additionalConstraints == value)
      return;
    _additionalConstraints = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (_additionalConstraints.hasBoundedWidth && _additionalConstraints.hasTightWidth)
      return _additionalConstraints.minWidth;
    final double width = super.computeMinIntrinsicWidth(height);
    if (_additionalConstraints.hasBoundedWidth)
      return _additionalConstraints.constrainWidth(width);
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (_additionalConstraints.hasBoundedWidth && _additionalConstraints.hasTightWidth)
      return _additionalConstraints.minWidth;
    final double width = super.computeMaxIntrinsicWidth(height);
    if (_additionalConstraints.hasBoundedWidth)
      return _additionalConstraints.constrainWidth(width);
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (_additionalConstraints.hasBoundedHeight && _additionalConstraints.hasTightHeight)
      return _additionalConstraints.minHeight;
    final double height = super.computeMinIntrinsicHeight(width);
    if (_additionalConstraints.hasBoundedHeight)
      return _additionalConstraints.constrainHeight(height);
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (_additionalConstraints.hasBoundedHeight && _additionalConstraints.hasTightHeight)
      return _additionalConstraints.minHeight;
    final double height = super.computeMaxIntrinsicHeight(width);
    if (_additionalConstraints.hasBoundedHeight)
      return _additionalConstraints.constrainHeight(height);
    return height;
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_additionalConstraints.enforce(constraints), parentUsesSize: true);
      size = child.size;
    } else {
      size = _additionalConstraints.enforce(constraints).constrain(Size.zero);
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      Paint paint;
      if (child == null || child.size.isEmpty) {
        paint = new Paint()
          ..color = debugPaintSpacingColor;
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('additionalConstraints: $additionalConstraints');
  }
}

/// Constrains the child's [BoxConstraints.maxWidth] and
/// [BoxConstraints.maxHeight] if they're otherwise unconstrained.
///
/// This has the effect of giving the child a natural dimension in unbounded
/// environments. For example, by providing a [maxHeight] to a widget that
/// normally tries to be as big as possible, the widget will normally size
/// itself to fit its parent, but when placed in a vertical list, it will take
/// on the given height.
///
/// This is useful when composing widgets that normally try to match their
/// parents' size, so that they behave reasonably in lists (which are
/// unbounded).
class RenderLimitedBox extends RenderProxyBox {
  /// Creates a render box that imposes a maximum width or maximum height on its
  /// child if the child is otherwise unconstrained.
  ///
  /// The [maxWidth] and [maxHeight] arguments not be null and must be
  /// non-negative.
  RenderLimitedBox({
    RenderBox child,
    double maxWidth: double.INFINITY,
    double maxHeight: double.INFINITY
  }) : _maxWidth = maxWidth, _maxHeight = maxHeight, super(child) {
    assert(maxWidth != null && maxWidth >= 0.0);
    assert(maxHeight != null && maxHeight >= 0.0);
  }

  /// The value to use for maxWidth if the incoming maxWidth constraint is infinite.
  double get maxWidth => _maxWidth;
  double _maxWidth;
  set maxWidth(double value) {
    assert(value != null && value >= 0.0);
    if (_maxWidth == value)
      return;
    _maxWidth = value;
    markNeedsLayout();
  }

  /// The value to use for maxHeight if the incoming maxHeight constraint is infinite.
  double get maxHeight => _maxHeight;
  double _maxHeight;
  set maxHeight(double value) {
    assert(value != null && value >= 0.0);
    if (_maxHeight == value)
      return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _limitConstraints(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.hasBoundedWidth ? constraints.maxWidth : constraints.constrainWidth(maxWidth),
      minHeight: constraints.minHeight,
      maxHeight: constraints.hasBoundedHeight ? constraints.maxHeight : constraints.constrainHeight(maxHeight)
    );
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_limitConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
    } else {
      size = _limitConstraints(constraints).constrain(Size.zero);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (maxWidth != double.INFINITY)
      description.add('maxWidth: $maxWidth');
    if (maxHeight != double.INFINITY)
      description.add('maxHeight: $maxHeight');
  }
}

/// Attempts to size the child to a specific aspect ratio.
///
/// The render object first tries the largest width permited by the layout
/// constraints. The height of the render object is determined by applying the
/// given aspect ratio to the width, expressed as a ratio of width to height.
///
/// For example, a 16:9 width:height aspect ratio would have a value of
/// 16.0/9.0. If the maximum width is infinite, the initial width is determined
/// by applying the aspect ratio to the maximum height.
///
/// Now consider a second example, this time with an aspect ratio of 2.0 and
/// layout constraints that require the width to be between 0.0 and 100.0 and
/// the height to be between 0.0 and 100.0. We'll select a width of 100.0 (the
/// biggest allowed) and a height of 50.0 (to match the aspect ratio).
///
/// In that same situation, if the aspect ratio is 0.5, we'll also select a
/// width of 100.0 (still the biggest allowed) and we'll attempt to use a height
/// of 200.0. Unfortunately, that violates the constraints because the child can
/// be at most 100.0 pixels tall. The render object will then take that value
/// and apply the aspect ratio again to obtain a width of 50.0. That width is
/// permitted by the constraints and the child receives a width of 50.0 and a
/// height of 100.0. If the width were not permitted, the render object would
/// continue iterating through the constraints. If the render object does not
/// find a feasible size after consulting each constraint, the render object
/// will eventually select a size for the child that meets the layout
/// constraints but fails to meet the aspect ratio constraints.
class RenderAspectRatio extends RenderProxyBox {
  /// Creates as render object with a specific aspect ratio.
  ///
  /// The [aspectRatio] argument must be a finite, positive value.
  RenderAspectRatio({
    RenderBox child,
    @required double aspectRatio,
  }) : _aspectRatio = aspectRatio, super(child) {
    assert(aspectRatio != null);
    assert(aspectRatio > 0.0);
    assert(aspectRatio.isFinite);
  }

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  double get aspectRatio => _aspectRatio;
  double _aspectRatio;
  set aspectRatio(double value) {
    assert(value != null);
    assert(value > 0.0);
    assert(value.isFinite);
    if (_aspectRatio == value)
      return;
    _aspectRatio = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (height.isFinite)
      return height * _aspectRatio;
    if (child != null)
      return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (height.isFinite)
      return height * _aspectRatio;
    if (child != null)
      return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (width.isFinite)
      return width / _aspectRatio;
    if (child != null)
      return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (width.isFinite)
      return width / _aspectRatio;
    if (child != null)
      return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  Size _applyAspectRatio(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    assert(() {
      if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
        throw new FlutterError(
          '$runtimeType has unbounded constraints.\n'
          'This $runtimeType was given an aspect ratio of $aspectRatio but was given '
          'both unbounded width and unbounded height constraints. Because both '
          'constraints were unbounded, this render object doesn\'t know how much '
          'size to consume.'
        );
      }
      return true;
    });

    if (constraints.isTight)
      return constraints.smallest;

    double width = constraints.maxWidth;
    double height;

    // We default to picking the height based on the width, but if the width
    // would be infinite, that's not sensible so we try to infer the height
    // from the width.
    if (width.isFinite) {
      height = width / _aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    // Similar to RenderImage, we iteratively attempt to fit within the given
    // constraints while maintaining the given aspect ratio. The order of
    // applying the constraints is also biased towards inferring the height
    // from the width.

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / _aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / _aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * _aspectRatio;
    }

    return constraints.constrain(new Size(width, height));
  }

  @override
  void performLayout() {
    size = _applyAspectRatio(constraints);
    if (child != null)
      child.layout(new BoxConstraints.tight(size));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('aspectRatio: $aspectRatio');
  }
}

/// Sizes its child to the child's intrinsic width.
///
/// Sizes its child's width to the child's maximum intrinsic width. If
/// [stepWidth] is non-null, the child's width will be snapped to a multiple of
/// the [stepWidth]. Similarly, if [stepHeight] is non-null, the child's height
/// will be snapped to a multiple of the [stepHeight].
///
/// This class is useful, for example, when unlimited width is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable width.
///
/// This class is relatively expensive. Avoid using it where possible.
class RenderIntrinsicWidth extends RenderProxyBox {
  /// Creates a render object that sizes itself to its child's intrinsic width.
  RenderIntrinsicWidth({
    double stepWidth,
    double stepHeight,
    RenderBox child
  }) : _stepWidth = stepWidth, _stepHeight = stepHeight, super(child);

  /// If non-null, force the child's width to be a multiple of this value.
  double get stepWidth => _stepWidth;
  double _stepWidth;
  set stepWidth(double value) {
    if (value == _stepWidth)
      return;
    _stepWidth = value;
    markNeedsLayout();
  }

  /// If non-null, force the child's height to be a multiple of this value.
  double get stepHeight => _stepHeight;
  double _stepHeight;
  set stepHeight(double value) {
    if (value == _stepHeight)
      return;
    _stepHeight = value;
    markNeedsLayout();
  }

  static double _applyStep(double input, double step) {
    assert(input.isFinite);
    if (step == null)
      return input;
    return (input / step).ceil() * step;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null)
      return 0.0;
    final double width = child.getMaxIntrinsicWidth(height);
    return _applyStep(width, _stepWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child == null)
      return 0.0;
    if (!width.isFinite)
      width = computeMaxIntrinsicWidth(double.INFINITY);
    assert(width.isFinite);
    final double height = child.getMinIntrinsicHeight(width);
    return _applyStep(height, _stepHeight);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null)
      return 0.0;
    if (!width.isFinite)
      width = computeMaxIntrinsicWidth(double.INFINITY);
    assert(width.isFinite);
    final double height = child.getMaxIntrinsicHeight(width);
    return _applyStep(height, _stepHeight);
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = constraints;
      if (!childConstraints.hasTightWidth) {
        final double width = child.getMaxIntrinsicWidth(childConstraints.maxHeight);
        assert(width.isFinite);
        childConstraints = childConstraints.tighten(width: _applyStep(width, _stepWidth));
      }
      if (_stepHeight != null) {
        final double height = child.getMaxIntrinsicHeight(childConstraints.maxWidth);
        assert(height.isFinite);
        childConstraints = childConstraints.tighten(height: _applyStep(height, _stepHeight));
      }
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('stepWidth: $stepWidth');
    description.add('stepHeight: $stepHeight');
  }
}

/// Sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// This class is relatively expensive. Avoid using it where possible.
class RenderIntrinsicHeight extends RenderProxyBox {
  /// Creates a render object that sizes itself to its child's intrinsic height.
  RenderIntrinsicHeight({
    RenderBox child
  }) : super(child);

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null)
      return 0.0;
    if (!height.isFinite)
      height = child.getMaxIntrinsicHeight(double.INFINITY);
    assert(height.isFinite);
    return child.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null)
      return 0.0;
    if (!height.isFinite)
      height = child.getMaxIntrinsicHeight(double.INFINITY);
    assert(height.isFinite);
    return child.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeMaxIntrinsicHeight(width);
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = constraints;
      if (!childConstraints.hasTightHeight) {
        final double height = child.getMaxIntrinsicHeight(childConstraints.maxWidth);
        assert(height.isFinite);
        childConstraints = childConstraints.tighten(height: height);
      }
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

}

int _getAlphaFromOpacity(double opacity) => (opacity * 255).round();

/// Makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// For values of opacity other than 0.0 and 1.0, this class is relatively
/// expensive because it requires painting the child into an intermediate
/// buffer. For the value 0.0, the child is simply not painted at all. For the
/// value 1.0, the child is painted immediately without an intermediate buffer.
class RenderOpacity extends RenderProxyBox {
  /// Creates a partially transparent render object.
  ///
  /// The [opacity] argument must be between 0.0 and 1.0, inclusive.
  RenderOpacity({ double opacity: 1.0, RenderBox child })
    : _opacity = opacity, _alpha = _getAlphaFromOpacity(opacity), super(child) {
    assert(opacity != null);
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

  @override
  bool get alwaysNeedsCompositing => child != null && (_alpha != 0 && _alpha != 255);

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  ///
  /// The opacity must not be null.
  ///
  /// Values 1.0 and 0.0 are painted with a fast path. Other values
  /// require painting the child into an intermediate buffer, which is
  /// expensive.
  double get opacity => _opacity;
  double _opacity;
  set opacity(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (_opacity == value)
      return;
    _opacity = value;
    _alpha = _getAlphaFromOpacity(_opacity);
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  int _alpha;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      if (_alpha == 0)
        return;
      if (_alpha == 255) {
        context.paintChild(child, offset);
        return;
      }
      assert(needsCompositing);
      context.pushOpacity(offset, _alpha, super.paint);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && _alpha != 0)
      visitor(child);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('opacity: ${opacity.toStringAsFixed(1)}');
  }
}

/// Signature for a function that creates a [Shader] for a given [Rect].
///
/// Used by [RenderShaderMask].
typedef Shader ShaderCallback(Rect bounds);

/// Applies a mask generated by a [Shader] to its child.
///
/// For example, [RenderShaderMask] can be used to gradually fade out the edge
/// of a child by using a [new ui.Gradient.linear] mask.
class RenderShaderMask extends RenderProxyBox {
  /// Creates a render object that applies a mask generated by a [Shader] to its child.
  ///
  /// The [shaderCallback] and [blendMode] arguments must not be null.
  RenderShaderMask({
    RenderBox child,
    @required ShaderCallback shaderCallback,
    BlendMode blendMode: BlendMode.modulate,
  }) : _shaderCallback = shaderCallback, _blendMode = blendMode, super(child) {
    assert(shaderCallback != null);
    assert(blendMode != null);
  }

  /// Called to creates the [Shader] that generates the mask.
  ///
  /// The shader callback is called with the current size of the child so that
  /// it can customize the shader to the size and location of the child.
  // TODO(abarth): Use the delegate pattern here to avoid generating spurious
  // repaints when the ShaderCallback changes identity.
  ShaderCallback get shaderCallback => _shaderCallback;
  ShaderCallback _shaderCallback;
  set shaderCallback(ShaderCallback value) {
    assert(value != null);
    if (_shaderCallback == value)
      return;
    _shaderCallback = value;
    markNeedsPaint();
  }

  /// The [BlendMode] to use when applying the shader to the child.
  ///
  /// The default, [BlendMode.modulate], is useful for applying an alpha blend
  /// to the child. Other blend modes can be used to create other effects.
  BlendMode get blendMode => _blendMode;
  BlendMode _blendMode;
  set blendMode(BlendMode value) {
    assert(value != null);
    if (_blendMode == value)
      return;
    _blendMode = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);
      final Rect rect = Offset.zero & size;
      context.pushShaderMask(offset, _shaderCallback(rect), rect, _blendMode, super.paint);
    }
  }
}

/// Applies a filter to the existing painted content and then paints [child].
///
/// This effect is relatively expensive, especially if the filter is non-local,
/// such as a blur.
class RenderBackdropFilter extends RenderProxyBox {
  /// Creates a backdrop filter.
  ///
  /// The [filter] argument must not be null.
  RenderBackdropFilter({ RenderBox child, @required ui.ImageFilter filter })
    : _filter = filter, super(child) {
    assert(filter != null);
  }

  /// The image filter to apply to the existing painted content before painting
  /// the child.
  ///
  /// For example, consider using [new ui.ImageFilter.blur] to create a backdrop
  /// blur effect.
  ui.ImageFilter get filter => _filter;
  ui.ImageFilter _filter;
  set filter(ui.ImageFilter value) {
    assert(value != null);
    if (_filter == value)
      return;
    _filter = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);
      context.pushBackdropFilter(offset, _filter, super.paint);
    }
  }
}

/// An interface for providing custom clips.
///
/// This class is used by a number of clip widgets (e.g., [ClipRect] and
/// [ClipPath]).
///
/// The [getClip] method is called whenever the custom clip needs to be updated.
///
/// The [shouldReclip] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to update the clip provided by this class is to
/// supply a reclip argument to the constructor of the [CustomClipper]. The
/// custom object will listen to this animation and update the clip whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// See also:
///
///  * [ClipRect], which can be customized with a [CustomClipper].
///  * [ClipRRect], which can be customized with a [CustomClipper].
///  * [ClipOval], which can be customized with a [CustomClipper].
///  * [ClipPath], which can be customized with a [CustomClipper].
abstract class CustomClipper<T> {
  /// Creates a custom clipper.
  ///
  /// The clipper will update its clip whenever [reclip] notifies its listeners.
  const CustomClipper({ Listenable reclip }) : _reclip = reclip;

  final Listenable _reclip;

  /// Returns a description of the clip given that the render object being
  /// clipped is of the given size.
  T getClip(Size size);

  /// Returns an approximation of the clip returned by [getClip], as
  /// an axis-aligned Rect. This is used by the semantics layer to
  /// determine whether widgets should be excluded.
  ///
  /// By default, this returns a rectangle that is the same size as
  /// the RenderObject. If getClip returns a shape that is roughly the
  /// same size as the RenderObject (e.g. it's a rounded rectangle
  /// with very small arcs in the corners), then this may be adequate.
  Rect getApproximateClipRect(Size size) => Offset.zero & size;

  /// Called whenever a new instance of the custom clipper delegate class is
  /// provided to the clip object, or any time that a new clip object is created
  /// with a new instance of the custom painter delegate class (which amounts to
  /// the same thing, because the latter is implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [getClip] call might be optimized
  /// away.
  ///
  /// It's possible that the [getClip] method will get called even if
  /// [shouldReclip] returns false or if the [shouldReclip] method is never
  /// called at all (e.g. if the box changes size).
  bool shouldReclip(covariant CustomClipper<T> oldClipper);

  @override
  String toString() => '$runtimeType';
}

abstract class _RenderCustomClip<T> extends RenderProxyBox {
  _RenderCustomClip({
    RenderBox child,
    CustomClipper<T> clipper
  }) : _clipper = clipper, super(child);

  /// If non-null, determines which clip to use on the child.
  CustomClipper<T> get clipper => _clipper;
  CustomClipper<T> _clipper;
  set clipper(CustomClipper<T> newClipper) {
    if (_clipper == newClipper)
      return;
    final CustomClipper<T> oldClipper = _clipper;
    _clipper = newClipper;
    assert(newClipper != null || oldClipper != null);
    if (newClipper == null || oldClipper == null ||
        oldClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper?._reclip?.removeListener(_markNeedsClip);
      newClipper?._reclip?.addListener(_markNeedsClip);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?._reclip?.addListener(_markNeedsClip);
 }

  @override
  void detach() {
    _clipper?._reclip?.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate(onlyChanges: true);
  }

  T get _defaultClip;
  T _clip;

  @override
  void performLayout() {
    final Size oldSize = hasSize ? size : null;
    super.performLayout();
    if (oldSize != size)
      _clip = null;
  }

  void _updateClip() {
    _clip ??= _clipper?.getClip(size) ?? _defaultClip;
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    return _clipper?.getApproximateClipRect(size) ?? Offset.zero & size;
  }
}

/// Clips its child using a rectangle.
///
/// By default, [RenderClipRect] prevents its child from painting outside its
/// bounds, but the size and location of the clip rect can be customized using a
/// custom [clipper].
class RenderClipRect extends _RenderCustomClip<Rect> {
  /// Creates a rectangular clip.
  ///
  /// If [clipper] is null, the clip will match the layout size and position of
  /// the child.
  RenderClipRect({
    RenderBox child,
    CustomClipper<Rect> clipper
  }) : super(child: child, clipper: clipper);

  @override
  Rect get _defaultClip => Offset.zero & size;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position))
        return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      context.pushClipRect(needsCompositing, offset, _clip, super.paint);
    }
  }
}

/// Clips its child using a rounded rectangle.
///
/// By default, [RenderClipRRect] uses its own bounds as the base rectangle for
/// the clip, but the size and location of the clip can be customized using a
/// custom [clipper].
class RenderClipRRect extends _RenderCustomClip<RRect> {
  /// Creates a rounded-rectangular clip.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipper] is non-null, then [borderRadius] is ignored.
  RenderClipRRect({
    RenderBox child,
    BorderRadius borderRadius: BorderRadius.zero,
    CustomClipper<RRect> clipper,
  }) : _borderRadius = borderRadius, super(child: child, clipper: clipper) {
    assert(_borderRadius != null || clipper != null);
  }

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  BorderRadius get borderRadius => _borderRadius;
  BorderRadius _borderRadius;
  set borderRadius(BorderRadius value) {
    assert(value != null);
    if (_borderRadius == value)
      return;
    _borderRadius = value;
    _markNeedsClip();
  }

  @override
  RRect get _defaultClip => _borderRadius.toRRect(Offset.zero & size);

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position))
        return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      context.pushClipRRect(needsCompositing, offset, _clip.outerRect, _clip, super.paint);
    }
  }
}

/// Clips its child using an oval.
///
/// By default, inscribes an axis-aligned oval into its layout dimensions and
/// prevents its child from painting outside that oval, but the size and
/// location of the clip oval can be customized using a custom [clipper].
class RenderClipOval extends _RenderCustomClip<Rect> {
  /// Creates an oval-shaped clip.
  ///
  /// If [clipper] is null, the oval will be inscribed into the layout size and
  /// position of the child.
  RenderClipOval({
    RenderBox child,
    CustomClipper<Rect> clipper
  }) : super(child: child, clipper: clipper);

  Rect _cachedRect;
  Path _cachedPath;

  Path _getClipPath(Rect rect) {
    if (rect != _cachedRect) {
      _cachedRect = rect;
      _cachedPath = new Path()..addOval(_cachedRect);
    }
    return _cachedPath;
  }

  @override
  Rect get _defaultClip => Offset.zero & size;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    _updateClip();
    assert(_clip != null);
    final Offset center = _clip.center;
    // convert the position to an offset from the center of the unit circle
    final Offset offset = new Offset((position.dx - center.dx) / _clip.width,
                                     (position.dy - center.dy) / _clip.height);
    // check if the point is outside the unit circle
    if (offset.distanceSquared > 0.25) // x^2 + y^2 > r^2
      return false;
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      context.pushClipPath(needsCompositing, offset, _clip, _getClipPath(_clip), super.paint);
    }
  }
}

/// Clips its child using a path.
///
/// Takes a delegate whose primary method returns a path that should
/// be used to prevent the child from painting outside the path.
///
/// Clipping to a path is expensive. Certain shapes have more
/// optimized render objects:
///
///  * To clip to a rectangle, consider [RenderClipRect].
///  * To clip to an oval or circle, consider [RenderClipOval].
///  * To clip to a rounded rectangle, consider [RenderClipRRect].
class RenderClipPath extends _RenderCustomClip<Path> {
  /// Creates a path clip.
  ///
  /// If [clipper] is null, the clip will be a rectangle that matches the layout
  /// size and location of the child. However, rather than use this default,
  /// consider using a [RenderClipRect], which can achieve the same effect more
  /// efficiently.
  RenderClipPath({
    RenderBox child,
    CustomClipper<Path> clipper
  }) : super(child: child, clipper: clipper);

  @override
  Path get _defaultClip => new Path()..addRect(Offset.zero & size);

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position))
        return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      context.pushClipPath(needsCompositing, offset, Offset.zero & size, _clip, super.paint);
    }
  }
}

/// Creates a physical model layer that clips its children to a rounded
/// rectangle.
///
/// A physical model layer casts a shadow based on its [elevation].
class RenderPhysicalModel extends _RenderCustomClip<RRect> {
  /// Creates a rounded-rectangular clip.
  ///
  /// The [color] is required.
  ///
  /// The [shape], [elevation], and [color] must not be null.
  RenderPhysicalModel({
    RenderBox child,
    BoxShape shape: BoxShape.rectangle,
    BorderRadius borderRadius,
    double elevation: 0.0,
    @required Color color,
  }) : _shape = shape,
       _borderRadius = borderRadius,
       _elevation = elevation,
       _color = color,
       super(child: child) {
    assert(shape != null);
    assert(elevation != null);
    assert(color != null);
  }

  /// The shape of the layer.
  ///
  /// Defaults to [BoxShape.rectangle]. The [borderRadius] affects the corners
  /// of the rectangle.
  BoxShape get shape => _shape;
  BoxShape _shape;
  set shape(BoxShape value) {
    assert(value != null);
    if (shape == value)
      return;
    _shape = value;
    _markNeedsClip();
  }

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This property is ignored if the [shape] is not [BoxShape.rectangle].
  ///
  /// The value null is treated like [BorderRadius.zero].
  BorderRadius get borderRadius => _borderRadius;
  BorderRadius _borderRadius;
  set borderRadius(BorderRadius value) {
    if (borderRadius == value)
      return;
    _borderRadius = value;
    _markNeedsClip();
  }

  /// The z-coordinate at which to place this material.
  double get elevation => _elevation;
  double _elevation;
  set elevation(double value) {
    assert(value != null);
    if (elevation == value)
      return;
    _elevation = value;
    markNeedsPaint();
  }

  /// The background color.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(value != null);
    if (color == value)
      return;
    _color = value;
    markNeedsPaint();
  }

  @override
  RRect get _defaultClip {
    assert(hasSize);
    if (_shape == BoxShape.rectangle) {
      return (borderRadius ?? BorderRadius.zero).toRRect(Offset.zero & size);
    } else {
      final Rect rect = Offset.zero & size;
      return new RRect.fromRectXY(rect, rect.width / 2, rect.height / 2);
    }
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position))
        return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      context.pushPhysicalModel(needsCompositing, offset, _clip.outerRect, _clip, elevation, color, super.paint);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('shape: $shape');
    description.add('borderRadius: $borderRadius');
    description.add('elevation: ${elevation.toStringAsFixed(1)}');
    description.add('color: $color');
  }
}

/// Where to paint a box decoration.
enum DecorationPosition {
  /// Paint the box decoration behind the children.
  background,

  /// Paint the box decoration in front of the children.
  foreground,
}

/// Paints a [Decoration] either before or after its child paints.
class RenderDecoratedBox extends RenderProxyBox {
  /// Creates a decorated box.
  ///
  /// The [decoration], [position], and [configuration] arguments must not be
  /// null. By default the decoration paints behind the child.
  ///
  /// The [ImageConfiguration] will be passed to the decoration (with the size
  /// filled in) to let it resolve images.
  RenderDecoratedBox({
    @required Decoration decoration,
    DecorationPosition position: DecorationPosition.background,
    ImageConfiguration configuration: ImageConfiguration.empty,
    RenderBox child
  }) : _decoration = decoration,
       _position = position,
       _configuration = configuration,
       super(child) {
    assert(decoration != null);
    assert(position != null);
    assert(configuration != null);
  }

  BoxPainter _painter;

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  Decoration get decoration => _decoration;
  Decoration _decoration;
  set decoration(Decoration value) {
    assert(value != null);
    if (value == _decoration)
      return;
    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  /// Whether to paint the box decoration behind or in front of the child.
  DecorationPosition get position => _position;
  DecorationPosition _position;
  set position(DecorationPosition value) {
    assert(value != null);
    if (value == _position)
      return;
    _position = value;
    markNeedsPaint();
  }

  /// The settings to pass to the decoration when painting, so that it can
  /// resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration)
      return;
    _configuration = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
  }

  @override
  bool hitTestSelf(Offset position) {
    return _decoration.hitTest(size, position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);
    final ImageConfiguration filledConfiguration = configuration.copyWith(size: size);
    if (position == DecorationPosition.background) {
      int debugSaveCount;
      assert(() {
        debugSaveCount = context.canvas.getSaveCount();
        return true;
      });
      _painter.paint(context.canvas, offset, filledConfiguration);
      assert(() {
        if (debugSaveCount != context.canvas.getSaveCount()) {
          throw new FlutterError(
            '${_decoration.runtimeType} painter had mismatching save and restore calls.\n'
            'Before painting the decoration, the canvas save count was $debugSaveCount. '
            'After painting it, the canvas save count was ${context.canvas.getSaveCount()}. '
            'Every call to save() or saveLayer() must be matched by a call to restore().\n'
            'The decoration was:\n'
            '${decoration.toString("  ")}\n'
            'The painter was:\n'
            '  $_painter'
          );
        }
        return true;
      });
      if (decoration.isComplex)
        context.setIsComplexHint();
    }
    super.paint(context, offset);
    if (position == DecorationPosition.foreground) {
      _painter.paint(context.canvas, offset, filledConfiguration);
      if (decoration.isComplex)
        context.setIsComplexHint();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('decoration:');
    description.addAll(_decoration.toString('  ', '    ').split('\n'));
    description.add('configuration: $configuration');
  }
}

/// Applies a transformation before painting its child.
class RenderTransform extends RenderProxyBox {
  /// Creates a render object that transforms its child.
  ///
  /// The [transform] argument must not be null.
  RenderTransform({
    @required Matrix4 transform,
    Offset origin,
    FractionalOffset alignment,
    this.transformHitTests: true,
    RenderBox child
  }) : super(child) {
    assert(transform != null);
    assert(alignment == null || (alignment.dx != null && alignment.dy != null));
    this.transform = transform;
    this.alignment = alignment;
    this.origin = origin;
  }

  /// The origin of the coordinate system (relative to the upper left corder of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  Offset get origin => _origin;
  Offset _origin;
  set origin(Offset value) {
    if (_origin == value)
      return;
    _origin = value;
    markNeedsPaint();
  }

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as an offset, both are applied.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  set alignment(FractionalOffset value) {
    assert(value == null || (value.dx != null && value.dy != null));
    if (_alignment == value)
      return;
    _alignment = value;
    markNeedsPaint();
  }

  /// When set to true, hit tests are performed based on the position of the
  /// child as it is painted. When set to false, hit tests are performed
  /// ignoring the transformation.
  ///
  /// applyPaintTransform(), and therefore localToGlobal() and globalToLocal(),
  /// always honor the transformation, regardless of the value of this property.
  bool transformHitTests;

  // Note the lack of a getter for transform because Matrix4 is not immutable
  Matrix4 _transform;

  /// The matrix to transform the child by during painting.
  set transform(Matrix4 value) {
    assert(value != null);
    if (_transform == value)
      return;
    _transform = new Matrix4.copy(value);
    markNeedsPaint();
  }

  /// Sets the transform to the identity matrix.
  void setIdentity() {
    _transform.setIdentity();
    markNeedsPaint();
  }

  /// Concatenates a rotation about the x axis into the transform.
  void rotateX(double radians) {
    _transform.rotateX(radians);
    markNeedsPaint();
  }

  /// Concatenates a rotation about the y axis into the transform.
  void rotateY(double radians) {
    _transform.rotateY(radians);
    markNeedsPaint();
  }

  /// Concatenates a rotation about the z axis into the transform.
  void rotateZ(double radians) {
    _transform.rotateZ(radians);
    markNeedsPaint();
  }

  /// Concatenates a translation by (x, y, z) into the transform.
  void translate(double x, [double y = 0.0, double z = 0.0]) {
    _transform.translate(x, y, z);
    markNeedsPaint();
  }

  /// Concatenates a scale into the transform.
  void scale(double x, [double y, double z]) {
    _transform.scale(x, y, z);
    markNeedsPaint();
  }

  Matrix4 get _effectiveTransform {
    if (_origin == null && _alignment == null)
      return _transform;
    final Matrix4 result = new Matrix4.identity();
    if (_origin != null)
      result.translate(_origin.dx, _origin.dy);
    Offset translation;
    if (_alignment != null) {
      translation = _alignment.alongSize(size);
      result.translate(translation.dx, translation.dy);
    }
    result.multiply(_transform);
    if (_alignment != null)
      result.translate(-translation.dx, -translation.dy);
    if (_origin != null)
      result.translate(-_origin.dx, -_origin.dy);
    return result;
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (transformHitTests) {
      Matrix4 inverse;
      try {
        inverse = new Matrix4.inverted(_effectiveTransform);
      } catch (e) {
        // We cannot invert the effective transform. That means the child
        // doesn't appear on screen and cannot be hit.
        return false;
      }
      position = MatrixUtils.transformPoint(inverse, position);
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Matrix4 transform = _effectiveTransform;
      final Offset childOffset = MatrixUtils.getAsTranslation(transform);
      if (childOffset == null)
        context.pushTransform(needsCompositing, offset, transform, super.paint);
      else
        super.paint(context, offset + childOffset);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform);
    super.applyPaintTransform(child, transform);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('transform matrix:');
    description.addAll(debugDescribeTransform(_transform));
    description.add('origin: $origin');
    description.add('alignment: $alignment');
    description.add('transformHitTests: $transformHitTests');
  }
}

/// Scales and positions its child within itself according to [fit].
class RenderFittedBox extends RenderProxyBox {
  /// Scales and positions its child within itself.
  ///
  /// The [fit] and [alignment] arguments must not be null.
  RenderFittedBox({
    RenderBox child,
    BoxFit fit: BoxFit.contain,
    FractionalOffset alignment: FractionalOffset.center
  }) : _fit = fit, _alignment = alignment, super(child) {
    assert(fit != null);
    assert(alignment != null && alignment.dx != null && alignment.dy != null);
  }

  /// How to inscribe the child into the space allocated during layout.
  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    assert(value != null);
    if (_fit == value)
      return;
    _fit = value;
    _clearPaintData();
    markNeedsPaint();
  }

  /// How to align the child within its parent's bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the child to the top-left corner of its
  /// parent's bounds.  An alignment of (1.0, 0.5) aligns the child to the middle
  /// of the right edge of its parent's bounds.
  FractionalOffset get alignment => _alignment;
  FractionalOffset _alignment;
  set alignment(FractionalOffset value) {
    assert(value != null && value.dx != null && value.dy != null);
    if (_alignment == value)
      return;
    _alignment = value;
    _clearPaintData();
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      size = constraints.constrainSizeAndAttemptToPreserveAspectRatio(child.size);
      _clearPaintData();
    } else {
      size = constraints.smallest;
    }
  }

  bool _hasVisualOverflow;
  Matrix4 _transform;

  void _clearPaintData() {
    _hasVisualOverflow = null;
    _transform = null;
  }

  void _updatePaintData() {
    if (_transform != null)
      return;

    if (child == null) {
      _hasVisualOverflow = false;
      _transform = new Matrix4.identity();
    } else {
      final Size childSize = child.size;
      final FittedSizes sizes = applyBoxFit(_fit, childSize, size);
      final double scaleX = sizes.destination.width / sizes.source.width;
      final double scaleY = sizes.destination.height / sizes.source.height;
      final Rect sourceRect = _alignment.inscribe(sizes.source, Offset.zero & childSize);
      final Rect destinationRect = _alignment.inscribe(sizes.destination, Offset.zero & size);
      _hasVisualOverflow = sourceRect.width < childSize.width || sourceRect.height < childSize.width;
      _transform = new Matrix4.translationValues(destinationRect.left, destinationRect.top, 0.0)
        ..scale(scaleX, scaleY, 1.0)
        ..translate(-sourceRect.left, -sourceRect.top);
    }
  }

  void _paintChildWithTransform(PaintingContext context, Offset offset) {
    final Offset childOffset = MatrixUtils.getAsTranslation(_transform);
    if (childOffset == null)
      context.pushTransform(needsCompositing, offset, _transform, super.paint);
    else
      super.paint(context, offset + childOffset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty)
      return;
    _updatePaintData();
    if (child != null) {
      if (_hasVisualOverflow)
        context.pushClipRect(needsCompositing, offset, Offset.zero & size, _paintChildWithTransform);
      else
        _paintChildWithTransform(context, offset);
    }
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    _updatePaintData();
    Matrix4 inverse;
    try {
      inverse = new Matrix4.inverted(_transform);
    } catch (e) {
      // We cannot invert the effective transform. That means the child
      // doesn't appear on screen and cannot be hit.
      return false;
    }
    position = MatrixUtils.transformPoint(inverse, position);
    return super.hitTest(result, position: position);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    _updatePaintData();
    transform.multiply(_transform);
    super.applyPaintTransform(child, transform);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('fit: $fit');
    description.add('alignment: $alignment');
  }
}

/// Applies a translation transformation before painting its child.
///
/// The translation is expressed as a [FractionalOffset] relative to the
/// RenderFractionalTranslation box's size. Hit tests will only be detected
/// inside the bounds of the RenderFractionalTranslation, even if the contents
/// are offset such that they overflow.
class RenderFractionalTranslation extends RenderProxyBox {
  /// Creates a render object that translates its child's painting.
  ///
  /// The [translation] argument must not be null.
  RenderFractionalTranslation({
    FractionalOffset translation,
    this.transformHitTests: true,
    RenderBox child
  }) : _translation = translation, super(child) {
    assert(translation == null || (translation.dx != null && translation.dy != null));
  }

  /// The translation to apply to the child, as a multiple of the size.
  FractionalOffset get translation => _translation;
  FractionalOffset _translation;
  set translation(FractionalOffset value) {
    assert(value == null || (value.dx != null && value.dy != null));
    if (_translation == value)
      return;
    _translation = value;
    markNeedsPaint();
  }

  /// When set to true, hit tests are performed based on the position of the
  /// child as it is painted. When set to false, hit tests are performed
  /// ignoring the transformation.
  ///
  /// applyPaintTransform(), and therefore localToGlobal() and globalToLocal(),
  /// always honor the transformation, regardless of the value of this property.
  bool transformHitTests;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    assert(!debugNeedsLayout);
    if (transformHitTests)
      position = new Offset(position.dx - translation.dx * size.width, position.dy - translation.dy * size.height);
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(!debugNeedsLayout);
    if (child != null)
      super.paint(context, offset + translation.alongSize(size));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translate(translation.dx * size.width, translation.dy * size.height);
    super.applyPaintTransform(child, transform);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('translation: $translation');
    description.add('transformHitTests: $transformHitTests');
  }
}

/// The interface used by [CustomPaint] (in the widgets library) and
/// [RenderCustomPaint] (in the rendering library).
///
/// To implement a custom painter, either subclass or implement this interface
/// to define your custom paint delegate. [CustomPaint] subclasses must
/// implement the [paint] and [shouldRepaint] methods, and may optionally also
/// implement the [hitTest] method.
///
/// The [paint] method is called whenever the custom object needs to be repainted.
///
/// The [shouldRepaint] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to trigger a repaint is to either extend this class
/// and supply a `repaint` argument to the constructor of the [CustomPainter],
/// where that object notifies its listeners when it is time to repaint, or to
/// extend [Listenable] (e.g. via [ChangeNotifier]) and implement
/// [CustomPainter], so that the object itself provides the notifications
/// directly. In either case, the [CustomPaint] widget or [RenderCustomPaint]
/// render object will listen to the [Listenable] and repaint whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// The [hitTest] method is called when the user interacts with the underlying
/// render object, to determine if the user hit the object or missed it.
///
/// ## Sample code
///
/// This sample extends the same code shown for [RadialGradient] to create a
/// custom painter that paints a sky.
///
/// ```dart
/// class Sky extends CustomPainter {
///   @override
///   void paint(Canvas canvas, Size size) {
///     var rect = Offset.zero & size;
///     var gradient = new RadialGradient(
///       center: const FractionalOffset(0.7, 0.2),
///       radius: 0.2,
///       colors: [const Color(0xFFFFFF00), const Color(0xFF0099FF)],
///       stops: [0.4, 1.0],
///     );
///     canvas.drawRect(
///       rect,
///       new Paint()..shader = gradient.createShader(rect),
///     );
///   }
///
///   @override
///   bool shouldRepaint(CustomPainter oldDelegate) => false;
/// }
/// ```
///
/// See also:
///
///  * [Canvas], the class that a custom painter uses to paint.
///  * [CustomPaint], the widget that uses [CustomPainter], and whose sample
///    code shows how to use the above `Sky` class.
///  * [RadialGradient], whose sample code section shows a different take
///    on the sample code above.
abstract class CustomPainter extends Listenable {
  /// Creates a custom painter.
  ///
  /// The painter will repaint whenever `repaint` notifies its listeners.
  const CustomPainter({ Listenable repaint }) : _repaint = repaint;

  final Listenable _repaint;

  /// Register a closure to be notified when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies when it is time to repaint.
  ///
  /// The [CustomPainter] implementation merely forwards to the same method on
  /// the [Listenable] provided to the constructor in the `repaint` argument, if
  /// it was not null.
  @override
  void removeListener(VoidCallback listener) => _repaint?.removeListener(listener);

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is the size of the [size] argument.
  ///
  /// Paint operations should remain inside the given area. Graphical operations
  /// outside the bounds may be silently ignored, clipped, or not clipped.
  ///
  /// Implementations should be wary of correctly pairing any calls to
  /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
  /// subsequent painting on this canvas may be affected, with potentially
  /// hilarious but confusing results.
  ///
  /// To paint text on a [Canvas], use a [TextPainter].
  ///
  /// To paint an image on a [Canvas]:
  ///
  /// 1. Obtain an [ImageStream], for example by calling [ImageProvider.resolve]
  ///    on an [AssetImage] or [NetworkImage] object.
  ///
  /// 2. Whenever the [ImageStream]'s underlying [ImageInfo] object changes
  ///    (see [ImageStream.addListener]), create a new instance of your custom
  ///    paint delegate, giving it the new [ImageInfo] object.
  ///
  /// 3. In your delegate's [paint] method, call the [Canvas.drawImage],
  ///    [Canvas.drawImageRect], or [Canvas.drawImageNine] methods to paint the
  ///    [ImageInfo.image] object, applying the [ImageInfo.scale] value to
  ///    obtain the correct rendering size.
  void paint(Canvas canvas, Size size);

  /// Called whenever a new instance of the custom painter delegate class is
  /// provided to the [RenderCustomPaint] object, or any time that a new
  /// [CustomPaint] object is created with a new instance of the custom painter
  /// delegate class (which amounts to the same thing, because the latter is
  /// implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away.
  ///
  /// It's possible that the [paint] method will get called even if
  /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
  /// be repainted). It's also possible that the [paint] method will get called
  /// without [shouldRepaint] being called at all (e.g. if the box changes
  /// size).
  ///
  /// If a custom delegate has a particularly expensive paint function such that
  /// repaints should be avoided as much as possible, a [RepaintBoundary] or
  /// [RenderRepaintBoundary] (or other render object with
  /// [RenderObject.isRepaintBoundary] set to true) might be helpful.
  bool shouldRepaint(covariant CustomPainter oldDelegate);

  /// Called whenever a hit test is being performed on an object that is using
  /// this custom paint delegate.
  ///
  /// The given point is relative to the same coordinate space as the last
  /// [paint] call.
  ///
  /// The default behavior is to consider all points to be hits for
  /// background painters, and no points to be hits for foreground painters.
  ///
  /// Return true if the given position corresponds to a point on the drawn
  /// image that should be considered a "hit", false if it corresponds to a
  /// point that should be considered outside the painted image, and null to use
  /// the default behavior.
  bool hitTest(Offset position) => null;

  @override
  String toString() => '$runtimeType#$hashCode(${ _repaint?.toString() ?? "" })';
}

/// Provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [RenderCustomPaint] first asks its [painter] to paint
/// on the current canvas, then it paints its child, and then, after painting
/// its child, it asks its [foregroundPainter] to paint. The coodinate system of
/// the canvas matches the coordinate system of the [CustomPaint] object. The
/// painters are expected to paint within a rectangle starting at the origin and
/// encompassing a region of the given size. (If the painters paint outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.)
///
/// Painters are implemented by subclassing or implementing [CustomPainter].
///
/// Because custom paint calls its painters during paint, you cannot mark the
/// tree as needing a new layout during the callback (the layout for this frame
/// has already happened).
///
/// Custom painters normally size themselves to their child. If they do not have
/// a child, they attempt to size themselves to the [preferredSize], which
/// defaults to [Size.zero].
///
/// See also:
///
///  * [CustomPainter], the class that custom painter delegates should extend.
///  * [Canvas], the API provided to custom painter delegates.
class RenderCustomPaint extends RenderProxyBox {
  /// Creates a render object that delegates its painting.
  RenderCustomPaint({
    CustomPainter painter,
    CustomPainter foregroundPainter,
    Size preferredSize: Size.zero,
    RenderBox child,
  }) : _painter = painter,
       _foregroundPainter = foregroundPainter,
       _preferredSize = preferredSize,
       super(child) {
    assert(preferredSize != null);
  }

  /// The background custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint behind the children.
  CustomPainter get painter => _painter;
  CustomPainter _painter;
  /// Set a new background custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [CustomPainter.shouldRepaint] called; if the result is
  /// true, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no background custom painter.
  set painter(CustomPainter value) {
    if (_painter == value)
      return;
    final CustomPainter oldPainter = _painter;
    _painter = value;
    _didUpdatePainter(_painter, oldPainter);
  }

  /// The foreground custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint in front of the children.
  CustomPainter get foregroundPainter => _foregroundPainter;
  CustomPainter _foregroundPainter;
  /// Set a new foreground custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [CustomPainter.shouldRepaint] called; if the result is
  /// true, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no foreground custom painter.
  set foregroundPainter(CustomPainter value) {
    if (_foregroundPainter == value)
      return;
    final CustomPainter oldPainter = _foregroundPainter;
    _foregroundPainter = value;
    _didUpdatePainter(_foregroundPainter, oldPainter);
  }

  void _didUpdatePainter(CustomPainter newPainter, CustomPainter oldPainter) {
    if (newPainter == null) {
      assert(oldPainter != null); // We should be called only for changes.
      markNeedsPaint();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newPainter?.addListener(markNeedsPaint);
    }
  }

  /// The size that this [RenderCustomPaint] should aim for, given the layout
  /// constraints, if there is no child.
  ///
  /// Defaults to [Size.zero].
  ///
  /// If there's a child, this is ignored, and the size of the child is used
  /// instead.
  Size get preferredSize => _preferredSize;
  Size _preferredSize;
  set preferredSize(Size value) {
    assert(value != null);
    if (preferredSize == value)
      return;
    _preferredSize = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
    _foregroundPainter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    _foregroundPainter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    if (_foregroundPainter != null && (_foregroundPainter.hitTest(position) ?? false))
      return true;
    return super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return _painter != null && (_painter.hitTest(position) ?? true);
  }

  @override
  void performResize() {
    size = constraints.constrain(preferredSize);
  }

  void _paintWithPainter(Canvas canvas, Offset offset, CustomPainter painter) {
    int debugPreviousCanvasSaveCount;
    canvas.save();
    assert(() { debugPreviousCanvasSaveCount = canvas.getSaveCount(); return true; });
    canvas.translate(offset.dx, offset.dy);
    painter.paint(canvas, size);
    assert(() {
      // This isn't perfect. For example, we can't catch the case of
      // someone first restoring, then setting a transform or whatnot,
      // then saving.
      // If this becomes a real problem, we could add logic to the
      // Canvas class to lock the canvas at a particular save count
      // such that restore() fails if it would take the lock count
      // below that number.
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      if (debugNewCanvasSaveCount > debugPreviousCanvasSaveCount) {
        throw new FlutterError(
          'The $painter custom painter called canvas.save() or canvas.saveLayer() at least '
          '${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount} more '
          'time${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount == 1 ? '' : 's' } '
          'than it called canvas.restore().\n'
          'This leaves the canvas in an inconsistent state and will probably result in a broken display.\n'
          'You must pair each call to save()/saveLayer() with a later matching call to restore().'
        );
      }
      if (debugNewCanvasSaveCount < debugPreviousCanvasSaveCount) {
        throw new FlutterError(
          'The $painter custom painter called canvas.restore() '
          '${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount} more '
          'time${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount == 1 ? '' : 's' } '
          'than it called canvas.save() or canvas.saveLayer().\n'
          'This leaves the canvas in an inconsistent state and will result in a broken display.\n'
          'You should only call restore() if you first called save() or saveLayer().'
        );
      }
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    });
    canvas.restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null)
      _paintWithPainter(context.canvas, offset, _painter);
    super.paint(context, offset);
    if (_foregroundPainter != null)
      _paintWithPainter(context.canvas, offset, _foregroundPainter);
  }
}

/// Signature for listening to [PointerDownEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerDownEventListener(PointerDownEvent event);

/// Signature for listening to [PointerMoveEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerMoveEventListener(PointerMoveEvent event);

/// Signature for listening to [PointerUpEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerUpEventListener(PointerUpEvent event);

/// Signature for listening to [PointerCancelEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
typedef void PointerCancelEventListener(PointerCancelEvent event);

/// Calls callbacks in response to pointer events.
///
/// If it has a child, defers to the child for sizing behavior.
///
/// If it does not have a child, grows to fit the parent-provided constraints.
class RenderPointerListener extends RenderProxyBoxWithHitTestBehavior {
  /// Creates a render object that forwards point events to callbacks.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  RenderPointerListener({
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    HitTestBehavior behavior: HitTestBehavior.deferToChild,
    RenderBox child
  }) : super(behavior: behavior, child: child);

  /// Called when a pointer comes into contact with the screen at this object.
  PointerDownEventListener onPointerDown;

  /// Called when a pointer that triggered an [onPointerDown] changes position.
  PointerMoveEventListener onPointerMove;

  /// Called when a pointer that triggered an [onPointerDown] is no longer in
  /// contact with the screen.
  PointerUpEventListener onPointerUp;

  /// Called when the input from a pointer that triggered an [onPointerDown] is
  /// no longer directed towards this receiver.
  PointerCancelEventListener onPointerCancel;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (onPointerDown != null && event is PointerDownEvent)
      return onPointerDown(event);
    if (onPointerMove != null && event is PointerMoveEvent)
      return onPointerMove(event);
    if (onPointerUp != null && event is PointerUpEvent)
      return onPointerUp(event);
    if (onPointerCancel != null && event is PointerCancelEvent)
      return onPointerCancel(event);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    final List<String> listeners = <String>[];
    if (onPointerDown != null)
      listeners.add('down');
    if (onPointerMove != null)
      listeners.add('move');
    if (onPointerUp != null)
      listeners.add('up');
    if (onPointerCancel != null)
      listeners.add('cancel');
    if (listeners.isEmpty)
      listeners.add('<none>');
    description.add('listeners: ${listeners.join(", ")}');
  }
}

/// Creates a separate display list for its child.
///
/// This render object creates a separate display list for its child, which
/// can improve performance if the subtree repaints at different times than
/// the surrounding parts of the tree. Specifically, when the child does not
/// repaint but its parent does, we can re-use the display list we recorded
/// previously. Similarly, when the child repaints but the surround tree does
/// not, we can re-record its display list without re-recording the display list
/// for the surround tree.
///
/// In some cases, it is necessary to place _two_ (or more) repaint boundaries
/// to get a useful effect. Consider, for example, an e-mail application that
/// shows an unread count and a list of e-mails. Whenever a new e-mail comes in,
/// the list would update, but so would the unread count. If only one of these
/// two parts of the application was behind a repaint boundary, the entire
/// application would repaint each time. On the other hand, if both were behind
/// a repaint boundary, a new e-mail would only change those two parts of the
/// application and the rest of the application would not repaint.
///
/// To tell if a particular RenderRepaintBoundary is useful, run your
/// application in checked mode, interacting with it in typical ways, and then
/// call [debugDumpRenderTree]. Each RenderRepaintBoundary will include the
/// ratio of cases where the repaint boundary was useful vs the cases where it
/// was not. These counts can also be inspected programmatically using
/// [debugAsymmetricPaintCount] and [debugSymmetricPaintCount] respectively.
class RenderRepaintBoundary extends RenderProxyBox {
  /// Creates a repaint boundary around [child].
  RenderRepaintBoundary({ RenderBox child }) : super(child);

  @override
  bool get isRepaintBoundary => true;

  /// The number of times that this render object repainted at the same time as
  /// its parent. Repaint boundaries are only useful when the parent and child
  /// paint at different times. When both paint at the same time, the repaint
  /// boundary is redundant, and may be actually making performance worse.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// zero.
  ///
  /// Can be reset using [debugResetMetrics]. See [debugAsymmetricPaintCount]
  /// for the corresponding count of times where only the parent or only the
  /// child painted.
  int get debugSymmetricPaintCount => _debugSymmetricPaintCount;
  int _debugSymmetricPaintCount = 0;

  /// The number of times that either this render object repainted without the
  /// parent being painted, or the parent repainted without this object being
  /// painted. When a repaint boundary is used at a seam in the render tree
  /// where the parent tends to repaint at entirely different times than the
  /// child, it can improve performance by reducing the number of paint
  /// operations that have to be recorded each frame.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// zero.
  ///
  /// Can be reset using [debugResetMetrics]. See [debugSymmetricPaintCount] for
  /// the corresponding count of times where both the parent and the child
  /// painted together.
  int get debugAsymmetricPaintCount => _debugAsymmetricPaintCount;
  int _debugAsymmetricPaintCount = 0;

  /// Resets the [debugSymmetricPaintCount] and [debugAsymmetricPaintCount]
  /// counts to zero.
  ///
  /// Only valid when asserts are enabled. Does nothing in release builds.
  void debugResetMetrics() {
    assert(() {
      _debugSymmetricPaintCount = 0;
      _debugAsymmetricPaintCount = 0;
      return true;
    });
  }

  @override
  void debugRegisterRepaintBoundaryPaint({ bool includedParent: true, bool includedChild: false }) {
    assert(() {
      if (includedParent && includedChild)
        _debugSymmetricPaintCount += 1;
      else
        _debugAsymmetricPaintCount += 1;
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    bool inReleaseMode = true;
    assert(() {
      inReleaseMode = false;
      if (debugSymmetricPaintCount + debugAsymmetricPaintCount == 0) {
        description.add('usefulness ratio: no metrics collected yet (never painted)');
      } else {
        final double percentage = 100.0 * debugAsymmetricPaintCount / (debugSymmetricPaintCount + debugAsymmetricPaintCount);
        String diagnosis;
        if (debugSymmetricPaintCount + debugAsymmetricPaintCount < 5) {
          diagnosis = 'insufficient data to draw conclusion (less than five repaints)';
        } else if (percentage > 90.0) {
          diagnosis = 'this is an outstandingly useful repaint boundary and should definitely be kept';
        } else if (percentage > 50.0) {
          diagnosis = 'this is a useful repaint boundary and should be kept';
        } else if (percentage > 30.0) {
          diagnosis = 'this repaint boundary is probably useful, but maybe it would be more useful in tandem with adding more repaint boundaries elsewhere';
        } else if (percentage > 10.0) {
          diagnosis = 'this repaint boundary does sometimes show value, though currently not that often';
        } else if (debugAsymmetricPaintCount == 0) {
          diagnosis = 'this repaint boundary is astoundingly ineffectual and should be removed';
        } else {
          diagnosis = 'this repaint boundary is not very effective and should probably be removed';
        }
        description.add('metrics: ${percentage.toStringAsFixed(1)}% useful ($debugSymmetricPaintCount bad vs $debugAsymmetricPaintCount good)');
        description.add('diagnosis: $diagnosis');
      }
      return true;
    });
    if (inReleaseMode)
      description.add('(run in checked mode to collect repaint boundary statistics)');
  }
}

/// A render object that is invisible during hit testing.
///
/// When [ignoring] is true, this render object (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events, because its render
/// object returns false from [hitTest].
///
/// When [ignoringSemantics] is true, the subtree will be invisible to
/// the semantics layer (and thus e.g. accessibility tools). If
/// [ignoringSemantics] is null, it uses the value of [ignoring].
///
/// See also:
///
///  * [RenderAbsorbPointer], which takes the pointer events but prevents any
///    nodes in the subtree from seeing them.
class RenderIgnorePointer extends RenderProxyBox {
  /// Creates a render object that is invisible to hit testing.
  ///
  /// The [ignoring] argument must not be null. If [ignoringSemantics], this
  /// render object will be ignored for semantics if [ignoring] is true.
  RenderIgnorePointer({
    RenderBox child,
    bool ignoring: true,
    bool ignoringSemantics
  }) : _ignoring = ignoring, _ignoringSemantics = ignoringSemantics, super(child) {
    assert(_ignoring != null);
  }

  /// Whether this render object is ignored during hit testing.
  ///
  /// Regardless of whether this render object is ignored during hit testing, it
  /// will still consume space during layout and be visible during painting.
  bool get ignoring => _ignoring;
  bool _ignoring;
  set ignoring(bool value) {
    assert(value != null);
    if (value == _ignoring)
      return;
    _ignoring = value;
    if (ignoringSemantics == null)
      markNeedsSemanticsUpdate();
  }

  /// Whether the semantics of this render object is ignored when compiling the semantics tree.
  ///
  /// If null, defaults to value of [ignoring].
  ///
  /// See [SemanticsNode] for additional information about the semantics tree.
  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  set ignoringSemantics(bool value) {
    if (value == _ignoringSemantics)
      return;
    final bool oldEffectiveValue = _effectiveIgnoringSemantics;
    _ignoringSemantics = value;
    if (oldEffectiveValue != _effectiveIgnoringSemantics)
      markNeedsSemanticsUpdate();
  }

  bool get _effectiveIgnoringSemantics => ignoringSemantics == null ? ignoring : ignoringSemantics;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    return ignoring ? false : super.hitTest(result, position: position);
  }

  // TODO(ianh): figure out a way to still include labels and flags in
  // descendants, just make them non-interactive, even when
  // _effectiveIgnoringSemantics is true
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && !_effectiveIgnoringSemantics)
      visitor(child);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('ignoring: $ignoring');
    description.add('ignoringSemantics: ${ ignoringSemantics == null ? "implicitly " : "" }$_effectiveIgnoringSemantics');
  }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class RenderOffstage extends RenderProxyBox {
  /// Creates an offstage render object.
  RenderOffstage({
    bool offstage: true,
    RenderBox child
  }) : _offstage = offstage, super(child) {
    assert(offstage != null);
  }

  /// Whether the child is hidden from the rest of the tree.
  ///
  /// If true, the child is laid out as if it was in the tree, but without
  /// painting anything, without making the child available for hit testing, and
  /// without taking any room in the parent.
  ///
  /// If false, the child is included in the tree as normal.
  bool get offstage => _offstage;
  bool _offstage;
  set offstage(bool value) {
    assert(value != null);
    if (value == _offstage)
      return;
    _offstage = value;
    markNeedsLayoutForSizedByParentChange();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (offstage)
      return 0.0;
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (offstage)
      return 0.0;
    return super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (offstage)
      return 0.0;
    return super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (offstage)
      return 0.0;
    return super.computeMaxIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (offstage)
      return null;
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool get sizedByParent => offstage;

  @override
  void performResize() {
    assert(offstage);
    size = constraints.smallest;
  }

  @override
  void performLayout() {
    if (offstage) {
      child?.layout(constraints);
    } else {
      super.performLayout();
    }
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    return !offstage && super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (offstage)
      return;
    super.paint(context, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (offstage)
      return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('offstage: $offstage');
  }
}

/// A render object that absorbs pointers during hit testing.
///
/// When [absorbing] is true, this render object prevents its subtree from
/// receiving pointer events by terminating hit testing at itself. It still
/// consumes space during layout and paints its child as usual. It just prevents
/// its children from being the target of located events, because its render
/// object returns true from [hitTest].
///
/// See also:
///
///  * [RenderIgnorePointer], which has the opposite effect: removing the
///    subtree from considering entirely for the purposes of hit testing.
class RenderAbsorbPointer extends RenderProxyBox {
  /// Creates a render object that absorbs pointers during hit testing.
  ///
  /// The [absorbing] argument must not be null.
  RenderAbsorbPointer({
    RenderBox child,
    this.absorbing: true
  }) : super(child) {
    assert(absorbing != null);
  }

  /// Whether this render object absorbs pointers during hit testing.
  ///
  /// Regardless of whether this render object absorbs pointers during hit
  /// testing, it will still consume space during layout and be visible during
  /// painting.
  bool absorbing;

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    return absorbing ? true : super.hitTest(result, position: position);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('absorbing: $absorbing');
  }
}

/// Holds opaque meta data in the render tree.
///
/// Useful for decorating the render tree with information that will be consumed
/// later. For example, you could store information in the render tree that will
/// be used when the user interacts with the render tree but has no visual
/// impact prior to the interaction.
class RenderMetaData extends RenderProxyBoxWithHitTestBehavior {
  /// Creates a render object that hold opaque meta data.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  RenderMetaData({
    this.metaData,
    HitTestBehavior behavior: HitTestBehavior.deferToChild,
    RenderBox child
  }) : super(behavior: behavior, child: child);

  /// Opaque meta data ignored by the render tree
  dynamic metaData;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('metaData: $metaData');
  }
}

/// Listens for the specified gestures from the semantics server (e.g.
/// an accessibility tool).
class RenderSemanticsGestureHandler extends RenderProxyBox implements SemanticsActionHandler {
  /// Creates a render object that listens for specific semantic gestures.
  ///
  /// The [scrollFactor] argument must not be null.
  RenderSemanticsGestureHandler({
    RenderBox child,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    GestureDragUpdateCallback onHorizontalDragUpdate,
    GestureDragUpdateCallback onVerticalDragUpdate,
    this.scrollFactor: 0.8
  }) : assert(scrollFactor != null),
       _onTap = onTap,
       _onLongPress = onLongPress,
       _onHorizontalDragUpdate = onHorizontalDragUpdate,
       _onVerticalDragUpdate = onVerticalDragUpdate,
       super(child);

   /// Called when the user taps on the render object.
  GestureTapCallback get onTap => _onTap;
  GestureTapCallback _onTap;
  set onTap(GestureTapCallback value) {
    if (_onTap == value)
      return;
    final bool wasSemanticBoundary = isSemanticBoundary;
    final bool hadHandler = _onTap != null;
    _onTap = value;
    if ((value != null) != hadHandler)
      markNeedsSemanticsUpdate(onlyChanges: isSemanticBoundary == wasSemanticBoundary);
  }

  /// Called when the user presses on the render object for a long period of time.
  GestureLongPressCallback get onLongPress => _onLongPress;
  GestureLongPressCallback _onLongPress;
  set onLongPress(GestureLongPressCallback value) {
    if (_onLongPress == value)
      return;
    final bool wasSemanticBoundary = isSemanticBoundary;
    final bool hadHandler = _onLongPress != null;
    _onLongPress = value;
    if ((value != null) != hadHandler)
      markNeedsSemanticsUpdate(onlyChanges: isSemanticBoundary == wasSemanticBoundary);
  }

  /// Called when the user scrolls to the left or to the right.
  GestureDragUpdateCallback get onHorizontalDragUpdate => _onHorizontalDragUpdate;
  GestureDragUpdateCallback _onHorizontalDragUpdate;
  set onHorizontalDragUpdate(GestureDragUpdateCallback value) {
    if (_onHorizontalDragUpdate == value)
      return;
    final bool wasSemanticBoundary = isSemanticBoundary;
    final bool hadHandler = _onHorizontalDragUpdate != null;
    _onHorizontalDragUpdate = value;
    if ((value != null) != hadHandler)
      markNeedsSemanticsUpdate(onlyChanges: isSemanticBoundary == wasSemanticBoundary);
  }

  /// Called when the user scrolls up or down.
  GestureDragUpdateCallback get onVerticalDragUpdate => _onVerticalDragUpdate;
  GestureDragUpdateCallback _onVerticalDragUpdate;
  set onVerticalDragUpdate(GestureDragUpdateCallback value) {
    if (_onVerticalDragUpdate == value)
      return;
    final bool wasSemanticBoundary = isSemanticBoundary;
    final bool hadHandler = _onVerticalDragUpdate != null;
    _onVerticalDragUpdate = value;
    if ((value != null) != hadHandler)
      markNeedsSemanticsUpdate(onlyChanges: isSemanticBoundary == wasSemanticBoundary);
  }

  /// The fraction of the dimension of this render box to use when
  /// scrolling. For example, if this is 0.8 and the box is 200 pixels
  /// wide, then when a left-scroll action is received from the
  /// accessibility system, it will translate into a 160 pixel
  /// leftwards drag.
  double scrollFactor;

  @override
  bool get isSemanticBoundary {
    return onTap != null
        || onLongPress != null
        || onHorizontalDragUpdate != null
        || onVerticalDragUpdate != null;
  }

  @override
  SemanticsAnnotator get semanticsAnnotator => isSemanticBoundary ? _annotate : null;

  void _annotate(SemanticsNode node) {
    if (onTap != null)
      node.addAction(SemanticsAction.tap);
    if (onLongPress != null)
      node.addAction(SemanticsAction.longPress);
    if (onHorizontalDragUpdate != null)
      node.addHorizontalScrollingActions();
    if (onVerticalDragUpdate != null)
      node.addVerticalScrollingActions();
  }

  @override
  void performAction(SemanticsAction action) {
    switch (action) {
      case SemanticsAction.tap:
        if (onTap != null)
          onTap();
        break;
      case SemanticsAction.longPress:
        if (onLongPress != null)
          onLongPress();
        break;
      case SemanticsAction.scrollLeft:
        if (onHorizontalDragUpdate != null) {
          final double primaryDelta = size.width * -scrollFactor;
          onHorizontalDragUpdate(new DragUpdateDetails(
            delta: new Offset(primaryDelta, 0.0), primaryDelta: primaryDelta,
            globalPosition: localToGlobal(size.center(Offset.zero)),
          ));
        }
        break;
      case SemanticsAction.scrollRight:
        if (onHorizontalDragUpdate != null) {
          final double primaryDelta = size.width * scrollFactor;
          onHorizontalDragUpdate(new DragUpdateDetails(
            delta: new Offset(primaryDelta, 0.0), primaryDelta: primaryDelta,
            globalPosition: localToGlobal(size.center(Offset.zero)),
          ));
        }
        break;
      case SemanticsAction.scrollUp:
        if (onVerticalDragUpdate != null) {
          final double primaryDelta = size.height * -scrollFactor;
          onVerticalDragUpdate(new DragUpdateDetails(
            delta: new Offset(0.0, primaryDelta), primaryDelta: primaryDelta,
            globalPosition: localToGlobal(size.center(Offset.zero)),
          ));
        }
        break;
      case SemanticsAction.scrollDown:
        if (onVerticalDragUpdate != null) {
          final double primaryDelta = size.height * scrollFactor;
          onVerticalDragUpdate(new DragUpdateDetails(
            delta: new Offset(0.0, primaryDelta), primaryDelta: primaryDelta,
            globalPosition: localToGlobal(size.center(Offset.zero)),
          ));
        }
        break;
      case SemanticsAction.increase:
      case SemanticsAction.decrease:
        assert(false);
        break;
    }
  }
}

/// Add annotations to the [SemanticsNode] for this subtree.
class RenderSemanticsAnnotations extends RenderProxyBox {
  /// Creates a render object that attaches a semantic annotation.
  ///
  /// The [container] argument must not be null.
  RenderSemanticsAnnotations({
    RenderBox child,
    bool container: false,
    bool checked,
    String label
  }) : _container = container,
       _checked = checked,
       _label = label,
       super(child) {
    assert(container != null);
  }

  /// If 'container' is true, this RenderObject will introduce a new
  /// node in the semantics tree. Otherwise, the semantics will be
  /// merged with the semantics of any ancestors.
  ///
  /// The 'container' flag is implicitly set to true on the immediate
  /// semantics-providing descendants of a node where multiple
  /// children have semantics or have descendants providing semantics.
  /// In other words, the semantics of siblings are not merged. To
  /// merge the semantics of an entire subtree, including siblings,
  /// you can use a [RenderMergeSemantics].
  bool get container => _container;
  bool _container;
  set container(bool value) {
    assert(value != null);
    if (container == value)
      return;
    _container = value;
    markNeedsSemanticsUpdate();
  }

  /// If non-null, sets the "hasCheckedState" semantic to true and the
  /// "isChecked" semantic to the given value.
  bool get checked => _checked;
  bool _checked;
  set checked(bool value) {
    if (checked == value)
      return;
    final bool hadValue = checked != null;
    _checked = value;
    markNeedsSemanticsUpdate(onlyChanges: (value != null) == hadValue);
  }

  /// If non-null, sets the "label" semantic to the given value.
  String get label => _label;
  String _label;
  set label(String value) {
    if (label == value)
      return;
    final bool hadValue = label != null;
    _label = value;
    markNeedsSemanticsUpdate(onlyChanges: (value != null) == hadValue);
  }

  @override
  bool get isSemanticBoundary => container;

  @override
  SemanticsAnnotator get semanticsAnnotator => checked != null || label != null ? _annotate : null;

  void _annotate(SemanticsNode node) {
    if (checked != null) {
      node
        ..hasCheckedState = true
        ..isChecked = checked;
    }
    if (label != null)
      node.label = label;
  }
}

/// Causes the semantics of all descendants to be merged into this
/// node such that the entire subtree becomes a single leaf in the
/// semantics tree.
///
/// Useful for combining the semantics of multiple render objects that
/// form part of a single conceptual widget, e.g. a checkbox, a label,
/// and the gesture detector that goes with them.
class RenderMergeSemantics extends RenderProxyBox {
  /// Creates a render object that merges the semantics from its descendants.
  RenderMergeSemantics({ RenderBox child }) : super(child);

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode node) {
    node.mergeAllDescendantsIntoThisNode = true;
  }
}

/// Excludes this subtree from the semantic tree.
///
/// When [excluding] is true, this render object (and its subtree) is excluded
/// from the semantic tree.
///
/// Useful e.g. for hiding text that is redundant with other text next
/// to it (e.g. text included only for the visual effect).
class RenderExcludeSemantics extends RenderProxyBox {
  /// Creates a render object that ignores the semantics of its subtree.
  RenderExcludeSemantics({
    RenderBox child,
    bool excluding: true,
  }) : _excluding = excluding, super(child) {
    assert(_excluding != null);
  }

  /// Whether this render object is excluded from the semantic tree.
  bool get excluding => _excluding;
  bool _excluding;
  set excluding(bool value) {
    assert(value != null);
    if (value == _excluding)
      return;
    _excluding = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (excluding)
      return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('excluding: $excluding');
  }
}
