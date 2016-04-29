// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image, ImageFilter;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'debug.dart';
import 'framework.dart';

export 'package:flutter/animation.dart';
export 'package:flutter/painting.dart';
export 'package:flutter/rendering.dart' show
    Axis,
    BoxConstraints,
    CrossAxisAlignment,
    CustomClipper,
    CustomPainter,
    FixedColumnCountGridDelegate,
    FlexDirection,
    FlowDelegate,
    FlowPaintingContext,
    FractionalOffsetTween,
    GridDelegate,
    GridDelegateWithInOrderChildPlacement,
    GridSpecification,
    HitTestBehavior,
    MainAxisAlignment,
    MaxTileWidthGridDelegate,
    MultiChildLayoutDelegate,
    PaintingContext,
    PlainTextSpan,
    PointerCancelEvent,
    PointerCancelEventListener,
    PointerDownEvent,
    PointerDownEventListener,
    PointerEvent,
    PointerMoveEvent,
    PointerMoveEventListener,
    PointerUpEvent,
    PointerUpEventListener,
    RelativeRect,
    RenderObjectPainter,
    ShaderCallback,
    SingleChildLayoutDelegate,
    ValueChanged,
    ViewportAnchor,
    ViewportDimensions,
    ViewportDimensionsChangeCallback;

// PAINTING NODES

/// Makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// For values of opacity other than 0.0 and 1.0, this class is relatively
/// expensive because it requires painting the child into an intermediate
/// buffer. For the value 0.0, the child is simply not painted at all. For the
/// value 1.0, the child is painted immediately without an intermediate buffer.
class Opacity extends SingleChildRenderObjectWidget {
  Opacity({ Key key, this.opacity, Widget child })
    : super(key: key, child: child) {
    assert(opacity != null && opacity >= 0.0 && opacity <= 1.0);
  }

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
  final double opacity;

  @override
  RenderOpacity createRenderObject(BuildContext context) => new RenderOpacity(opacity: opacity);

  @override
  void updateRenderObject(BuildContext context, RenderOpacity renderObject) {
    renderObject.opacity = opacity;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('opacity: $opacity');
  }
}

class ShaderMask extends SingleChildRenderObjectWidget {
  ShaderMask({
    Key key,
    this.shaderCallback,
    this.transferMode: TransferMode.modulate,
    Widget child
  }) : super(key: key, child: child) {
    assert(shaderCallback != null);
    assert(transferMode != null);
  }

  final ShaderCallback shaderCallback;
  final TransferMode transferMode;

  @override
  RenderShaderMask createRenderObject(BuildContext context) {
    return new RenderShaderMask(
      shaderCallback: shaderCallback,
      transferMode: transferMode
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderShaderMask renderObject) {
    renderObject
      ..shaderCallback = shaderCallback
      ..transferMode = transferMode;
  }
}

class BackdropFilter extends SingleChildRenderObjectWidget {
  BackdropFilter({
    Key key,
    this.filter,
    Widget child
  }) : super(key: key, child: child) {
    assert(filter != null);
  }

  final ui.ImageFilter filter;

  @override
  RenderBackdropFilter createRenderObject(BuildContext context) {
    return new RenderBackdropFilter(filter: filter);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBackdropFilter renderObject) {
    renderObject.filter = filter;
  }
}

/// Paints a [Decoration] either before or after its child paints.
/// Container insets its child by the widths of the borders, this Widget does not.
///
/// Commonly used with [BoxDecoration].
class DecoratedBox extends SingleChildRenderObjectWidget {
  DecoratedBox({
    Key key,
    this.decoration,
    this.position: DecorationPosition.background,
    Widget child
  }) : super(key: key, child: child) {
    assert(decoration != null);
    assert(position != null);
  }

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  final Decoration decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  @override
  RenderDecoratedBox createRenderObject(BuildContext context) => new RenderDecoratedBox(decoration: decoration, position: position);

  @override
  void updateRenderObject(BuildContext context, RenderDecoratedBox renderObject) {
    renderObject
      ..decoration = decoration
      ..position = position;
  }
}

/// Provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [CustomPaint] objects first ask their [painter] to
/// paint on the current canvas, then they paint their children, and then, after
/// painting their children, ask their [foregroundPainter] to paint. The
/// coodinate system of the canvas matches the coordinate system of the
/// [CustomPaint] object. The painters are expected to paint within a rectangle
/// starting at the origin and encompassing a region of the given size. (If the
/// painters paints outside those bounds, there might be insufficient memory
/// allocated to rasterize the painting commands and the resulting behavior is
/// undefined.)
///
/// Painters are implemented by subclassing [CustomPainter].
///
/// Because custom paint calls its painters during paint, you cannot mark the
/// tree as needing a new layout during the callback (the layout for this frame
/// has already happened).
///
/// See: [CustomPainter], [Canvas].
class CustomPaint extends SingleChildRenderObjectWidget {
  CustomPaint({ Key key, this.painter, this.foregroundPainter, Widget child })
    : super(key: key, child: child);

  /// The painter that paints before the children.
  final CustomPainter painter;

  /// The painter that paints after the children.
  final CustomPainter foregroundPainter;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) => new RenderCustomPaint(
    painter: painter,
    foregroundPainter: foregroundPainter
  );

  @override
  void updateRenderObject(BuildContext context, RenderCustomPaint renderObject) {
    renderObject
      ..painter = painter
      ..foregroundPainter = foregroundPainter;
  }

  @override
  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}

/// Clips its child using a rectangle.
///
/// Prevents its child from painting outside its bounds.
class ClipRect extends SingleChildRenderObjectWidget {
  ClipRect({ Key key, this.clipper, Widget child }) : super(key: key, child: child);

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect> clipper;

  @override
  RenderClipRect createRenderObject(BuildContext context) => new RenderClipRect(clipper: clipper);

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    renderObject.clipper = clipper;
  }

  @override
  void didUnmountRenderObject(RenderClipRect renderObject) {
    renderObject.clipper = null;
  }
}

/// Clips its child using a rounded rectangle.
///
/// Creates a rounded rectangle from its layout dimensions and the given x and
/// y radius values and prevents its child from painting outside that rounded
/// rectangle.
class ClipRRect extends SingleChildRenderObjectWidget {
  ClipRRect({ Key key, this.xRadius, this.yRadius, Widget child })
    : super(key: key, child: child);

  /// The radius of the rounded corners in the horizontal direction in logical pixels.
  ///
  /// Values are clamped to be between zero and half the width of the render
  /// object.
  final double xRadius;

  /// The radius of the rounded corners in the vertical direction in logical pixels.
  ///
  /// Values are clamped to be between zero and half the height of the render
  /// object.
  final double yRadius;

  @override
  RenderClipRRect createRenderObject(BuildContext context) => new RenderClipRRect(xRadius: xRadius, yRadius: yRadius);

  @override
  void updateRenderObject(BuildContext context, RenderClipRRect renderObject) {
    renderObject
      ..xRadius = xRadius
      ..yRadius = yRadius;
  }
}

/// Clips its child using an oval.
///
/// Inscribes an oval into its layout dimensions and prevents its child from
/// painting outside that oval.
class ClipOval extends SingleChildRenderObjectWidget {
  ClipOval({ Key key, this.clipper, Widget child }) : super(key: key, child: child);

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect> clipper;

  @override
  RenderClipOval createRenderObject(BuildContext context) => new RenderClipOval(clipper: clipper);

  @override
  void updateRenderObject(BuildContext context, RenderClipOval renderObject) {
    renderObject.clipper = clipper;
  }

  @override
  void didUnmountRenderObject(RenderClipOval renderObject) {
    renderObject.clipper = null;
  }
}


// POSITIONING AND SIZING NODES

/// Applies a transformation before painting its child.
class Transform extends SingleChildRenderObjectWidget {
  Transform({ Key key, this.transform, this.origin, this.alignment, this.transformHitTests: true, Widget child })
    : super(key: key, child: child) {
    assert(transform != null);
  }

  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system (relative to the upper left corder of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as an offset, both are applied.
  final FractionalOffset alignment;

  /// Whether to apply the translation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderTransform createRenderObject(BuildContext context) => new RenderTransform(
    transform: transform,
    origin: origin,
    alignment: alignment,
    transformHitTests: transformHitTests
  );

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..transformHitTests = transformHitTests;
  }
}

/// Applies a translation expressed as a fraction of the box's size before
/// painting its child.
class FractionalTranslation extends SingleChildRenderObjectWidget {
  FractionalTranslation({ Key key, this.translation, this.transformHitTests: true, Widget child })
    : super(key: key, child: child) {
    assert(translation != null);
  }

  /// The offset by which to translate the child, as a multiple of its size.
  final FractionalOffset translation;

  /// Whether to apply the translation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderFractionalTranslation createRenderObject(BuildContext context) => new RenderFractionalTranslation(translation: translation, transformHitTests: transformHitTests);

  @override
  void updateRenderObject(BuildContext context, RenderFractionalTranslation renderObject) {
    renderObject
      ..translation = translation
      ..transformHitTests = transformHitTests;
  }
}

/// Rotates its child by a integral number of quarter turns.
///
/// Unlike [Transform], which applies a transform just prior to painting,
/// this object applies its rotation prior to layout, which means the entire
/// rotated box consumes only as much space as required by the rotated child.
class RotatedBox extends SingleChildRenderObjectWidget {
  RotatedBox({ Key key, this.quarterTurns, Widget child })
    : super(key: key, child: child) {
    assert(quarterTurns != null);
  }

  /// The number of clockwise quarter turns the child should be rotated.
  final int quarterTurns;

  @override
  RenderRotatedBox createRenderObject(BuildContext context) => new RenderRotatedBox(quarterTurns: quarterTurns);

  @override
  void updateRenderObject(BuildContext context, RenderRotatedBox renderObject) {
    renderObject.quarterTurns = quarterTurns;
  }
}

/// Insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
class Padding extends SingleChildRenderObjectWidget {
  Padding({ Key key, this.padding, Widget child })
    : super(key: key, child: child) {
    assert(padding != null);
  }

  /// The amount of space by which to inset the child.
  final EdgeInsets padding;

  @override
  RenderPadding createRenderObject(BuildContext context) => new RenderPadding(padding: padding);

  @override
  void updateRenderObject(BuildContext context, RenderPadding renderObject) {
    renderObject.padding = padding;
  }
}

/// Aligns its child box within itself.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [FractionalOffset.bottomRight].
///
/// By default, sizes to be as big as possible in both axes. If either axis is
/// unconstrained, then in that direction it will be sized to fit the child's
/// dimensions. Using widthFactor and heightFactor you can force this latter
/// behavior in all cases.
///
/// See also:
///
///  * [CustomSingleChildLayout]
///  * [Center] (which is the same as [Align] but with the [alignment] always
///    set to [FractionalOffset.center])
class Align extends SingleChildRenderObjectWidget {
  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [FractionalOffset.center].
  Align({
    Key key,
    this.alignment: FractionalOffset.center,
    this.widthFactor,
    this.heightFactor,
    Widget child
  }) : super(key: key, child: child) {
    assert(alignment != null && alignment.dx != null && alignment.dy != null);
    assert(widthFactor == null || widthFactor >= 0.0);
    assert(heightFactor == null || heightFactor >= 0.0);
  }

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively.  An x value of 0.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.5 means that the center of the child is aligned
  /// with the center of the parent.
  final FractionalOffset alignment;

  /// If non-null, sets its width to the child's width multipled by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double widthFactor;

  /// If non-null, sets its height to the child's height multipled by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double heightFactor;

  @override
  RenderPositionedBox createRenderObject(BuildContext context) => new RenderPositionedBox(alignment: alignment, widthFactor: widthFactor, heightFactor: heightFactor);

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
    if (widthFactor != null)
      description.add('widthFactor: $widthFactor');
    if (heightFactor != null)
      description.add('heightFactor: $heightFactor');
  }
}

/// Centers its child within itself.
///
/// See also:
///
///  * [Align]
class Center extends Align {
  Center({ Key key, double widthFactor, double heightFactor, Widget child })
    : super(key: key, widthFactor: widthFactor, heightFactor: heightFactor, child: child);
}

/// Defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
///
/// See also:
///
///  * [SingleChildLayoutDelegate]
///  * [Align] (which positions a single child according to a [FractionalOffset])
///  * [CustomMultiChildLayout] (which uses a delegate to position multiple
///    children)
class CustomSingleChildLayout extends SingleChildRenderObjectWidget {
  /// Creates a custom single child layout.
  ///
  /// The delegate argument must not be null.
  CustomSingleChildLayout({
    Key key,
    this.delegate,
    Widget child
  }) : super(key: key, child: child) {
    assert(delegate != null);
  }

  /// The delegate that controls the layout of the child.
  final SingleChildLayoutDelegate delegate;

  @override
  RenderCustomSingleChildLayoutBox createRenderObject(BuildContext context) => new RenderCustomSingleChildLayoutBox(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderCustomSingleChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// Metadata for identifying children in a [CustomMultiChildLayout].
class LayoutId extends ParentDataWidget<CustomMultiChildLayout> {
  /// Marks a child with a layout identifier.
  ///
  /// Both the child and the id arguments must not be null.
  LayoutId({
    Key key,
    Widget child,
    Object id
  }) : id = id, super(key: key ?? new ValueKey<Object>(id), child: child) {
    assert(child != null);
    assert(id != null);
  }

  /// An object representing the identity of this child.
  final Object id;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is MultiChildLayoutParentData);
    final MultiChildLayoutParentData parentData = renderObject.parentData;
    if (parentData.id != id) {
      parentData.id = id;
      AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('id: $id');
  }
}

const List<Widget> _emptyWidgetList = const <Widget>[];

/// Defers the layout of multiple children to a delegate.
///
/// The delegate can determine the layout constraints for each child and can
/// decide where to position each child. The delegate can also determine the
/// size of the parent, but the size of the parent cannot depend on the sizes of
/// the children.
///
/// See also:
///
/// * [MultiChildLayoutDelegate]
/// * [CustomSingleChildLayout]
/// * [Stack]
/// * [Flow]
class CustomMultiChildLayout extends MultiChildRenderObjectWidget {
  /// Creates a custom multi-child layout.
  ///
  /// The delegate argument must not be null.
  CustomMultiChildLayout({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.delegate
  }) : super(key: key, children: children) {
    assert(delegate != null);
  }

  /// The delegate that controls the layout of the children.
  final MultiChildLayoutDelegate delegate;

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return new RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomMultiChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// A box with a specified size.
///
/// If given a child, this widget forces its child to have a specific width
/// and/or height (assuming values are permitted by this widget's parent). If
/// either the width or height is null, this widget will size itself to match
/// the child's size in that dimension.
///
/// If not given a child, this widget will size itself to the given width and
/// height, treating nulls as zero.
class SizedBox extends SingleChildRenderObjectWidget {
  SizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  /// If non-null, requires the child to have exactly this width.
  final double width;

  /// If non-null, requires the child to have exactly this height.
  final double height;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) => new RenderConstrainedBox(
    additionalConstraints: _additionalConstraints
  );

  BoxConstraints get _additionalConstraints {
    return new BoxConstraints.tightFor(width: width, height: height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }
}

/// Imposes additional constraints on its child.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)`` as the
/// [additionalConstraints].
class ConstrainedBox extends SingleChildRenderObjectWidget {
  ConstrainedBox({ Key key, this.constraints, Widget child })
    : super(key: key, child: child) {
    assert(constraints != null);
  }

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) => new RenderConstrainedBox(additionalConstraints: constraints);

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = constraints;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$constraints');
  }
}

/// Sizes itself to a fraction of the total available space.
///
/// See [RenderFractionallySizedOverflowBox] for details.
class FractionallySizedBox extends SingleChildRenderObjectWidget {
  FractionallySizedBox({
    Key key,
    this.alignment: FractionalOffset.center,
    this.width,
    this.height,
    Widget child
  }) : super(key: key, child: child) {
    assert(alignment != null && alignment.dx != null && alignment.dy != null);
  }

  /// If non-null, the factor of the incoming width to use.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multipled by this factor.
  final double width;

  /// If non-null, the factor of the incoming height to use.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming height constraint multipled by this factor.
  final double height;

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively.  An x value of 0.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.5 means that the center of the child is aligned
  /// with the center of the parent.
  final FractionalOffset alignment;

  @override
  RenderFractionallySizedOverflowBox createRenderObject(BuildContext context) => new RenderFractionallySizedOverflowBox(
    alignment: alignment,
    widthFactor: width,
    heightFactor: height
  );

  @override
  void updateRenderObject(BuildContext context, RenderFractionallySizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = width
      ..heightFactor = height;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }
}

/// A box that limits its size only when it's unconstrained.
///
/// If this widget's maximum width is unconstrained then its child's width is
/// limited to maxWidth. Similarly, if this widget's maximum height is unconstrained
/// then its child's height is limited to to maxHeight.
class LimitedBox extends SingleChildRenderObjectWidget {
  LimitedBox({ Key key, this.maxWidth: double.INFINITY, this.maxHeight: double.INFINITY, Widget child })
    : super(key: key, child: child) {
    assert(maxWidth != null && maxWidth >= 0.0);
    assert(maxHeight != null && maxHeight >= 0.0);
  }

  /// The maximum width limit to apply in the absence of a maxWidth constraint.
  final double maxWidth;

  /// The maximum height limit to apply in the absence of a maxHeight constraint.
  final double maxHeight;

  @override
  RenderLimitedBox createRenderObject(BuildContext context) => new RenderLimitedBox(
    maxWidth: maxWidth,
    maxHeight: maxHeight
  );

  @override
  void updateRenderObject(BuildContext context, RenderLimitedBox renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight;
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

/// A render object that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// See [RenderOverflowBox] for details.
class OverflowBox extends SingleChildRenderObjectWidget {
  OverflowBox({
    Key key,
    this.alignment: FractionalOffset.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    Widget child
  }) : super(key: key, child: child);

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively.  An x value of 0.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.5 means that the center of the child is aligned
  /// with the center of the parent.
  final FractionalOffset alignment;

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double minWidth;

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double maxWidth;

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double minHeight;

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double maxHeight;

  @override
  RenderConstrainedOverflowBox createRenderObject(BuildContext context) => new RenderConstrainedOverflowBox(
    alignment: alignment,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight
  );

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
    if (minWidth != null)
      description.add('minWidth: $minWidth');
    if (maxWidth != null)
      description.add('maxWidth: $maxWidth');
    if (minHeight != null)
      description.add('minHeight: $minHeight');
    if (maxHeight != null)
      description.add('maxHeight: $maxHeight');
  }
}

class SizedOverflowBox extends SingleChildRenderObjectWidget {
  SizedOverflowBox({
    Key key,
    this.alignment: FractionalOffset.center,
    this.size,
    Widget child
  }) : super(key: key, child: child) {
    assert(alignment != null && alignment.dx != null && alignment.dy != null);
  }

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively.  An x value of 0.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.5 means that the center of the child is aligned
  /// with the center of the parent.
  final FractionalOffset alignment;

  final Size size;

  @override
  RenderSizedOverflowBox createRenderObject(BuildContext context) {
    return new RenderSizedOverflowBox(
      alignment: alignment,
      requestedSize: size
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..requestedSize = size;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('alignment: $alignment');
    if (size != null)
      description.add('size: $size');
  }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class OffStage extends SingleChildRenderObjectWidget {
  OffStage({ Key key, Widget child })
    : super(key: key, child: child);

  @override
  RenderOffStage createRenderObject(BuildContext context) => new RenderOffStage();
}

/// Attempts to size the child to a specific aspect ratio.
///
/// The widget first tries the largest width permited by the layout
/// constraints. The height of the widget is determined by applying the
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
/// be at most 100.0 pixels tall. The widget will then take that value
/// and apply the aspect ratio again to obtain a width of 50.0. That width is
/// permitted by the constraints and the child receives a width of 50.0 and a
/// height of 100.0. If the width were not permitted, the widget would
/// continue iterating through the constraints. If the widget does not
/// find a feasible size after consulting each constraint, the widget
/// will eventually select a size for the child that meets the layout
/// constraints but fails to meet the aspect ratio constraints.
class AspectRatio extends SingleChildRenderObjectWidget {
  AspectRatio({ Key key, this.aspectRatio, Widget child })
    : super(key: key, child: child) {
    assert(aspectRatio != null);
  }

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) => new RenderAspectRatio(aspectRatio: aspectRatio);

  @override
  void updateRenderObject(BuildContext context, RenderAspectRatio renderObject) {
    renderObject.aspectRatio = aspectRatio;
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
class IntrinsicWidth extends SingleChildRenderObjectWidget {
  IntrinsicWidth({ Key key, this.stepWidth, this.stepHeight, Widget child })
    : super(key: key, child: child);

  /// If non-null, force the child's width to be a multiple of this value.
  final double stepWidth;

  /// If non-null, force the child's height to be a multiple of this value.
  final double stepHeight;

  @override
  RenderIntrinsicWidth createRenderObject(BuildContext context) => new RenderIntrinsicWidth(stepWidth: stepWidth, stepHeight: stepHeight);

  @override
  void updateRenderObject(BuildContext context, RenderIntrinsicWidth renderObject) {
    renderObject
      ..stepWidth = stepWidth
      ..stepHeight = stepHeight;
  }
}

/// Sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// This class is relatively expensive. Avoid using it where possible.
class IntrinsicHeight extends SingleChildRenderObjectWidget {
  IntrinsicHeight({ Key key, Widget child }) : super(key: key, child: child);

  @override
  RenderIntrinsicHeight createRenderObject(BuildContext context) => new RenderIntrinsicHeight();
}

/// Shifts the child down such that the child's baseline (or the
/// bottom of the child, if the child has no baseline) is [baseline]
/// logical pixels below the top of this box, then sizes this box to
/// contain the child. If [baseline] is less than the distance from
/// the top of the child to the baseline of the child, then the child
/// is top-aligned instead.
class Baseline extends SingleChildRenderObjectWidget {
  /// Creates a [Baseline] object.
  ///
  /// The [baseline] and [baselineType] arguments are required.
  Baseline({ Key key, this.baseline, this.baselineType, Widget child })
    : super(key: key, child: child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

  /// The number of logical pixels from the top of this box at which to position
  /// the child's baseline.
  final double baseline;

  /// The type of baseline to use for positioning the child.
  final TextBaseline baselineType;

  @override
  RenderBaseline createRenderObject(BuildContext context) => new RenderBaseline(baseline: baseline, baselineType: baselineType);

  @override
  void updateRenderObject(BuildContext context, RenderBaseline renderObject) {
    renderObject
      ..baseline = baseline
      ..baselineType = baselineType;
  }
}

/// A widget that's bigger on the inside.
///
/// The child of a viewport can layout to a larger size than the viewport
/// itself. If that happens, only a portion of the child will be visible through
/// the viewport. The portion of the child that is visible is controlled by the
/// scroll offset.
///
/// Viewport is the core scrolling primitive in the system, but it can be used
/// in other situations.
class Viewport extends SingleChildRenderObjectWidget {
  Viewport({
    Key key,
    this.paintOffset: Offset.zero,
    this.mainAxis: Axis.vertical,
    this.anchor: ViewportAnchor.start,
    this.overlayPainter,
    this.onPaintOffsetUpdateNeeded,
    Widget child
  }) : super(key: key, child: child) {
    assert(mainAxis != null);
    assert(paintOffset != null);
  }

  /// The offset at which to paint the child.
  ///
  /// The offset can be non-zero only in the [mainAxis].
  final Offset paintOffset;

  /// The direction in which the child is permitted to be larger than the viewport
  ///
  /// The child is given layout constraints that are fully unconstrainted along
  /// the main axis (e.g., the child can be as tall as it wants if the main axis
  /// is vertical).
  final Axis mainAxis;

  final ViewportAnchor anchor;

  /// Paints an overlay over the viewport.
  ///
  /// Often used to paint scroll bars.
  final RenderObjectPainter overlayPainter;

  /// Called when the interior or exterior dimensions of the viewport change.
  final ViewportDimensionsChangeCallback onPaintOffsetUpdateNeeded;

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return new RenderViewport(
      paintOffset: paintOffset,
      mainAxis: mainAxis,
      anchor: anchor,
      onPaintOffsetUpdateNeeded: onPaintOffsetUpdateNeeded,
      overlayPainter: overlayPainter
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    // Order dependency: RenderViewport validates scrollOffset based on mainAxis.
    renderObject
      ..mainAxis = mainAxis
      ..anchor = anchor
      ..paintOffset = paintOffset
      ..onPaintOffsetUpdateNeeded = onPaintOffsetUpdateNeeded
      ..overlayPainter = overlayPainter;
  }
}


// CONTAINER

/// A convenience widget that combines common painting, positioning, and sizing widgets.
class Container extends StatelessWidget {
  Container({
    Key key,
    this.child,
    BoxConstraints constraints,
    this.decoration,
    this.foregroundDecoration,
    this.margin,
    this.padding,
    this.transform,
    double width,
    double height
  }) : constraints =
        (width != null || height != null)
          ? constraints?.tighten(width: width, height: height)
            ?? new BoxConstraints.tightFor(width: width, height: height)
          : constraints,
       super(key: key) {
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
    assert(decoration == null || decoration.debugAssertValid());
  }

  /// The child contained by the container.
  ///
  /// If null, the container will expand to fill all available space in its parent.
  final Widget child;

  /// Additional constraints to apply to the child.
  final BoxConstraints constraints;

  /// The decoration to paint behind the child.
  final Decoration decoration;

  /// The decoration to paint in front of the child.
  final Decoration foregroundDecoration;

  /// Empty space to surround the decoration.
  final EdgeInsets margin;

  /// Empty space to inscribe inside the decoration.
  final EdgeInsets padding;

  /// The transformation matrix to apply before painting the container.
  final Matrix4 transform;

  EdgeInsets get _paddingIncludingDecoration {
    if (decoration == null || decoration.padding == null)
      return padding;
    EdgeInsets decorationPadding = decoration.padding;
    if (padding == null)
      return decorationPadding;
    return padding + decorationPadding;
  }

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    if (child == null && (constraints == null || !constraints.isTight))
      current = new ConstrainedBox(constraints: const BoxConstraints.expand());

    EdgeInsets effectivePadding = _paddingIncludingDecoration;
    if (effectivePadding != null)
      current = new Padding(padding: effectivePadding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (foregroundDecoration != null) {
      current = new DecoratedBox(
        decoration: foregroundDecoration,
        position: DecorationPosition.foreground,
        child: current
      );
    }

    if (constraints != null)
      current = new ConstrainedBox(constraints: constraints, child: current);

    if (margin != null)
      current = new Padding(padding: margin, child: current);

    if (transform != null)
      current = new Transform(transform: transform, child: current);

    return current;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (constraints != null)
      description.add('$constraints');
    if (decoration != null)
      description.add('bg: $decoration');
    if (foregroundDecoration != null)
      description.add('fg: $foregroundDecoration');
    if (margin != null)
      description.add('margin: $margin');
    if (padding != null)
      description.add('padding: $padding');
    if (transform != null)
      description.add('has transform');
  }
}


// LAYOUT NODES

/// Uses the block layout algorithm for its children.
///
/// This widget is rarely used directly. Instead, consider using [Block], which
/// combines the block layout algorithm with scrolling behavior.
///
/// For details about the block layout algorithm, see [RenderBlockBase].
class BlockBody extends MultiChildRenderObjectWidget {
  BlockBody({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.mainAxis: Axis.vertical
  }) : super(key: key, children: children) {
    assert(mainAxis != null);
  }

  /// The direction to use as the main axis.
  final Axis mainAxis;

  @override
  RenderBlock createRenderObject(BuildContext context) => new RenderBlock(mainAxis: mainAxis);

  @override
  void updateRenderObject(BuildContext context, RenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
  }
}

/// A base class for widgets that accept [Positioned] children.
abstract class StackRenderObjectWidgetBase extends MultiChildRenderObjectWidget {
  StackRenderObjectWidgetBase({
    List<Widget> children: _emptyWidgetList,
    Key key
  }) : super(key: key, children: children);
}

/// Uses the stack layout algorithm for its children.
///
/// This class is useful if you want to overlap several children in a
/// simple way, for example having some text and an image, overlaid
/// with a gradient and a button attached to the bottom.
///
/// If you want to lay a number of children out in a particular
/// pattern, or if you want to make a custom layout manager, you
/// probably want to use [CustomMultiChildLayout] instead. In
/// particular, when using a Stack you can't position children
/// relative to their size or the stack's own size.
///
/// For more details about the stack layout algorithm, see
/// [RenderStack]. To control the position of child widgets, see the
/// [Positioned] widget.
///
/// See also:
///
///  * [Flow]
///  * [Align] (which positions a single child according to a [FractionalOffset])
///  * [CustomSingleChildLayout]
///  * [CustomMultiChildLayout]
class Stack extends StackRenderObjectWidgetBase {
  Stack({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.alignment: FractionalOffset.topLeft
  }) : super(key: key, children: children);

  /// How to align the non-positioned children in the stack.
  final FractionalOffset alignment;

  @override
  RenderStack createRenderObject(BuildContext context) => new RenderStack(alignment: alignment);

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject.alignment = alignment;
  }
}

/// A [Stack] that shows a single child from a list of children.
class IndexedStack extends StackRenderObjectWidgetBase {
  IndexedStack({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.alignment: FractionalOffset.topLeft,
    this.index: 0
  }) : super(key: key, children: children) {
    assert(index != null);
  }

  /// The index of the child to show.
  final int index;

  /// How to align the non-positioned children in the stack.
  final FractionalOffset alignment;

  @override
  RenderIndexedStack createRenderObject(BuildContext context) => new RenderIndexedStack(index: index, alignment: alignment);

  @override
  void updateRenderObject(BuildContext context, RenderIndexedStack renderObject) {
    renderObject
      ..index = index
      ..alignment = alignment;
  }
}

/// Controls where a child of a [Stack] is positioned.
///
/// This widget must be a descendant of a [Stack], and the path from this widget
/// to its enclosing [Stack] must contain only [StatelessWidget]s or
/// [StatefulWidget]s (not other kinds of widgets, like [RenderObjectWidget]s).
class Positioned extends ParentDataWidget<StackRenderObjectWidgetBase> {
  /// Creates a Positioned object with the given values.
  ///
  /// Only two out of the three horizontal values ([left], [right],
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  Positioned({
    Key key,
    Widget child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height
  }) : super(key: key, child: child) {
    assert(left == null || right == null || width == null);
    assert(top == null || bottom == null || height == null);
  }

  /// Creates a Positioned object with the values from the given [Rect].
  ///
  /// This sets the [left], [top], [width], and [height] properties
  /// from the given [Rect]. The [right] and [bottom] properties are
  /// set to null.
  Positioned.fromRect({
    Key key,
    Widget child,
    Rect rect
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null,
       super(key: key, child: child);

  /// The distance that the child's left edge is inset from the left of the stack.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  final double left;

  /// The distance that the child's top edge is inset from the top of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double top;

  /// The distance that the child's right edge is inset from the right of the stack.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  final double right;

  /// The distance that the child's bottom edge is inset from the bottom of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double bottom;

  /// The child's width.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double height;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StackParentData);
    final StackParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.left != left) {
      parentData.left = left;
      needsLayout = true;
    }

    if (parentData.top != top) {
      parentData.top = top;
      needsLayout = true;
    }

    if (parentData.right != right) {
      parentData.right = right;
      needsLayout = true;
    }

    if (parentData.bottom != bottom) {
      parentData.bottom = bottom;
      needsLayout = true;
    }

    if (parentData.width != width) {
      parentData.width = width;
      needsLayout = true;
    }

    if (parentData.height != height) {
      parentData.height = height;
      needsLayout = true;
    }

    if (needsLayout) {
      AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (left != null)
      description.add('left: $left');
    if (top != null)
      description.add('top: $top');
    if (right != null)
      description.add('right: $right');
    if (bottom != null)
      description.add('bottom: $bottom');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }
}

abstract class GridRenderObjectWidgetBase extends MultiChildRenderObjectWidget {
  GridRenderObjectWidgetBase({
    List<Widget> children: _emptyWidgetList,
    Key key
  }) : super(key: key, children: children) {
    _delegate = createDelegate();
  }

  GridDelegate _delegate;

  /// The delegate that controls the layout of the children.
  GridDelegate createDelegate();

  @override
  RenderGrid createRenderObject(BuildContext context) => new RenderGrid(delegate: _delegate);

  @override
  void updateRenderObject(BuildContext context, RenderGrid renderObject) {
    renderObject.delegate = _delegate;
  }
}

/// Uses the grid layout algorithm for its children.
///
/// For details about the grid layout algorithm, see [RenderGrid].
class CustomGrid extends GridRenderObjectWidgetBase {
  CustomGrid({ Key key, List<Widget> children: _emptyWidgetList, this.delegate })
    : super(key: key, children: children) {
    assert(delegate != null);
  }

  /// The delegate that controls the layout of the children.
  final GridDelegate delegate;

  @override
  GridDelegate createDelegate() => delegate;
}

/// Uses a grid layout with a fixed column count.
///
/// For details about the grid layout algorithm, see [MaxTileWidthGridDelegate].
class FixedColumnCountGrid extends GridRenderObjectWidgetBase {
  FixedColumnCountGrid({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.columnCount,
    this.columnSpacing: 0.0,
    this.rowSpacing: 0.0,
    this.tileAspectRatio: 1.0,
    this.padding: EdgeInsets.zero
  }) : super(key: key, children: children) {
    assert(columnCount != null);
  }

  /// The number of columns in the grid.
  final int columnCount;

  /// The horizontal distance between columns.
  final double columnSpacing;

  /// The vertical distance between rows.
  final double rowSpacing;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  /// The amount of padding to apply to each child.
  final EdgeInsets padding;

  @override
  FixedColumnCountGridDelegate createDelegate() {
    return new FixedColumnCountGridDelegate(
      columnCount: columnCount,
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      tileAspectRatio: tileAspectRatio,
      padding: padding
    );
  }
}

/// Uses a grid layout with a max tile width.
///
/// For details about the grid layout algorithm, see [MaxTileWidthGridDelegate].
class MaxTileWidthGrid extends GridRenderObjectWidgetBase {
  MaxTileWidthGrid({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.maxTileWidth,
    this.columnSpacing: 0.0,
    this.rowSpacing: 0.0,
    this.tileAspectRatio: 1.0,
    this.padding: EdgeInsets.zero
  }) : super(key: key, children: children) {
    assert(maxTileWidth != null);
  }

  /// The maximum width of a tile in the grid.
  final double maxTileWidth;

  /// The ratio of the width to the height of each tile in the grid.
  final double tileAspectRatio;

  /// The horizontal distance between columns.
  final double columnSpacing;

  /// The vertical distance between rows.
  final double rowSpacing;

  /// The amount of padding to apply to each child.
  final EdgeInsets padding;

  @override
  MaxTileWidthGridDelegate createDelegate() {
    return new MaxTileWidthGridDelegate(
      maxTileWidth: maxTileWidth,
      tileAspectRatio: tileAspectRatio,
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      padding: padding
    );
  }
}

/// Supplies per-child data to the grid's [GridDelegate].
class GridPlacementData<DataType, WidgetType extends RenderObjectWidget> extends ParentDataWidget<WidgetType> {
  GridPlacementData({ Key key, this.placementData, Widget child })
    : super(key: key, child: child);

  /// Opaque data passed to the getChildPlacement method of the grid's [GridDelegate].
  final DataType placementData;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is GridParentData);
    final GridParentData parentData = renderObject.parentData;
    if (parentData.placementData != placementData) {
      parentData.placementData = placementData;
      AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('placementData: $placementData');
  }
}

/// Uses the flex layout algorithm for its children.
///
/// For details about the flex layout algorithm, see [RenderFlex]. To control
/// the flex of child widgets, see the [Flexible] widget.
class Flex extends MultiChildRenderObjectWidget {
  Flex({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.direction: FlexDirection.horizontal,
    this.mainAxisAlignment: MainAxisAlignment.start,
    this.crossAxisAlignment: CrossAxisAlignment.center,
    this.textBaseline
  }) : super(key: key, children: children) {
    assert(direction != null);
    assert(mainAxisAlignment != null);
    assert(crossAxisAlignment != null);
  }

  /// The direction to use as the main axis.
  final FlexDirection direction;

  /// How the children should be placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How the children should be placed along the cross axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// If aligning items according to their baseline, which baseline to use.
  final TextBaseline textBaseline;

  @override
  RenderFlex createRenderObject(BuildContext context) => new RenderFlex(direction: direction, mainAxisAlignment: mainAxisAlignment, crossAxisAlignment: crossAxisAlignment, textBaseline: textBaseline);

  @override
  void updateRenderObject(BuildContext context, RenderFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..crossAxisAlignment = crossAxisAlignment
      ..textBaseline = textBaseline;
  }
}

/// Lays out child elements in a row.
///
/// For details about the flex layout algorithm, see [RenderFlex]. To control
/// the flex of child widgets, see the [Flexible] widget.
class Row extends Flex {
  Row({
    Key key,
    List<Widget> children: _emptyWidgetList,
    MainAxisAlignment mainAxisAlignment: MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment: CrossAxisAlignment.center,
    TextBaseline textBaseline
  }) : super(
    children: children,
    key: key,
    direction: FlexDirection.horizontal,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textBaseline: textBaseline
  );
}

/// Lays out child elements in a column.
///
/// For details about the flex layout algorithm, see [RenderFlex]. To control
/// the flex of child widgets, see the [Flexible] widget.
class Column extends Flex {
  Column({
    Key key,
    List<Widget> children: _emptyWidgetList,
    MainAxisAlignment mainAxisAlignment: MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment: CrossAxisAlignment.center,
    TextBaseline textBaseline
  }) : super(
    children: children,
    key: key,
    direction: FlexDirection.vertical,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textBaseline: textBaseline
  );
}

/// Controls how a child of a [Flex], [Row], or [Column] flexes.
///
/// This widget must be a descendant of a [Flex], [Row], or [Column], and the
/// path from this widget to its enclosing [Flex], [Row], or [Column] must
/// contain only [StatelessWidget]s or [StatefulWidget]s (not other kinds of
/// widgets, like [RenderObjectWidget]s).
class Flexible extends ParentDataWidget<Flex> {
  Flexible({ Key key, this.flex: 1, Widget child })
    : super(key: key, child: child);

  /// The flex factor to use for this child
  ///
  /// If null, the child is inflexible and determines its own size. If non-null,
  /// the child is flexible and its extent in the main axis is determined by
  /// dividing the free space (after placing the inflexible children)
  /// according to the flex factors of the flexible children.
  final int flex;

  /// Whether to apply tight or loose constraints to this child if this child has a non-null [flex].
  ///
  /// Ignored if [flex] is null. If this property is null, the child will be
  /// given tight constraints.
  FlexConstraintType constraintType;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final FlexParentData parentData = renderObject.parentData;
    bool needsLayout = false;
    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }
    if (parentData.constraintType != constraintType) {
      parentData.constraintType = constraintType;
      needsLayout = true;
    }
    if (needsLayout) {
      AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('flex: $flex');
  }
}

/// Implements the flow layout algorithm.
///
/// Flow layouts are optimized for repositioning children using transformation
/// matrices.
///
/// The flow container is sized independently from the children by the
/// [FlowDelegate.getSize] function of the delegate. The children are then sized
/// independently given the constraints from the
/// [FlowDelegate.getConstraintsForChild] function.
///
/// Rather than positioning the children during layout, the children are
/// positioned using transformation matrices during the paint phase using the
/// matrices from the [FlowDelegate.paintChildren] function. The children can be
/// repositioned efficiently by simply repainting the flow.
///
/// The most efficient way to trigger a repaint of the flow is to supply a
/// repaint argument to the constructor of the [FlowDelegate]. The flow will
/// listen to this animation and repaint whenever the animation ticks, avoiding
/// both the build and layout phases of the pipeline.
///
/// See also:
///
///  * [FlowDelegate]
///  * [Stack]
///  * [CustomSingleChildLayout]
///  * [CustomMultiChildLayout]
class Flow extends MultiChildRenderObjectWidget {
  /// Creates a flow layout.
  ///
  /// Wraps each of the given children in a [RepaintBoundary] to avoid
  /// repainting the children when the flow repaints.
  Flow({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.delegate
  }) : super(key: key, children: RepaintBoundary.wrapAll(children)) {
    assert(delegate != null);
  }

  /// Creates a flow layout.
  ///
  /// Does not wrap the given children in repaint boundaries, unlike the default
  /// constructor. Useful when the child is trivial to paint or already contains
  /// a repaint boundary.
  Flow.unwrapped({
    Key key,
    List<Widget> children: _emptyWidgetList,
    this.delegate
  }) : super(key: key, children: children) {
    assert(delegate != null);
  }

  /// The delegate that controls the transformation matrices of the children.
  final FlowDelegate delegate;

  @override
  RenderFlow createRenderObject(BuildContext context) => new RenderFlow(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderFlow renderObject) {
    renderObject
      ..delegate = delegate;
  }
}

/// A paragraph of rich text.
///
/// The [RichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree. The text might
/// break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// Text displayed in a [RichText] widget must be explicitly styled. When
/// picking which style to use, consider using [DefaultTextStyle.of] the current
/// [BuildContext] to provide defaults.
///
/// When all the text uses the same style, consider using the [Text] widget,
/// which is less verbose and integrates with [DefaultTextStyle] for default
/// styling.
///
/// See also:
///
///  * [Text]
///  * [TextSpan]
///  * [DefaultTextStyle]
class RichText extends LeafRenderObjectWidget {
  /// Creates a paragraph of rich text.
  ///
  /// The [text] argument is required to be non-null.
  RichText({ Key key, this.text }) : super(key: key) {
    assert(text != null);
  }

  /// The text to display in this widget.
  final TextSpan text;

  @override
  RenderParagraph createRenderObject(BuildContext context) => new RenderParagraph(text);

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    renderObject.text = text;
  }
}

/// The text style to apply to descendant [Text] widgets without explicit style.
class DefaultTextStyle extends InheritedWidget {
  DefaultTextStyle({
    Key key,
    this.style,
    Widget child
  }) : super(key: key, child: child) {
    assert(style != null);
    assert(child != null);
  }

  /// The text style to apply.
  final TextStyle style;

  /// The style from the closest instance of this class that encloses the given context.
  static TextStyle of(BuildContext context) {
    DefaultTextStyle result = context.inheritFromWidgetOfExactType(DefaultTextStyle);
    return result?.style ?? const TextStyle();
  }

  @override
  bool updateShouldNotify(DefaultTextStyle old) => style != old.style;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    '$style'.split('\n').forEach(description.add);
  }
}

/// A run of text with a single style.
///
/// The [Text] widget displays a string of text with single style. The string
/// might break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// The [style] argument is optional. When omitted, the text will use the style
/// from the closest enclosing [DefaultTextStyle]. If the given style's
/// [TextStyle.inherit] property is true, the given style will be merged with
/// the closest enclosing [DefaultTextStyle]. This merging behavior is useful,
/// for example, to make the text bold while using the default font family and
/// size.
///
/// To display text that uses multiple styles (e.g., a paragraph with some bold
/// words), use [RichText].
///
/// See also:
///
///  * [RichText]
///  * [DefaultTextStyle]
class Text extends StatelessWidget {
  /// Creates a text widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  Text(this.data, { Key key, this.style }) : super(key: key) {
    assert(data != null);
  }

  /// The text to display.
  final String data;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle style;

  TextStyle _getEffectiveStyle(BuildContext context) {
    if (style == null || style.inherit)
      return DefaultTextStyle.of(context).merge(style);
    else
      return style;
  }

  @override
  Widget build(BuildContext context) {
    return new RichText(
      text: new TextSpan(
        style: _getEffectiveStyle(context),
        text: data
      )
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$data"');
    if (style != null)
      '$style'.split('\n').forEach(description.add);
  }
}

/// Displays a raw image.
///
/// This widget is rarely used directly. Instead, consider using [AssetImage] or
/// [NetworkImage], depending on whather you wish to display an image from the
/// assert bundle or from the network.
///
/// See also:
///
///  * [AssetImage]
///  * [NetworkImage]
class RawImage extends LeafRenderObjectWidget {
  RawImage({
    Key key,
    this.image,
    this.width,
    this.height,
    this.scale: 1.0,
    this.color,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  /// The image to display.
  final ui.Image image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// Specifies the image's scale.
  ///
  /// Used when determining the best display size for the image.
  final double scale;

  /// If non-null, apply this color filter to the image before painting.
  final Color color;

  /// How to inscribe the image into the place allocated during layout.
  final ImageFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  @override
  RenderImage createRenderObject(BuildContext context) => new RenderImage(
    image: image,
    width: width,
    height: height,
    scale: scale,
    color: color,
    fit: fit,
    alignment: alignment,
    repeat: repeat,
    centerSlice: centerSlice
  );

  @override
  void updateRenderObject(BuildContext context, RenderImage renderObject) {
    renderObject
      ..image = image
      ..width = width
      ..height = height
      ..scale = scale
      ..color = color
      ..alignment = alignment
      ..fit = fit
      ..repeat = repeat
      ..centerSlice = centerSlice;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('image: $image');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (scale != 1.0)
      description.add('scale: $scale');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}

/// Displays an [ImageResource].
///
/// An image resource differs from an image in that it might yet let be loaded
/// from the underlying storage (e.g., the asset bundle or the network) and it
/// might change over time (e.g., an animated image).
///
/// This widget is rarely used directly. Instead, consider using [AssetImage] or
/// [NetworkImage], depending on whather you wish to display an image from the
/// assert bundle or from the network.
class RawImageResource extends StatefulWidget {
  RawImageResource({
    Key key,
    this.image,
    this.width,
    this.height,
    this.color,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key) {
    assert(image != null);
  }

  /// The image to display.
  final ImageResource image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// If non-null, apply this color filter to the image before painting.
  final Color color;

  /// How to inscribe the image into the place allocated during layout.
  final ImageFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  @override
  _RawImageResourceState createState() => new _RawImageResourceState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('image: $image');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}

class _RawImageResourceState extends State<RawImageResource> {
  @override
  void initState() {
    super.initState();
    config.image.addListener(_handleImageChanged);
  }

  ImageInfo _resolvedImage;

  void _handleImageChanged(ImageInfo resolvedImage) {
    setState(() {
      _resolvedImage = resolvedImage;
    });
  }

  @override
  void dispose() {
    config.image.removeListener(_handleImageChanged);
    super.dispose();
  }

  @override
  void didUpdateConfig(RawImageResource oldConfig) {
    if (config.image != oldConfig.image) {
      oldConfig.image.removeListener(_handleImageChanged);
      config.image.addListener(_handleImageChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new RawImage(
      image: _resolvedImage?.image,
      width: config.width,
      height: config.height,
      scale: _resolvedImage == null ? 1.0 : _resolvedImage.scale,
      color: config.color,
      fit: config.fit,
      alignment: config.alignment,
      repeat: config.repeat,
      centerSlice: config.centerSlice
    );
  }
}

/// Displays an image loaded from the network.
class NetworkImage extends StatelessWidget {
  NetworkImage({
    Key key,
    this.src,
    this.width,
    this.height,
    this.scale : 1.0,
    this.color,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  /// The URL from which to load the image.
  final String src;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// Specifies the image's scale.
  ///
  /// Used when determining the best display size for the image.
  final double scale;

  /// If non-null, apply this color filter to the image before painting.
  final Color color;

  /// How to inscribe the image into the place allocated during layout.
  final ImageFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  @override
  Widget build(BuildContext context) {
    ImageResource imageResource = imageCache.load(src, scale: scale);
    return new RawImageResource(
      key: key == null ? new ObjectKey(imageResource) : null,
      image: imageResource,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('src: $src');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (scale != 1.0)
      description.add('scale: $scale');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}

/// Sets a default asset bundle for its descendants.
///
/// For example, used by [AssetImage] to determine which bundle to use if no
/// bundle is specified explicitly.
class DefaultAssetBundle extends InheritedWidget {
  DefaultAssetBundle({
    Key key,
    this.bundle,
    Widget child
  }) : super(key: key, child: child) {
    assert(bundle != null);
    assert(child != null);
  }

  /// The bundle to use as a default.
  final AssetBundle bundle;

  /// The bundle from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [DefaultAssetBundle] ancestor widget in the tree
  /// at the given context, then this will return the [rootBundle].
  /// The [rootBundle] does not automatically select images based on
  /// the current device pixel ratio. To get an asset bundle that
  /// automatically performs pixel-density-aware asset resolution, use
  /// a [MaterialApp], [WidgetsApp], or [AssetVendor] widget, which
  /// introduce a suitably-configured [DefaultAssetBundle] widget.
  static AssetBundle of(BuildContext context) {
    DefaultAssetBundle result = context.inheritFromWidgetOfExactType(DefaultAssetBundle);
    return result?.bundle ?? rootBundle;
  }

  @override
  bool updateShouldNotify(DefaultAssetBundle old) => bundle != old.bundle;
}

/// Displays an image provided by an [ImageProvider].
///
/// This widget lets you customize how images are loaded by supplying your own
/// image provider. Internally, [NetworkImage] uses an [ImageProvider] that
/// loads the image from the network.
class AsyncImage extends StatelessWidget {
  AsyncImage({
    Key key,
    this.provider,
    this.width,
    this.height,
    this.color,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  /// The object that will provide the image.
  final ImageProvider provider;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// If non-null, apply this color filter to the image before painting.
  final Color color;

  /// How to inscribe the image into the place allocated during layout.
  final ImageFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  @override
  Widget build(BuildContext context) {
    ImageResource imageResource = imageCache.loadProvider(provider);
    return new RawImageResource(
      key: key == null ? new ObjectKey(imageResource) : null,
      image: imageResource,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('provider: $provider');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}

/// Displays an image from an [AssetBundle].
///
/// By default, asset image will load the image from the closest enclosing
/// [DefaultAssetBundle].
///
/// To get an asset bundle that automatically performs
/// pixel-density-aware asset resolution, use a [MaterialApp],
/// [WidgetsApp], or [AssetVendor] widget, which introduce a
/// suitably-configured [DefaultAssetBundle] widget.
class AssetImage extends StatelessWidget {
  /// Creates an [AssetImage].
  ///
  /// The `name` argument must not be null.
  // Don't add asserts here unless absolutely necessary, since it will
  // require removing the const constructor, which is an API change.
  const AssetImage({
    Key key,
    @required this.name,
    this.bundle,
    this.width,
    this.height,
    this.color,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  /// The name of the image in the assert bundle.
  final String name;

  /// The bundle from which to load the image.
  ///
  /// If null, the image will be loaded from the closest enclosing
  /// [DefaultAssetBundle].
  final AssetBundle bundle;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// If non-null, apply this color filter to the image before painting.
  final Color color;

  /// How to inscribe the image into the place allocated during layout.
  final ImageFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  @override
  Widget build(BuildContext context) {
    ImageResource imageResource = (bundle ?? DefaultAssetBundle.of(context)).loadImage(name);
    return new RawImageResource(
      key: key == null ? new ObjectKey(imageResource) : null,
      image: imageResource,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('name: $name');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (color != null)
      description.add('color: $color');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
    if (bundle != null)
      description.add('bundle: $bundle');
  }
}

/// An adapter for placing a specific [RenderBox] in the widget tree.
///
/// A given render object can be placed at most once in the widget tree. This
/// widget enforces that restriction by keying itself using a [GlobalObjectKey]
/// for the given render object.
class WidgetToRenderBoxAdapter extends LeafRenderObjectWidget {
  WidgetToRenderBoxAdapter({ RenderBox renderBox, this.onBuild })
    : renderBox = renderBox,
      // WidgetToRenderBoxAdapter objects are keyed to their render box. This
      // prevents the widget being used in the widget hierarchy in two different
      // places, which would cause the RenderBox to get inserted in multiple
      // places in the RenderObject tree.
      super(key: new GlobalObjectKey(renderBox)) {
    assert(renderBox != null);
  }

  /// The render box to place in the widget tree.
  final RenderBox renderBox;

  /// Called when it is safe to update the render box and its descendants. If
  /// you update the RenderObject subtree under this widget outside of
  /// invocations of this callback, features like hit-testing will fail as the
  /// tree will be dirty.
  final VoidCallback onBuild;

  @override
  RenderBox createRenderObject(BuildContext context) => renderBox;

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    if (onBuild != null)
      onBuild();
  }
}


// EVENT HANDLING

class Listener extends SingleChildRenderObjectWidget {
  Listener({
    Key key,
    Widget child,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.behavior: HitTestBehavior.deferToChild
  }) : super(key: key, child: child) {
    assert(behavior != null);
  }

  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final HitTestBehavior behavior;

  @override
  RenderPointerListener createRenderObject(BuildContext context) => new RenderPointerListener(
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel,
    behavior: behavior
  );

  @override
  void updateRenderObject(BuildContext context, RenderPointerListener renderObject) {
    renderObject
      ..onPointerDown = onPointerDown
      ..onPointerMove = onPointerMove
      ..onPointerUp = onPointerUp
      ..onPointerCancel = onPointerCancel
      ..behavior = behavior;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    List<String> listeners = <String>[];
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

/// Creates a separate display list for its child.
///
/// This widget creates a separate display list for its child, which
/// can improve performance if the subtree repaints at different times than
/// the surrounding parts of the tree. Specifically, when the child does not
/// repaint but its parent does, we can re-use the display list we recorded
/// previously. Similarly, when the child repaints but the surround tree does
/// not, we can re-record its display list without re-recording the display list
/// for the surround tree.
class RepaintBoundary extends SingleChildRenderObjectWidget {
  RepaintBoundary({ Key key, Widget child }) : super(key: key, child: child);

  factory RepaintBoundary.wrap(Widget child, int childIndex) {
    Key key = child.key != null ? new ValueKey<Key>(child.key) : new ValueKey<int>(childIndex);
    return new RepaintBoundary(key: key, child: child);
  }

  static List<RepaintBoundary> wrapAll(List<Widget> widgets) {
    List<RepaintBoundary> result = new List<RepaintBoundary>(widgets.length);
    for (int i = 0; i < result.length; ++i)
      result[i] = new RepaintBoundary.wrap(widgets[i], i);
    return result;
  }

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) => new RenderRepaintBoundary();
}

class IgnorePointer extends SingleChildRenderObjectWidget {
  IgnorePointer({ Key key, Widget child, this.ignoring: true, this.ignoringSemantics })
    : super(key: key, child: child);

  final bool ignoring;
  final bool ignoringSemantics; // if null, defaults to value of ignoring

  @override
  RenderIgnorePointer createRenderObject(BuildContext context) => new RenderIgnorePointer(
    ignoring: ignoring,
    ignoringSemantics: ignoringSemantics
  );

  @override
  void updateRenderObject(BuildContext context, RenderIgnorePointer renderObject) {
    renderObject
      ..ignoring = ignoring
      ..ignoringSemantics = ignoringSemantics;
  }
}


// UTILITY NODES

/// The Semantics widget annotates the widget tree with a description
/// of the meaning of the widgets, so that accessibility tools, search
/// engines, and other semantic analysis software can determine the
/// meaning of the application.
class Semantics extends SingleChildRenderObjectWidget {
  Semantics({
    Key key,
    Widget child,
    this.container: false,
    this.checked,
    this.label
  }) : super(key: key, child: child) {
    assert(container != null);
  }

  /// If 'container' is true, this Widget will introduce a new node in
  /// the semantics tree. Otherwise, the semantics will be merged with
  /// the semantics of any ancestors.
  ///
  /// The 'container' flag is implicitly set to true on the immediate
  /// semantics-providing descendants of a node where multiple
  /// children have semantics or have descendants providing semantics.
  /// In other words, the semantics of siblings are not merged. To
  /// merge the semantics of an entire subtree, including siblings,
  /// you can use a [MergeSemantics] widget.
  final bool container;

  /// If non-null, indicates that this subtree represents a checkbox
  /// or similar widget with a "checked" state, and what its current
  /// state is.
  final bool checked;

  /// Provides a textual description of the widget.
  final String label;

  @override
  RenderSemanticAnnotations createRenderObject(BuildContext context) => new RenderSemanticAnnotations(
    container: container,
    checked: checked,
    label: label
  );

  @override
  void updateRenderObject(BuildContext context, RenderSemanticAnnotations renderObject) {
    renderObject
      ..container = container
      ..checked = checked
      ..label = label;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('container: $container');
    if (checked != null);
      description.add('checked: $checked');
    if (label != null);
      description.add('label: "$label"');
  }
}

/// Causes all the semantics of the subtree rooted at this node to be
/// merged into one node in the semantics tree. For example, if you
/// have a widget with a Text node next to a checkbox widget, this
/// could be used to merge the label from the Text node with the
/// "checked" semantic state of the checkbox into a single node that
/// had both the label and the checked state. Otherwise, the label
/// would be presented as a separate feature than the checkbox, and
/// the user would not be able to be sure that they were related.
///
/// Be aware that if two nodes in the subtree have conflicting
/// semantics, the result may be nonsensical. For example, a subtree
/// with a checked checkbox and an unchecked checkbox will be
/// presented as checked. All the labels will be merged into a single
/// string (with newlines separating each label from the other). If
/// multiple nodes in the merged subtree can handle semantic gestures,
/// the first one in tree order will be the one to receive the
/// callbacks.
class MergeSemantics extends SingleChildRenderObjectWidget {
  MergeSemantics({ Key key, Widget child }) : super(key: key, child: child);

  @override
  RenderMergeSemantics createRenderObject(BuildContext context) => new RenderMergeSemantics();
}

/// Drops all semantics in this subtree.
///
/// This can be used to hide subwidgets that would otherwise be
/// reported but that would only be confusing. For example, the
/// material library's [Chip] widget hides the avatar since it is
/// redundant with the chip label.
class ExcludeSemantics extends SingleChildRenderObjectWidget {
  ExcludeSemantics({ Key key, Widget child }) : super(key: key, child: child);

  @override
  RenderExcludeSemantics createRenderObject(BuildContext context) => new RenderExcludeSemantics();
}

class MetaData extends SingleChildRenderObjectWidget {
  MetaData({
    Key key,
    Widget child,
    this.metaData,
    this.behavior: HitTestBehavior.deferToChild
  }) : super(key: key, child: child);

  final dynamic metaData;
  final HitTestBehavior behavior;

  @override
  RenderMetaData createRenderObject(BuildContext context) => new RenderMetaData(
    metaData: metaData,
    behavior: behavior
  );

  @override
  void updateRenderObject(BuildContext context, RenderMetaData renderObject) {
    renderObject
      ..metaData = metaData
      ..behavior = behavior;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('behavior: $behavior');
    description.add('metaData: $metaData');
  }
}

/// Always builds the given child.
///
/// Useful for attaching a key to an existing widget.
class KeyedSubtree extends StatelessWidget {
  /// Creates a widget that always builds the given child.
  KeyedSubtree({ Key key, this.child })
    : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Creates a KeyedSubtree for child with a key that's based on the child's existing key or childIndex.
  factory KeyedSubtree.wrap(Widget child, int childIndex) {
    Key key = child.key != null ? new ValueKey<Key>(child.key) : new ValueKey<int>(childIndex);
    return new KeyedSubtree(key: key, child: child);
  }

  /// Wrap each item in a KeyedSubtree whose key is based on the item's existing key or
  /// its list index + baseIndex.
  static List<Widget> ensureUniqueKeysForList(Iterable<Widget> items, { int baseIndex: 0 }) {
    if (items == null || items.isEmpty)
      return items;

    List<Widget> itemsWithUniqueKeys = <Widget>[];
    int itemIndex = baseIndex;
    for (Widget item in items) {
      itemsWithUniqueKeys.add(new KeyedSubtree.wrap(item, itemIndex));
      itemIndex += 1;
    }

    assert(!debugItemsHaveDuplicateKeys(itemsWithUniqueKeys));
    return itemsWithUniqueKeys;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// A platonic widget that invokes a closure to obtain its child widget.
class Builder extends StatelessWidget {
  Builder({ Key key, this.builder }) : super(key: key);

  /// Called to obtain the child widget.
  ///
  /// This function is invoked whether this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

typedef Widget StatefulWidgetBuilder(BuildContext context, StateSetter setState);
class StatefulBuilder extends StatefulWidget {
  StatefulBuilder({ Key key, this.builder }) : super(key: key);

  final StatefulWidgetBuilder builder;

  @override
  _StatefulBuilderState createState() => new _StatefulBuilderState();
}
class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) => config.builder(context, setState);
}
