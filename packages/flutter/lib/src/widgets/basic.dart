// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'framework.dart';

export 'package:flutter/rendering.dart' show
    BackgroundImage,
    BlockDirection,
    Border,
    BorderSide,
    BoxConstraints,
    BoxDecoration,
    BoxShadow,
    BoxShape,
    Canvas,
    Color,
    ColorFilter,
    CustomClipper,
    CustomPainter,
    Decoration,
    DecorationPosition,
    EdgeDims,
    FlexAlignItems,
    FlexDirection,
    FlexJustifyContent,
    FontStyle,
    FontWeight,
    FractionalOffset,
    Gradient,
    HitTestBehavior,
    ImageFit,
    ImageRepeat,
    InputEvent,
    LinearGradient,
    Matrix4,
    Offset,
    OneChildLayoutDelegate,
    Paint,
    Path,
    PlainTextSpan,
    Point,
    PointerCancelEvent,
    PointerDownEvent,
    PointerEvent,
    PointerMoveEvent,
    PointerUpEvent,
    RadialGradient,
    Rect,
    ScrollDirection,
    Size,
    StyledTextSpan,
    TextAlign,
    TextBaseline,
    TextDecoration,
    TextDecorationStyle,
    TextSpan,
    TextStyle,
    TransferMode,
    ValueChanged,
    VoidCallback,
    bold,
    normal,
    underline,
    overline,
    lineThrough;


// PAINTING NODES

/// Makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// This class is relatively expensive because it requires painting the child
/// into an intermediate buffer.
class Opacity extends OneChildRenderObjectWidget {
  Opacity({ Key key, this.opacity, Widget child })
    : super(key: key, child: child) {
    assert(opacity >= 0.0 && opacity <= 1.0);
  }

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  final double opacity;

  RenderOpacity createRenderObject() => new RenderOpacity(opacity: opacity);

  void updateRenderObject(RenderOpacity renderObject, Opacity oldWidget) {
    renderObject.opacity = opacity;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('opacity: $opacity');
  }
}

class ShaderMask extends OneChildRenderObjectWidget {
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

  RenderShaderMask createRenderObject() {
    return new RenderShaderMask(
      shaderCallback: shaderCallback,
      transferMode: transferMode
    );
  }

  void updateRenderObject(RenderShaderMask renderObject, ShaderMask oldWidget) {
    renderObject.shaderCallback = shaderCallback;
    renderObject.transferMode = transferMode;
  }
}

/// Paints a [BoxDecoration] either before or after its child paints.
class DecoratedBox extends OneChildRenderObjectWidget {
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
  final Decoration decoration;

  /// Where to paint the box decoration.
  final DecorationPosition position;

  RenderDecoratedBox createRenderObject() => new RenderDecoratedBox(decoration: decoration, position: position);

  void updateRenderObject(RenderDecoratedBox renderObject, DecoratedBox oldWidget) {
    renderObject.decoration = decoration;
    renderObject.position = position;
  }
}

/// Delegates its painting.
///
/// When asked to paint, custom paint first asks painter to paint with the
/// current canvas and then paints its children. After painting its children,
/// custom paint asks foregroundPainter to paint. The coodinate system of the
/// canvas matches the coordinate system of the custom paint object. The
/// painters are expected to paint within a rectangle starting at the origin
/// and encompassing a region of the given size. If the painters paints outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.
///
/// Because custom paint calls its painters during paint, you cannot dirty
/// layout or paint information during the callback.
class CustomPaint extends OneChildRenderObjectWidget {
  CustomPaint({ Key key, this.painter, this.foregroundPainter, Widget child })
    : super(key: key, child: child);

  /// The painter that paints before the children.
  final CustomPainter painter;

  /// The painter that paints after the children.
  final CustomPainter foregroundPainter;

  RenderCustomPaint createRenderObject() => new RenderCustomPaint(
    painter: painter,
    foregroundPainter: foregroundPainter
  );

  void updateRenderObject(RenderCustomPaint renderObject, CustomPaint oldWidget) {
    renderObject.painter = painter;
    renderObject.foregroundPainter = foregroundPainter;
  }

  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject.painter = null;
    renderObject.foregroundPainter = null;
  }
}

/// Clips its child using a rectangle.
///
/// Prevents its child from painting outside its bounds.
class ClipRect extends OneChildRenderObjectWidget {
  ClipRect({ Key key, this.clipper, Widget child }) : super(key: key, child: child);

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect> clipper;

  RenderClipRect createRenderObject() => new RenderClipRect(clipper: clipper);

  void updateRenderObject(RenderClipRect renderObject, ClipRect oldWidget) {
    renderObject.clipper = clipper;
  }

  void didUnmountRenderObject(RenderClipRect renderObject) {
    renderObject.clipper = null;
  }
}

/// Clips its child using a rounded rectangle.
///
/// Creates a rounded rectangle from its layout dimensions and the given x and
/// y radius values and prevents its child from painting outside that rounded
/// rectangle.
class ClipRRect extends OneChildRenderObjectWidget {
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

  RenderClipRRect createRenderObject() => new RenderClipRRect(xRadius: xRadius, yRadius: yRadius);

  void updateRenderObject(RenderClipRRect renderObject, ClipRRect oldWidget) {
    renderObject.xRadius = xRadius;
    renderObject.yRadius = yRadius;
  }
}

/// Clips its child using an oval.
///
/// Inscribes an oval into its layout dimensions and prevents its child from
/// painting outside that oval.
class ClipOval extends OneChildRenderObjectWidget {
  ClipOval({ Key key, this.clipper, Widget child }) : super(key: key, child: child);

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect> clipper;

  RenderClipOval createRenderObject() => new RenderClipOval(clipper: clipper);

  void updateRenderObject(RenderClipOval renderObject, ClipOval oldWidget) {
    renderObject.clipper = clipper;
  }

  void didUnmountRenderObject(RenderClipOval renderObject) {
    renderObject.clipper = null;
  }
}


// POSITIONING AND SIZING NODES

/// Applies a transformation before painting its child.
class Transform extends OneChildRenderObjectWidget {
  Transform({ Key key, this.transform, this.origin, this.alignment, Widget child })
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
  /// If it is specificed at the same time as an offset, both are applied.
  final FractionalOffset alignment;

  RenderTransform createRenderObject() => new RenderTransform(transform: transform, origin: origin, alignment: alignment);

  void updateRenderObject(RenderTransform renderObject, Transform oldWidget) {
    renderObject.transform = transform;
    renderObject.origin = origin;
    renderObject.alignment = alignment;
  }
}

/// Insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
class Padding extends OneChildRenderObjectWidget {
  Padding({ Key key, this.padding, Widget child })
    : super(key: key, child: child) {
    assert(padding != null);
  }

  /// The amount to pad the child in each dimension.
  final EdgeDims padding;

  RenderPadding createRenderObject() => new RenderPadding(padding: padding);

  void updateRenderObject(RenderPadding renderObject, Padding oldWidget) {
    renderObject.padding = padding;
  }
}

/// Aligns its child box within itself.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with horizontal and vertical set to 1.0.
class Align extends OneChildRenderObjectWidget {
  Align({
    Key key,
    this.alignment: const FractionalOffset(0.5, 0.5),
    this.widthFactor,
    this.heightFactor,
    Widget child
  }) : super(key: key, child: child) {
    assert(alignment != null && alignment.x != null && alignment.y != null);
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

  RenderPositionedBox createRenderObject() => new RenderPositionedBox(alignment: alignment, widthFactor: widthFactor, heightFactor: heightFactor);

  void updateRenderObject(RenderPositionedBox renderObject, Align oldWidget) {
    renderObject.alignment = alignment;
    renderObject.widthFactor = widthFactor;
    renderObject.heightFactor = heightFactor;
  }
}

/// Centers its child within itself.
class Center extends Align {
  Center({ Key key, widthFactor, heightFactor, Widget child })
    : super(key: key, widthFactor: widthFactor, heightFactor: heightFactor, child: child);
}

/// Defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
class CustomOneChildLayout extends OneChildRenderObjectWidget {
  CustomOneChildLayout({
    Key key,
    this.delegate,
    this.token,
    Widget child
  }) : super(key: key, child: child) {
    assert(delegate != null);
  }

  /// A long-lived delegate that controls the layout of this widget.
  ///
  /// Whenever the delegate changes, we need to recompute the layout of this
  /// widget, which means you might not want to create a new delegate instance
  /// every time you build this widget. Instead, consider using a long-lived
  /// deletate (perhaps held in a component's state) that you re-use every time
  /// you build this widget.
  final OneChildLayoutDelegate delegate;
  final Object token;

  RenderCustomOneChildLayoutBox createRenderObject() => new RenderCustomOneChildLayoutBox(delegate: delegate);

  void updateRenderObject(RenderCustomOneChildLayoutBox renderObject, CustomOneChildLayout oldWidget) {
    if (oldWidget.token != token)
      renderObject.markNeedsLayout();
    renderObject.delegate = delegate;
  }
}

/// Metadata for identifying children in a [CustomMultiChildLayout].
class LayoutId extends ParentDataWidget {
  LayoutId({
    Key key,
    Widget child,
    Object id
  }) : id = id, super(key: key ?? new ValueKey(id), child: child) {
    assert(child != null);
    assert(id != null);
  }

  /// An object representing the identity of this child.
  final Object id;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'LayoutId must placed inside a CustomMultiChildLayout';
      return ancestor is CustomMultiChildLayout;
    });
  }

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

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('id: $id');
  }
}

/// Defers the layout of multiple children to a delegate.
///
/// The delegate can determine the layout constraints for each child and can
/// decide where to position each child. The delegate can also determine the
/// size of the parent, but the size of the parent cannot depend on the sizes of
/// the children.
class CustomMultiChildLayout extends MultiChildRenderObjectWidget {
  CustomMultiChildLayout(List<Widget> children, {
    Key key,
    this.delegate,
    this.token
  }) : super(key: key, children: children) {
    assert(delegate != null);
  }

  /// The delegate that controls the layout of the children.
  final MultiChildLayoutDelegate delegate;
  final Object token;

  RenderCustomMultiChildLayoutBox createRenderObject() {
    return new RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  void updateRenderObject(RenderCustomMultiChildLayoutBox renderObject, CustomMultiChildLayout oldWidget) {
    if (oldWidget.token != token)
      renderObject.markNeedsLayout();
    renderObject.delegate = delegate;
  }
}

/// A box with a specified size.
///
/// Forces its child to have a specific width and/or height and sizes itself to
/// match the size of its child.
class SizedBox extends OneChildRenderObjectWidget {
  SizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  /// If non-null, requires the child to have exactly this width.
  final double width;

  /// If non-null, requires the child to have exactly this height.
  final double height;

  RenderConstrainedBox createRenderObject() => new RenderConstrainedBox(
    additionalConstraints: _additionalConstraints
  );

  BoxConstraints get _additionalConstraints {
    BoxConstraints result = const BoxConstraints();
    if (width != null)
      result = result.tightenWidth(width);
    if (height != null)
      result = result.tightenHeight(height);
    return result;
  }

  void updateRenderObject(RenderConstrainedBox renderObject, SizedBox oldWidget) {
    renderObject.additionalConstraints = _additionalConstraints;
  }

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
class ConstrainedBox extends OneChildRenderObjectWidget {
  ConstrainedBox({ Key key, this.constraints, Widget child })
    : super(key: key, child: child) {
    assert(constraints != null);
  }

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  RenderConstrainedBox createRenderObject() => new RenderConstrainedBox(additionalConstraints: constraints);

  void updateRenderObject(RenderConstrainedBox renderObject, ConstrainedBox oldWidget) {
    renderObject.additionalConstraints = constraints;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$constraints');
  }
}

class FractionallySizedBox extends OneChildRenderObjectWidget {
  FractionallySizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  final double width;
  final double height;

  RenderFractionallySizedBox createRenderObject() => new RenderFractionallySizedBox(
    widthFactor: width,
    heightFactor: height
  );

  void updateRenderObject(RenderFractionallySizedBox renderObject, FractionallySizedBox oldWidget) {
    renderObject.widthFactor = width;
    renderObject.heightFactor = height;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }
}

class OverflowBox extends OneChildRenderObjectWidget {
  OverflowBox({ Key key, this.minWidth, this.maxWidth, this.minHeight, this.maxHeight, Widget child })
    : super(key: key, child: child);

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  RenderOverflowBox createRenderObject() => new RenderOverflowBox(
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight
  );

  void updateRenderObject(RenderOverflowBox renderObject, OverflowBox oldWidget) {
    renderObject.minWidth = minWidth;
    renderObject.maxWidth = maxWidth;
    renderObject.minHeight = minHeight;
    renderObject.maxHeight = maxHeight;
  }
}

class SizedOverflowBox extends OneChildRenderObjectWidget {
  SizedOverflowBox({ Key key, this.size, Widget child })
    : super(key: key, child: child);

  final Size size;

  RenderSizedOverflowBox createRenderObject() => new RenderSizedOverflowBox(requestedSize: size);

  void updateRenderObject(RenderSizedOverflowBox renderObject, SizedOverflowBox oldWidget) {
    renderObject.requestedSize = size;
  }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
class OffStage extends OneChildRenderObjectWidget {
  OffStage({ Key key, Widget child })
    : super(key: key, child: child);

  RenderOffStage createRenderObject() => new RenderOffStage();
}

class AspectRatio extends OneChildRenderObjectWidget {
  AspectRatio({ Key key, this.aspectRatio, Widget child })
    : super(key: key, child: child) {
    assert(aspectRatio != null);
  }

  final double aspectRatio;

  RenderAspectRatio createRenderObject() => new RenderAspectRatio(aspectRatio: aspectRatio);

  void updateRenderObject(RenderAspectRatio renderObject, AspectRatio oldWidget) {
    renderObject.aspectRatio = aspectRatio;
  }

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
class IntrinsicWidth extends OneChildRenderObjectWidget {
  IntrinsicWidth({ Key key, this.stepWidth, this.stepHeight, Widget child })
    : super(key: key, child: child);

  /// If non-null, force the child's width to be a multiple of this value.
  final double stepWidth;

  /// If non-null, force the child's height to be a multiple of this value.
  final double stepHeight;

  RenderIntrinsicWidth createRenderObject() => new RenderIntrinsicWidth(stepWidth: stepWidth, stepHeight: stepHeight);

  void updateRenderObject(RenderIntrinsicWidth renderObject, IntrinsicWidth oldWidget) {
    renderObject.stepWidth = stepWidth;
    renderObject.stepHeight = stepHeight;
  }
}

/// Sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// This class is relatively expensive. Avoid using it where possible.
class IntrinsicHeight extends OneChildRenderObjectWidget {
  IntrinsicHeight({ Key key, Widget child }) : super(key: key, child: child);
  RenderIntrinsicHeight createRenderObject() => new RenderIntrinsicHeight();
}

class Baseline extends OneChildRenderObjectWidget {
  Baseline({ Key key, this.baseline, this.baselineType: TextBaseline.alphabetic, Widget child })
    : super(key: key, child: child) {
    assert(baseline != null);
    assert(baselineType != null);
  }

  final double baseline; // in pixels
  final TextBaseline baselineType;

  RenderBaseline createRenderObject() => new RenderBaseline(baseline: baseline, baselineType: baselineType);

  void updateRenderObject(RenderBaseline renderObject, Baseline oldWidget) {
    renderObject.baseline = baseline;
    renderObject.baselineType = baselineType;
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
class Viewport extends OneChildRenderObjectWidget {
  Viewport({
    Key key,
    this.scrollDirection: ScrollDirection.vertical,
    this.scrollOffset: Offset.zero,
    Widget child
  }) : super(key: key, child: child) {
    assert(scrollDirection != null);
    assert(scrollOffset != null);
  }

  /// The direction in which the child is permitted to be larger than the viewport
  ///
  /// If the viewport is scrollable in a particular direction (e.g., vertically),
  /// the child is given layout constraints that are fully unconstrainted in
  /// that direction (e.g., the child can be as tall as it wants).
  final ScrollDirection scrollDirection;

  /// The offset at which to paint the child.
  ///
  /// The offset can be non-zero only in the [scrollDirection].
  final Offset scrollOffset;

  RenderViewport createRenderObject() => new RenderViewport(scrollDirection: scrollDirection, scrollOffset: scrollOffset);

  void updateRenderObject(RenderViewport renderObject, Viewport oldWidget) {
    // Order dependency: RenderViewport validates scrollOffset based on scrollDirection.
    renderObject.scrollDirection = scrollDirection;
    renderObject.scrollOffset = scrollOffset;
  }
}

/// Calls [onSizeChanged] whenever the child's layout size changes
///
/// Because size observer calls its callback during layout, you cannot modify
/// layout information during the callback.
class SizeObserver extends OneChildRenderObjectWidget {
  SizeObserver({ Key key, this.onSizeChanged, Widget child })
    : super(key: key, child: child) {
    assert(onSizeChanged != null);
  }

  /// The callback to call whenever the child's layout size changes
  final SizeChangedCallback onSizeChanged;

  RenderSizeObserver createRenderObject() => new RenderSizeObserver(onSizeChanged: onSizeChanged);

  void updateRenderObject(RenderSizeObserver renderObject, SizeObserver oldWidget) {
    renderObject.onSizeChanged = onSizeChanged;
  }

  void didUnmountRenderObject(RenderSizeObserver renderObject) {
    renderObject.onSizeChanged = null;
  }
}


// CONVENIENCE CLASS TO COMBINE COMMON PAINTING, POSITIONING, AND SIZING NODES

class Container extends StatelessComponent {

  Container({
    Key key,
    this.child,
    this.constraints,
    this.decoration,
    this.foregroundDecoration,
    this.margin,
    this.padding,
    this.transform,
    this.width,
    this.height
  }) : super(key: key) {
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
    assert(decoration == null || decoration.debugAssertValid());
  }

  final Widget child;
  final BoxConstraints constraints;
  final Decoration decoration;
  final Decoration foregroundDecoration;
  final EdgeDims margin;
  final EdgeDims padding;
  final Matrix4 transform;
  final double width;
  final double height;

  EdgeDims get _paddingIncludingDecoration {
    if (decoration == null || decoration.padding == null)
      return padding;
    EdgeDims decorationPadding = decoration.padding;
    if (padding == null)
      return decorationPadding;
    return padding + decorationPadding;
  }

  Widget build(BuildContext context) {
    Widget current = child;

    if (child == null && (width == null || height == null))
      current = new ConstrainedBox(constraints: const BoxConstraints.expand());

    EdgeDims effectivePadding = _paddingIncludingDecoration;
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

    if (width != null || height != null) {
      current = new SizedBox(
        width: width,
        height: height,
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

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (constraints != null)
      description.add('$constraints');
    if (decoration != null)
      description.add('has background');
    if (foregroundDecoration != null)
      description.add('has foreground');
    if (margin != null)
      description.add('margin: $margin');
    if (padding != null)
      description.add('padding: $padding');
    if (transform != null)
      description.add('has transform');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }

}


// LAYOUT NODES

class BlockBody extends MultiChildRenderObjectWidget {
  BlockBody(List<Widget> children, {
    Key key,
    this.direction: BlockDirection.vertical
  }) : super(key: key, children: children) {
    assert(direction != null);
  }

  final BlockDirection direction;

  RenderBlock createRenderObject() => new RenderBlock(direction: direction);

  void updateRenderObject(RenderBlock renderObject, BlockBody oldWidget) {
    renderObject.direction = direction;
  }
}

class Stack extends MultiChildRenderObjectWidget {
  Stack(List<Widget> children, {
    Key key,
    this.alignment: const FractionalOffset(0.0, 0.0)
  }) : super(key: key, children: children);

  final FractionalOffset alignment;

  RenderStack createRenderObject() => new RenderStack(alignment: alignment);

  void updateRenderObject(RenderStack renderObject, Stack oldWidget) {
    renderObject.alignment = alignment;
  }
}

class IndexedStack extends MultiChildRenderObjectWidget {
  IndexedStack(List<Widget> children, {
    Key key,
    this.alignment: const FractionalOffset(0.0, 0.0),
    this.index: 0
  }) : super(key: key, children: children);

  final int index;
  final FractionalOffset alignment;

  RenderIndexedStack createRenderObject() => new RenderIndexedStack(index: index, alignment: alignment);

  void updateRenderObject(RenderIndexedStack renderObject, IndexedStack oldWidget) {
    super.updateRenderObject(renderObject, oldWidget);
    renderObject.index = index;
    renderObject.alignment = alignment;
  }
}

class Positioned extends ParentDataWidget {
  Positioned({
    Key key,
    Widget child,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.width,
    this.height
  }) : super(key: key, child: child) {
    assert(top == null || bottom == null || height == null);
    assert(left == null || right == null || width == null);
  }

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

  final double top;
  final double right;
  final double bottom;
  final double left;

  final double width;
  final double height;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'Positioned must placed inside a Stack';
      return ancestor is Stack;
    });
  }

  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StackParentData);
    final StackParentData parentData = renderObject.parentData;
    bool needsLayout = false;

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

    if (parentData.left != left) {
      parentData.left = left;
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

class Grid extends MultiChildRenderObjectWidget {
  Grid(List<Widget> children, { Key key, this.maxChildExtent })
    : super(key: key, children: children) {
    assert(maxChildExtent != null);
  }

  final double maxChildExtent;

  RenderGrid createRenderObject() => new RenderGrid(maxChildExtent: maxChildExtent);

  void updateRenderObject(RenderGrid renderObject, Grid oldWidget) {
    renderObject.maxChildExtent = maxChildExtent;
  }
}

class Flex extends MultiChildRenderObjectWidget {
  Flex(List<Widget> children, {
    Key key,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.start,
    this.alignItems: FlexAlignItems.center,
    this.textBaseline
  }) : super(key: key, children: children) {
    assert(direction != null);
    assert(justifyContent != null);
    assert(alignItems != null);
  }

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;
  final FlexAlignItems alignItems;
  final TextBaseline textBaseline;

  RenderFlex createRenderObject() => new RenderFlex(direction: direction, justifyContent: justifyContent, alignItems: alignItems, textBaseline: textBaseline);

  void updateRenderObject(RenderFlex renderObject, Flex oldWidget) {
    renderObject.direction = direction;
    renderObject.justifyContent = justifyContent;
    renderObject.alignItems = alignItems;
    renderObject.textBaseline = textBaseline;
  }
}

class Row extends Flex {
  Row(List<Widget> children, {
    Key key,
    justifyContent: FlexJustifyContent.start,
    alignItems: FlexAlignItems.center,
    textBaseline
  }) : super(children, key: key, direction: FlexDirection.horizontal, justifyContent: justifyContent, alignItems: alignItems, textBaseline: textBaseline);
}

class Column extends Flex {
  Column(List<Widget> children, {
    Key key,
    justifyContent: FlexJustifyContent.start,
    alignItems: FlexAlignItems.center,
    textBaseline
  }) : super(children, key: key, direction: FlexDirection.vertical, justifyContent: justifyContent, alignItems: alignItems, textBaseline: textBaseline);
}

class Flexible extends ParentDataWidget {
  Flexible({ Key key, this.flex: 1, Widget child })
    : super(key: key, child: child);

  final int flex;

  void debugValidateAncestor(Widget ancestor) {
    assert(() {
      'Flexible must placed inside a Flex';
      return ancestor is Flex;
    });
  }

  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final FlexParentData parentData = renderObject.parentData;
    if (parentData.flex != flex) {
      parentData.flex = flex;
      AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('flex: $flex');
  }
}

class Paragraph extends LeafRenderObjectWidget {
  Paragraph({ Key key, this.text }) : super(key: key) {
    assert(text != null);
  }

  final TextSpan text;

  RenderParagraph createRenderObject() => new RenderParagraph(text);

  void updateRenderObject(RenderParagraph renderObject, Paragraph oldWidget) {
    renderObject.text = text;
  }
}

class StyledText extends StatelessComponent {
  // elements ::= "string" | [<text-style> <elements>*]
  // Where "string" is text to display and text-style is an instance of
  // TextStyle. The text-style applies to all of the elements that follow.
  StyledText({ this.elements, Key key }) : super(key: key) {
    assert(_toSpan(elements) != null);
  }

  final dynamic elements;

  TextSpan _toSpan(dynamic element) {
    if (element is String)
      return new PlainTextSpan(element);
    if (element is Iterable) {
      dynamic first = element.first;
      if (first is! TextStyle)
        throw new ArgumentError("First element of Iterable is a ${first.runtimeType} not a TextStyle");
      return new StyledTextSpan(first, element.skip(1).map(_toSpan).toList());
    }
    throw new ArgumentError("Element is ${element.runtimeType} not a String or an Iterable");
  }

  Widget build(BuildContext context) {
    return new Paragraph(text: _toSpan(elements));
  }
}

class DefaultTextStyle extends InheritedWidget {
  DefaultTextStyle({
    Key key,
    this.style,
    Widget child
  }) : super(key: key, child: child) {
    assert(style != null);
    assert(child != null);
  }

  final TextStyle style;

  static TextStyle of(BuildContext context) {
    DefaultTextStyle result = context.inheritFromWidgetOfType(DefaultTextStyle);
    return result?.style;
  }

  bool updateShouldNotify(DefaultTextStyle old) => style != old.style;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    '$style'.split('\n').forEach(description.add);
  }
}

class Text extends StatelessComponent {
  Text(this.data, { Key key, this.style }) : super(key: key) {
    assert(data != null);
  }

  final String data;
  final TextStyle style;

  Widget build(BuildContext context) {
    TextSpan text = new PlainTextSpan(data);
    TextStyle combinedStyle;
    if (style == null || style.inherit) {
      combinedStyle = DefaultTextStyle.of(context)?.merge(style) ?? style;
    } else {
      combinedStyle = style;
    }
    if (combinedStyle != null)
      text = new StyledTextSpan(combinedStyle, <TextSpan>[text]);
    return new Paragraph(text: text);
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$data"');
    if (style != null)
      '$style'.split('\n').forEach(description.add);
  }
}

class Image extends LeafRenderObjectWidget {
  Image({
    Key key,
    this.image,
    this.width,
    this.height,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  final ui.Image image;
  final double width;
  final double height;
  final ColorFilter colorFilter;
  final ImageFit fit;
  final FractionalOffset alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;

  RenderImage createRenderObject() => new RenderImage(
    image: image,
    width: width,
    height: height,
    colorFilter: colorFilter,
    fit: fit,
    alignment: alignment,
    repeat: repeat,
    centerSlice: centerSlice);

  void updateRenderObject(RenderImage renderObject, Image oldWidget) {
    renderObject.image = image;
    renderObject.width = width;
    renderObject.height = height;
    renderObject.colorFilter = colorFilter;
    renderObject.alignment = alignment;
    renderObject.fit = fit;
    renderObject.repeat = repeat;
    renderObject.centerSlice = centerSlice;
  }
}

class ImageListener extends StatefulComponent {
  ImageListener({
    Key key,
    this.image,
    this.width,
    this.height,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key) {
    assert(image != null);
  }

  final ImageResource image;
  final double width;
  final double height;
  final ColorFilter colorFilter;
  final ImageFit fit;
  final FractionalOffset alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;

  _ImageListenerState createState() => new _ImageListenerState();
}

class _ImageListenerState extends State<ImageListener> {
  void initState() {
    super.initState();
    config.image.addListener(_handleImageChanged);
  }

  ui.Image _resolvedImage;

  void _handleImageChanged(ui.Image resolvedImage) {
    setState(() {
      _resolvedImage = resolvedImage;
    });
  }

  void dispose() {
    config.image.removeListener(_handleImageChanged);
    super.dispose();
  }

  void didUpdateConfig(ImageListener oldConfig) {
    if (config.image != oldConfig.image) {
      oldConfig.image.removeListener(_handleImageChanged);
      config.image.addListener(_handleImageChanged);
    }
  }

  Widget build(BuildContext context) {
    return new Image(
      image: _resolvedImage,
      width: config.width,
      height: config.height,
      colorFilter: config.colorFilter,
      fit: config.fit,
      alignment: config.alignment,
      repeat: config.repeat,
      centerSlice: config.centerSlice
    );
  }
}

class NetworkImage extends StatelessComponent {
  NetworkImage({
    Key key,
    this.src,
    this.width,
    this.height,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  final String src;
  final double width;
  final double height;
  final ColorFilter colorFilter;
  final ImageFit fit;
  final FractionalOffset alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;

  Widget build(BuildContext context) {
    return new ImageListener(
      image: imageCache.load(src),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }
}

class DefaultAssetBundle extends InheritedWidget {
  DefaultAssetBundle({
    Key key,
    this.bundle,
    Widget child
  }) : super(key: key, child: child) {
    assert(bundle != null);
    assert(child != null);
  }

  final AssetBundle bundle;

  static AssetBundle of(BuildContext context) {
    DefaultAssetBundle result = context.inheritFromWidgetOfType(DefaultAssetBundle);
    return result?.bundle;
  }

  bool updateShouldNotify(DefaultAssetBundle old) => bundle != old.bundle;
}

class AsyncImage extends StatelessComponent {
  AsyncImage({
    Key key,
    this.provider,
    this.width,
    this.height,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  final ImageProvider provider;
  final double width;
  final double height;
  final ColorFilter colorFilter;
  final ImageFit fit;
  final FractionalOffset alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;

  Widget build(BuildContext context) {
    return new ImageListener(
      image: imageCache.loadProvider(provider),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }
}

class AssetImage extends StatelessComponent {
  AssetImage({
    Key key,
    this.name,
    this.bundle,
    this.width,
    this.height,
    this.colorFilter,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice
  }) : super(key: key);

  final String name;
  final AssetBundle bundle;
  final double width;
  final double height;
  final ColorFilter colorFilter;
  final ImageFit fit;
  final FractionalOffset alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;

  Widget build(BuildContext context) {
    return new ImageListener(
      image: (bundle ?? DefaultAssetBundle.of(context)).loadImage(name),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }
}

class WidgetToRenderBoxAdapter extends LeafRenderObjectWidget {
  WidgetToRenderBoxAdapter(RenderBox renderBox)
    : renderBox = renderBox,
      // WidgetToRenderBoxAdapter objects are keyed to their render box. This
      // prevents the widget being used in the widget hierarchy in two different
      // places, which would cause the RenderBox to get inserted in multiple
      // places in the RenderObject tree.
      super(key: new GlobalObjectKey(renderBox)) {
    assert(renderBox != null);
  }

  final RenderBox renderBox;

  RenderBox createRenderObject() => renderBox;
}


// EVENT HANDLING

class Listener extends OneChildRenderObjectWidget {
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

  RenderPointerListener createRenderObject() => new RenderPointerListener(
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel,
    behavior: behavior
  );

  void updateRenderObject(RenderPointerListener renderObject, Listener oldWidget) {
    renderObject.onPointerDown = onPointerDown;
    renderObject.onPointerMove = onPointerMove;
    renderObject.onPointerUp = onPointerUp;
    renderObject.onPointerCancel = onPointerCancel;
    renderObject.behavior = behavior;
  }

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

class RepaintBoundary extends OneChildRenderObjectWidget {
  RepaintBoundary({ Key key, Widget child }) : super(key: key, child: child);
  RenderRepaintBoundary createRenderObject() => new RenderRepaintBoundary();
}

class IgnorePointer extends OneChildRenderObjectWidget {
  IgnorePointer({ Key key, Widget child, this.ignoring: true })
    : super(key: key, child: child);

  final bool ignoring;

  RenderIgnorePointer createRenderObject() => new RenderIgnorePointer(ignoring: ignoring);

  void updateRenderObject(RenderIgnorePointer renderObject, IgnorePointer oldWidget) {
    renderObject.ignoring = ignoring;
  }
}


// UTILITY NODES

class MetaData extends OneChildRenderObjectWidget {
  MetaData({ Key key, Widget child, this.metaData })
    : super(key: key, child: child);

  final dynamic metaData;

  RenderMetaData createRenderObject() => new RenderMetaData(metaData: metaData);

  void updateRenderObject(RenderMetaData renderObject, MetaData oldWidget) {
    renderObject.metaData = metaData;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$metaData');
  }
}

class KeyedSubtree extends StatelessComponent {
  KeyedSubtree({ Key key, this.child })
    : super(key: key);

  final Widget child;

  Widget build(BuildContext context) => child;
}

class Builder extends StatelessComponent {
  Builder({ Key key, this.builder }) : super(key: key);
  final WidgetBuilder builder;
  Widget build(BuildContext context) => builder(context);
}

typedef Widget StatefulWidgetBuilder(BuildContext context, StateSetter setState);
class StatefulBuilder extends StatefulComponent {
  StatefulBuilder({ Key key, this.builder }) : super(key: key);
  final StatefulWidgetBuilder builder;
  _StatefulBuilderState createState() => new _StatefulBuilderState();
}
class _StatefulBuilderState extends State<StatefulBuilder> {
  Widget build(BuildContext context) => config.builder(context, setState);
}
